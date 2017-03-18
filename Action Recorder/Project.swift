//
//  Project.swift
//  Action Recorder
//
//  Created by Jean on 7/4/15.
//  Copyright (c) 2015 mobileuse. All rights reserved.
//

import CoreGraphics

class Animation {
    var frames = [AnimationFrame]()
    var framesPerSecond = 24//default 24
}

struct AnimationFrame : TimelineObject {
    var image:CGImage! = nil
    var frameCountDuration: Int = 0
    var frameCountStartTime: Int = 0
    
    init(image: CGImage, frameCountDuration: Int){
        self.image = image
        self.frameCountDuration = frameCountDuration
    }
}


/*enum ProjectAnimationFrameUpdateType {
    case Add
    case ModifyStartTime
    case ModifyDuration
    case ModifyImage
    case Replace
    case Remove
}*/

struct ProjectAnimationFrameUpdateTypes : OptionSet {
    fileprivate enum `Type` : Int, CustomStringConvertible {
        case add = 1, modifyStartTime = 2, modifyDuration = 4, modifyImage = 8, replace = 16, remove = 32
        var description : String {
            var shift = 0
            while (rawValue >> shift != 1){ shift += 1 }
            return ["Add", "ModifyStartTime", "ModifyDuration", "ModifyImage", "Replace", "Remove"][shift]
        }
    }
    func containedIn(_ types: ProjectAnimationFrameUpdateTypes) -> Bool {
        return types.intersection(self) == self
    }
    
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }
    fileprivate init(_ type:Type){ self.rawValue = type.rawValue }
    
    static let Add = ProjectAnimationFrameUpdateTypes(Type.add)
    static let ModifyStartTime = ProjectAnimationFrameUpdateTypes(rawValue: 2)
    static let ModifyDuration = ProjectAnimationFrameUpdateTypes(rawValue: 4)
    static let ModifyImage = ProjectAnimationFrameUpdateTypes(rawValue: 8)
    static let Modify: ProjectAnimationFrameUpdateTypes = [ModifyStartTime, ModifyDuration, ModifyImage]
    static let Replace = ProjectAnimationFrameUpdateTypes(rawValue: 16)
    static let Remove = ProjectAnimationFrameUpdateTypes(rawValue: 32)
}


protocol ProjectDelegate {
    func projectAnimationFramesChanged(selectedRange: CountableRange<Int>, changedRange: CountableRange<Int>, updateType: ProjectAnimationFrameUpdateTypes)
}

protocol ProjectAnimationFrameSpecificUpdatesDelegate {
    func projectAddedAnimationFrames(selectedRange: CountableRange<Int>, changedRange: CountableRange<Int>)
    func projectModifiedAnimationFrames(selectedRange: CountableRange<Int>, changedRange: CountableRange<Int>, updateType: ProjectAnimationFrameUpdateTypes)
    func projectReplacedAnimationFrames(selectedRange: CountableRange<Int>, changedRange: CountableRange<Int>)
    func projectRemovedAnimationFrames(selectedRange: CountableRange<Int>, changedRange: CountableRange<Int>)
}

class Project: NSObject {
    var animation = Animation()
    var delegate: ProjectDelegate? = nil
    var specificUpdatesDelegates = [ProjectAnimationFrameSpecificUpdatesDelegate]()
    
    
    override init() {
        super.init()
    }
    
    
    
    //MARK: Animation Frames
    
    
    func _updateStartTimeOfFrameAtIndex(_ index:Int) {
        animation.frames[index].frameCountStartTime = index == 0 ? 0 : animation.frames[index-1].frameCountStartTime + animation.frames[index-1].frameCountDuration
    }
    
    func _updateStartTimeOfFramesInRange(_ range:CountableRange<Int>){
        for index in range {
            _updateStartTimeOfFrameAtIndex(index)
        }
    }
    
    func _updateStartTimeOfSuccessorsOfIndexIfNeeded(_ index: Int) {
        if index < animation.frames.endIndex-1 {
            var firstSuccessorCalculatedStartTime = 0
            if index > 0 {
                let previous = animation.frames[index]
                firstSuccessorCalculatedStartTime = previous.frameCountStartTime + previous.frameCountDuration
            }
            if animation.frames[index+1].frameCountStartTime != firstSuccessorCalculatedStartTime {
                let updateStartTimeRange = animation.frames.indices.suffix(from: index)
                _updateStartTimeOfFramesInRange(updateStartTimeRange)
                notifyDelegates(selectedRange: updateStartTimeRange, changedRange: updateStartTimeRange, updateType: .ModifyStartTime)
            }
        }
    }
    
    func updateStartTimeOfFrameAtIndex(_ index:Int) {
        _updateStartTimeOfFrameAtIndex(index)
        notifyDelegates(selectedRange: index..<index, changedRange: index..<index+1, updateType: .ModifyStartTime)
        _updateStartTimeOfSuccessorsOfIndexIfNeeded(index)
    }
    
    func updateStartTimeOfFramesInRange(_ range:CountableRange<Int>){
        _updateStartTimeOfFramesInRange(range)
        notifyDelegates(selectedRange: range, changedRange: range, updateType: .ModifyStartTime)
        _updateStartTimeOfSuccessorsOfIndexIfNeeded(range.upperBound-1)
    }
    
    
    func notifyDelegates(selectedRange:CountableRange<Int>, changedRange:CountableRange<Int>, updateType:ProjectAnimationFrameUpdateTypes) {
        for specificUpdatesDelegate in specificUpdatesDelegates as [ProjectAnimationFrameSpecificUpdatesDelegate] {
            
            switch updateType {
            case let updateType where updateType.contains(.Add) :
                
                specificUpdatesDelegate.projectAddedAnimationFrames(selectedRange: selectedRange, changedRange: changedRange)
                
            case let updateType where updateType.containedIn(.Modify) :
                
                specificUpdatesDelegate.projectModifiedAnimationFrames(selectedRange: selectedRange, changedRange: changedRange, updateType: updateType)
                
            case let updateType where updateType.contains(.Replace) :
                
                specificUpdatesDelegate.projectReplacedAnimationFrames(selectedRange: selectedRange, changedRange: changedRange)
                
            case let updateType where updateType.contains(.Remove) :
                
                specificUpdatesDelegate.projectRemovedAnimationFrames(selectedRange: selectedRange, changedRange: changedRange)
                
            default :
                print(updateType)
            }
        }
        
        delegate?.projectAnimationFramesChanged(selectedRange: selectedRange, changedRange: changedRange, updateType:updateType)
    }
    
    func appendAnimationFrame(_ animationFrame: AnimationFrame){
        self.animation.frames.append(animationFrame)
        let selectedRange = animation.frames.endIndex-1..<animation.frames.endIndex-1
        let changedRange = animation.frames.endIndex-1..<animation.frames.endIndex
        notifyDelegates(selectedRange: selectedRange, changedRange: changedRange, updateType: .Add)
        updateStartTimeOfFramesInRange(changedRange)
    }
    
    func insertAnimationFrameAtIndex(_ animationFrame: AnimationFrame, index: Int){
        self.animation.frames.insert(animationFrame, at: index)
        let selectedRange = index..<index
        let changedRange = index..<index+1
        notifyDelegates(selectedRange: selectedRange, changedRange: changedRange, updateType: .Add)
        updateStartTimeOfFramesInRange(changedRange)
    }
    
    func spliceAnimationFrames(_ frames: [(AnimationFrame)], index: Int){
        self.animation.frames.insert(contentsOf: frames, at: index)
        let selectedRange = index..<index
        let changedRange = index..<index+1
        notifyDelegates(selectedRange: selectedRange, changedRange: changedRange, updateType: .Add)
        updateStartTimeOfFramesInRange(changedRange)
    }
    
    func replaceAnimationFramesRange(_ subRange: CountableRange<Int>, frames: [(AnimationFrame)]){
        self.animation.frames.replaceSubrange(subRange, with: frames)
        let selectedRange = subRange
        let changedRange = subRange
        notifyDelegates(selectedRange: selectedRange, changedRange: changedRange, updateType: .Replace)
        updateStartTimeOfFramesInRange(changedRange)
    }
    
    func removeAnimationFrameAtIndex(_ index: Int){
        self.animation.frames.remove(at: index)
        let selectedRange = index..<index
        let changedRange = index..<index
        notifyDelegates(selectedRange: selectedRange, changedRange: changedRange, updateType: .Remove)
        updateStartTimeOfFramesInRange(changedRange)
    }
    
    func removeAnimationFramesRange(_ subRange: CountableRange<Int>){
        self.animation.frames.removeSubrange(subRange)
        let selectedRange = subRange
        let changedRange = subRange.lowerBound..<subRange.lowerBound
        notifyDelegates(selectedRange: selectedRange, changedRange: changedRange, updateType: .Remove)
        updateStartTimeOfFramesInRange(changedRange)
    }
    
}

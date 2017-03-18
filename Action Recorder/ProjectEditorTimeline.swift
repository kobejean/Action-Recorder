//
//  ProjectEditorTimeline.swift
//  Action Recorder
//
//  Created by Jean on 7/6/15.
//  Copyright (c) 2015 mobileuse. All rights reserved.
//

import UIKit

protocol TimelineObject {
    var frameCountDuration: Int {get set}
}


class TOV: UIView {
    var frameCountStartTime = 0
    var frameCountDuration = 0
    
    init(){
        super.init(frame:CGRect.zero)
        self.backgroundColor = UIColor.green
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol TimelineDelegate {
    func timelineIndexChanged(_ index:Int?)
}

infix operator ~= { associativity none precedence 130 }
func ~= (left: TOVThreshold, right: CGFloat) -> Bool {
    return left.start <= right && right < left.end
}

struct TOVThreshold {
    var start: CGFloat = 0
    var end: CGFloat = 0
    
    init(start: CGFloat, end: CGFloat) {
        self.start = start
        self.end = end
    }
}

class ProjectEditorTimeline: UIScrollView, UIScrollViewDelegate, ProjectAnimationFrameSpecificUpdatesDelegate {
    var animation: Animation! = nil
    var tovs = [TOV]()
    var captureFrameView = TOV()
    var timelineDelegate: TimelineDelegate? = nil
    
    fileprivate var _threshold: TOVThreshold? = nil
    
    fileprivate var _frameIndex: Int? = 0
    var frameIndex: Int? {
        set {
            _frameIndex = newValue
            timelineDelegate?.timelineIndexChanged(newValue)
        }
        
        get {
            return _frameIndex
        }
    }
    
    let pixelsPerFrameCount = 20
    let height: CGFloat = 60
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.contentInset.left = frame.width/2
        self.contentInset.right = frame.width/2
        self.decelerationRate = 0.99
        self.delegate = self
        
        // captureFrameView
        self.captureFrameView.frameCountDuration = 2
        self.captureFrameView.backgroundColor = UIColor.gray
        self.addSubview(self.captureFrameView)
        self.tovs.append(self.captureFrameView)
        updateFrameForTOV(0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentInset.left = frame.width/2
        self.contentInset.right = frame.width/2
        if let last = tovs.last {
            self.contentSize = CGSize(width: CGFloat(pixelsPerFrameCount * (last.frameCountStartTime + last.frameCountDuration)), height: height)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        findCurrentFrame()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.setContentOffset(_nearestSnapPoint(scrollView.contentOffset), animated: true)
    }
    
    func hitTestForTOV(_ point:CGPoint) -> TOV? {
        let hitTestView = self.hitTest(point, with: nil)
        if let hitTestTOV = hitTestView as? TOV {
            return hitTestTOV
        }else{
            return nil
        }
    }
    
    func projectAddedAnimationFrames(selectedRange: CountableRange<Int>, changedRange: CountableRange<Int>) {
        for index in CountableRange<Int>(changedRange) {
            let frame = self.animation.frames[index]
            let timelineObjectView = TOV()
            timelineObjectView.frameCountDuration = frame.frameCountDuration
            
            self.addSubview(timelineObjectView)
            self.tovs.insert(timelineObjectView, at: index)
        }
    }
    
    func projectModifiedAnimationFrames(selectedRange: CountableRange<Int>, changedRange: CountableRange<Int>, updateType: ProjectAnimationFrameUpdateTypes) {
        if updateType == ProjectAnimationFrameUpdateTypes.ModifyStartTime {
            for index in CountableRange<Int>(changedRange)  {
                let frame = self.animation.frames[index]
                tovs[index].frameCountStartTime = frame.frameCountStartTime
                updateFrameForTOV(index)
            }
        }
        if updateType == ProjectAnimationFrameUpdateTypes.ModifyDuration {
            for index in CountableRange<Int>(changedRange)  {
                let frame = self.animation.frames[index]
                tovs[index].frameCountDuration = frame.frameCountDuration
                updateFrameForTOV(index)
            }
        }
        let lastBCFV = tovs[tovs.endIndex - 2]
        let captureFrameCountStartTime = lastBCFV.frameCountStartTime + lastBCFV.frameCountDuration
        captureFrameView.frameCountStartTime = captureFrameCountStartTime
        updateFrameForTOV(tovs.endIndex - 1)
    }
    
    func projectReplacedAnimationFrames(selectedRange: CountableRange<Int>, changedRange: CountableRange<Int>) {
        
    }
    
    func projectRemovedAnimationFrames(selectedRange: CountableRange<Int>, changedRange: CountableRange<Int>) {
        
    }
    
    func updateFrameForTOV(_ index:Int) {
        let timelineObjectView = tovs[index]
        timelineObjectView.frame.origin.x = CGFloat(timelineObjectView.frameCountStartTime * pixelsPerFrameCount)
        timelineObjectView.frame.origin.y = 0.0
        timelineObjectView.frame.size.width = CGFloat(timelineObjectView.frameCountDuration * pixelsPerFrameCount)
        timelineObjectView.frame.size.height = CGFloat(height)
    }
    
    //MARK: |   Utilities
    
    fileprivate func _nearestCGFloat(_ originalFloat:CGFloat, float1:CGFloat, float2: CGFloat) -> CGFloat {
        let diff1 = abs(originalFloat - float1)
        let diff2 = abs(originalFloat - float2)
        if diff1 > diff2 {
            return float2
        }else{
            return float1
        }
    }
    
    fileprivate func _nearestSnapPoint(_ targetOffestPoint:CGPoint) -> CGPoint {
        let relativePoint = _convertOffsetPointToPointInTimeLine(targetOffestPoint)
        let hitTestTOV = hitTestForTOV(relativePoint)
        if let hitTestTOV = hitTestTOV {
            let nearestX = _nearestCGFloat(relativePoint.x, float1: hitTestTOV.frame.origin.x, float2: hitTestTOV.frame.origin.x + hitTestTOV.frame.width)
            let point = _convertPointInTimelineToOffsetPoint(CGPoint(x: nearestX, y: hitTestTOV.frame.origin.y))
            return point
        }else{
            let ratio: CGFloat = (relativePoint.x / contentSize.width)
            let boundedRatio: CGFloat = max(min(ratio, 1), 0)
            
            let boundedX = (boundedRatio * contentSize.width)
            let point = _convertPointInTimelineToOffsetPoint(CGPoint(x: boundedX, y: 0))
            
            if 0 < boundedRatio && boundedRatio < 1 {
                print("guessing snap point...")
            }
            return point
        }
    }

    fileprivate func _convertOffsetPointToPointInTimeLine(_ point:CGPoint) -> CGPoint {
        return point.applying(CGAffineTransform(translationX: self.contentInset.left, y: self.contentInset.top))
    }
    
    fileprivate func _convertPointInTimelineToOffsetPoint(_ point:CGPoint) -> CGPoint {
        return point.applying(CGAffineTransform(translationX: -self.contentInset.left, y: -self.contentInset.top))
    }
    
    fileprivate func _convertOffsetXToXInTimeline(_ x:CGFloat) -> CGFloat {
        return x + self.contentInset.left
    }
    
    fileprivate func _convertXInTimelineToOffsetX(_ x:CGFloat) -> CGFloat {
        return x - self.contentInset.left
    }

    // MARK: Find Current Frame
    
    // threshold for index
    fileprivate func _FCF_TFI(_ index: Int) -> TOVThreshold? {
        if self.tovs.indices ~= index {
            let tov = self.tovs[index]
            
            var start = tov.frame.origin.x
            var end = start + tov.frame.width
            
            start = self._convertXInTimelineToOffsetX(start)
            end = self._convertXInTimelineToOffsetX(end)
            
            return TOVThreshold(start: start, end: end)
        }else{
            return nil
        }
    }
    
    // find current frame with hit test
    fileprivate func _FCF_HT() {
        let relativePoint = self._convertOffsetPointToPointInTimeLine(self.contentOffset)
        let hitTestTOV = self.hitTestForTOV(relativePoint)
        
        if hitTestTOV != nil {              // hit test success
            
            frameIndex = tovs.index(of: hitTestTOV!)// nil if not found
            _threshold = frameIndex != nil ? _FCF_TFI(frameIndex!) : nil
            
        }else{                                        // hit test failed
            self.frameIndex = nil
            self._threshold = nil
        }
    }
    
    // find current frame with guess index
    fileprivate func _FCF_GI(_ guessIndex: Int) {
        let guessThreshold = _FCF_TFI(guessIndex)
        if guessThreshold != nil {// guess threshold is not out of bounds
            
            if guessThreshold! ~= self.contentOffset.x {// contentOffset.x is currently inside guess threshold
                self.frameIndex = guessIndex
                self._threshold = guessThreshold!
            }else{                              // guess was wrong use hitTest to find current frame
                _FCF_HT()
            }
        }else{                                  // must be out of bounds
            self.frameIndex = nil
            self._threshold = nil
        }
    }

    func findCurrentFrame() {
        if frameIndex != nil {
            if _threshold != nil {
                if self.contentOffset.x < _threshold!.start {
                    _FCF_GI(frameIndex! - 1) // previous
                }else if self.contentOffset.x > _threshold!.end{
                    _FCF_GI(frameIndex! + 1) // next
                }
            }else{
                _FCF_HT()
            }
        }else{
            _FCF_HT()
        }
    }
}

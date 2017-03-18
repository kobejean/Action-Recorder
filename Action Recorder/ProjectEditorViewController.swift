//
//  ProjectEditorViewController.swift
//  Action Recorder
//
//  Created by Jean on 7/3/15.
//  Copyright (c) 2015 mobileuse. All rights reserved.
//

import UIKit

class ProjectEditorViewController: UIViewController, ProjectAnimationFrameSpecificUpdatesDelegate, TimelineDelegate, CaptureViewControllerDelegate {
    //MARK: Properties
    //MARK: |   IBOutlet
    
    @IBOutlet weak var projectPreviewContainerView: UIView!
    @IBOutlet weak var timeline: ProjectEditorTimeline!
    @IBOutlet weak var testStepper: UIStepper!
    
    //MARK: |   childViewControllers
    weak var projectPreviewViewController: ProjectPreviewViewController! = nil
    weak var captureViewController: CaptureViewController! = nil

    //MARK: |   Project
    var project: Project! = Project()
    
    //MARK: |   Set Get
    
    fileprivate var _showCaptureView = true
    var showCaptureView: Bool {
        get {
            return _showCaptureView
        }
        
        set {
            if _showCaptureView != newValue {
                _showCaptureView = newValue
                projectPreviewContainerView.isHidden = showCaptureView
            }
        }
    }
    
    fileprivate var _displayFrameIndex = 0
    var displayFrameIndex: Int {
        set {
            if _displayFrameIndex != newValue {
                _displayFrameIndex = newValue
                if self.timeline.frameIndex != newValue {
                    //self.timeline.frameIndex = newValue
                }
                
                if testStepper.value != Double(displayFrameIndex) {
                    testStepper.value = Double(displayFrameIndex)
                }
                
                updateDisplayFrame()
            }
        }
        
        get {
            return _displayFrameIndex
        }
    }
    
    //MARK: Methods
    //MARK: |   UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.project.specificUpdatesDelegates.append(self)
        self.project.specificUpdatesDelegates.append(self.timeline)
        self.timeline.animation = self.project.animation
        self.timeline.timelineDelegate = self
    }
    
    override func shouldAutomaticallyForwardRotationMethods() -> Bool {
        return true
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.landscape
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ProjectPreviewEmbededSegue" {
            projectPreviewViewController = segue.destination as! ProjectPreviewViewController
            projectPreviewViewController.project = project
            
        }
        if segue.identifier == "CaptureEmbededSegue" {
            captureViewController = segue.destination as! CaptureViewController
            captureViewController.delegate = self
        }
    }
    
    func updateDisplayFrame() {
        if displayFrameIndex == project.animation.frames.endIndex { // Capture View
            showCaptureView = true
            captureViewController.overlayImage = project.animation.frames[displayFrameIndex-1].image
        }else if displayFrameIndex < project.animation.frames.endIndex && displayFrameIndex >= 0 {//Project Preview View
            
            showCaptureView = false
            projectPreviewViewController.displayFrameIndex = displayFrameIndex
        }else{
            print("displayFrameIndex: \(displayFrameIndex) is beyond bounds")
        }
    }
    
    func updateDisplayFrameIfAffectedByUpdateRange(selectedRange: CountableRange<Int>, changedRange: CountableRange<Int>, updateType:ProjectAnimationFrameUpdateTypes) {
        
        let willAffectTrailingIndexes = (updateType == .Add || updateType == .Remove)
        let isInRange = changedRange ~= displayFrameIndex
        
        if willAffectTrailingIndexes {
            // new trail start index
            var _NTSI: Int! = nil
            // previous trail start index
            var _PTSI: Int!  = nil
            if updateType == .Add {
                _NTSI = changedRange.upperBound
                _PTSI = changedRange.lowerBound
            }else if updateType == .Remove {
                _NTSI = changedRange.lowerBound
                _PTSI = changedRange.upperBound
            }
            
            if isInRange {
                // move to fisrt index after the last added or subtracted frame
                displayFrameIndex = _NTSI
            }else if changedRange.upperBound <= displayFrameIndex {
                // current frame index is trailing updated range
                // displace by differance of the new first trailing index 
                let trailIndexDisplacement = _NTSI - _PTSI
                displayFrameIndex += trailIndexDisplacement
            }
            
        }else if isInRange {
            updateDisplayFrame()
        }
    }
    
    //MARK: |   ProjectFrameSpecificUpdatesDelegate
    
    func projectAddedAnimationFrames(selectedRange: CountableRange<Int>, changedRange: CountableRange<Int>) {
        self.testStepper.maximumValue = Double(project.animation.frames.endIndex)
        
        updateDisplayFrameIfAffectedByUpdateRange(selectedRange: selectedRange, changedRange: changedRange, updateType: .Add)
    }
    
    func projectModifiedAnimationFrames(selectedRange: CountableRange<Int>, changedRange: CountableRange<Int>, updateType: ProjectAnimationFrameUpdateTypes) {
        updateDisplayFrameIfAffectedByUpdateRange(selectedRange: selectedRange, changedRange: changedRange, updateType: updateType)
    }
    
    func projectReplacedAnimationFrames(selectedRange: CountableRange<Int>, changedRange: CountableRange<Int>) {
        updateDisplayFrameIfAffectedByUpdateRange(selectedRange: selectedRange, changedRange: changedRange, updateType: .Replace)
    }
    
    func projectRemovedAnimationFrames(selectedRange: CountableRange<Int>, changedRange: CountableRange<Int>) {
        self.testStepper.maximumValue = Double(project.animation.frames.endIndex)
        
        updateDisplayFrameIfAffectedByUpdateRange(selectedRange: selectedRange, changedRange: changedRange, updateType: .Add)
    }
    
    func timelineIndexChanged(_ index: Int?) {
        if index != nil && self.displayFrameIndex != index {
            self.displayFrameIndex = index!
        }
    }
    
    func didCaptureImage(_ image: CGImage) {
        self.project.appendAnimationFrame(AnimationFrame(image: image, frameCountDuration: 2))
    }
    
    //MARK: |   IBAction
    
    @IBAction func stepperValueChanged(_ sender: UIStepper) {
        self.displayFrameIndex = Int(sender.value)
    }
}

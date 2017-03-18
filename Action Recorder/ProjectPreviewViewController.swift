//
//  ProjectPreviewViewController.swift
//  Action Recorder
//
//  Created by Jean on 7/4/15.
//  Copyright (c) 2015 mobileuse. All rights reserved.
//

import UIKit

class ProjectPreviewViewController: UIViewController {
    var project: Project! = nil
    var provideControls: Bool = false
    var _displayFrameIndex = 0
    var displayFrameIndex: Int {
        set {
            _displayFrameIndex = newValue
            self.view.layer.contents = project.animation.frames[displayFrameIndex].image
        }
        
        get {
            return _displayFrameIndex
        }
    }
    
    //MARK: Methods
    //MARK: |   UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.clear
        self.view.contentMode = UIViewContentMode.scaleAspectFit
        //project.delegate = self
    }
    
    //MARK: |   ProjectFrameSpecificUpdatesDelegate
    
    func projectAnimationFramesUpdatedRange(selectedRange: Range<Int>, changedRange: Range<Int>, updateType:ProjectAnimationFrameUpdateTypes) {
        if changedRange ~= displayFrameIndex && (updateType != ProjectAnimationFrameUpdateTypes.ModifyDuration || updateType != ProjectAnimationFrameUpdateTypes.ModifyStartTime) {
            if(project.animation.frames.count > displayFrameIndex){
                let image = project.animation.frames[displayFrameIndex].image
                self.view.layer.contents = image
            }else{
                self.view.layer.contents = nil
            }
        }
    }
}

//
//  CapturePreviewView.swift
//  Action Recorder
//
//  Created by Jean on 6/24/15.
//  Copyright (c) 2015 mobileuse. All rights reserved.
//

import UIKit
import AVFoundation

class CapturePreviewView: UIView {
    
    var pointer: CaptureInterestPointerView!
    var overlayLayer = CALayer()
    var overlayImage: CGImage! {
        didSet{
            overlayLayer.contents = overlayImage
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        overlayLayer.frame = bounds
    }

    override init(frame:CGRect){
        super.init(frame: frame)
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        self.pointer = CaptureInterestPointerView(devicePoint: devicePoint, inView: self)
        self.layer.addSublayer(overlayLayer)
        self.layer.videoGravity = AVLayerVideoGravityResizeAspectFill
        overlayLayer.opacity = 0.5
        overlayLayer.contentsGravity = kCAGravityResizeAspectFill
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        self.pointer = CaptureInterestPointerView(devicePoint: devicePoint, inView: self)
        self.layer.addSublayer(overlayLayer)
        overlayLayer.opacity = 0.5
        overlayLayer.contentsGravity = kCAGravityResizeAspect
        //self.addSubview(self.pointerView)
    }
    
    override var layer: AVCaptureVideoPreviewLayer {
        set {
            self.layer = newValue
        }
        
        get {
            if let layer = super.layer as? AVCaptureVideoPreviewLayer {
                return layer
            }else{print("attempting forced conversion")}
            return super.layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    override class var layerClass : AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var session: AVCaptureSession {
        set {
            self.layer.session = newValue
        }
        
        get {
            return self.layer.session
        }
    }
    
    var connection: AVCaptureConnection! {
        get {
            return self.layer.connection
        }
    }
    
    var videoOrientation: AVCaptureVideoOrientation! {
        set {
            if self.layer.connection != nil {
                self.layer.connection.videoOrientation = newValue
                
            }else{print("connection == nil \n could not set connection.videoOrientation \n videoOrientation: set()")}
        }
        
        get {
            if self.layer.connection != nil {
                return self.layer.connection.videoOrientation
            }else{print("connection == nil \n could not get connection.videoOrientation \n videoOrientation: get()")}
            return nil
        }
    }
    
}

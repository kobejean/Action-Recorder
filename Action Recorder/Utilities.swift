//
//  Utilities.swift
//  Action Recorder
//
//  Created by Jean on 7/6/15.
//  Copyright (c) 2015 mobileuse. All rights reserved.
//

import UIKit

func CGImageOrientation(_ originalCGImage: CGImage, orientation: UIImage.Orientation) -> CGImage {
    let imageSize = CGSize(width: CGFloat(originalCGImage.width), height: CGFloat(originalCGImage.height))
    var rotatedSize: CGSize! = nil
    var radians = 0.0
    switch (orientation) {
    case UIImage.Orientation.up, UIImage.Orientation.upMirrored:
        radians = 0.0;
        break;
    case UIImage.Orientation.left, UIImage.Orientation.leftMirrored:
        radians = -Double.pi / 2;
        break;
    case UIImage.Orientation.right, UIImage.Orientation.rightMirrored:
        radians = Double.pi / 2;
        break;
    case UIImage.Orientation.down, UIImage.Orientation.downMirrored:
        radians = Double.pi;
        break;
    }
    
    if radians == 0.0 || radians == Double.pi {
        rotatedSize = imageSize
    }else{
        rotatedSize = CGSize(width: imageSize.height, height: imageSize.width)
    }
    let rotatedCenterX = rotatedSize.width / 2
    let rotatedCenterY = rotatedSize.height / 2
    
    UIGraphicsBeginImageContextWithOptions(rotatedSize, false, 1.0)
    let rotatedContext = UIGraphicsGetCurrentContext()
    
    if radians == 0.0 || radians == Double.pi { // 0 or 180 degrees
        rotatedContext?.translateBy(x: rotatedCenterX, y: rotatedCenterY)
        if radians == 0.0 {
            rotatedContext?.scaleBy(x: 1.0, y: -1.0)
        }else{
            rotatedContext?.scaleBy(x: -1.0, y: 1.0)
        }
        rotatedContext?.translateBy(x: -rotatedCenterX, y: -rotatedCenterY)
    }else if radians == Double.pi / 2 || radians == -Double.pi / 2 { // +/- 90 degrees
        rotatedContext?.translateBy(x: rotatedCenterX, y: rotatedCenterY)
        rotatedContext?.rotate(by: CGFloat(radians))
        rotatedContext?.scaleBy(x: 1.0, y: -1.0)
        rotatedContext?.translateBy(x: -rotatedCenterY, y: -rotatedCenterX)
    }
    let drawingRect = CGRect(x: 0.0, y: 0.0, width: imageSize.width, height: imageSize.height)
    rotatedContext?.draw(originalCGImage, in: drawingRect)
    let rotatedCGImage = rotatedContext?.makeImage()!
    return rotatedCGImage!
}

//
//  Utilities.swift
//  Action Recorder
//
//  Created by Jean on 7/6/15.
//  Copyright (c) 2015 mobileuse. All rights reserved.
//

import UIKit

func CGImageOrientation(_ originalCGImage: CGImage, orientation: UIImageOrientation) -> CGImage {
    let imageSize = CGSize(width: CGFloat(originalCGImage.width), height: CGFloat(originalCGImage.height))
    var rotatedSize: CGSize! = nil
    var radians = 0.0
    switch (orientation) {
    case UIImageOrientation.up, UIImageOrientation.upMirrored:
        radians = 0.0;
        break;
    case UIImageOrientation.left, UIImageOrientation.leftMirrored:
        radians = -M_PI_2;
        break;
    case UIImageOrientation.right, UIImageOrientation.rightMirrored:
        radians = M_PI_2;
        break;
    case UIImageOrientation.down, UIImageOrientation.downMirrored:
        radians = M_PI;
        break;
    }
    
    if radians == 0.0 || radians == M_PI {
        rotatedSize = imageSize
    }else{
        rotatedSize = CGSize(width: imageSize.height, height: imageSize.width)
    }
    let rotatedCenterX = rotatedSize.width / 2
    let rotatedCenterY = rotatedSize.height / 2
    
    UIGraphicsBeginImageContextWithOptions(rotatedSize, false, 1.0)
    let rotatedContext = UIGraphicsGetCurrentContext()
    
    if radians == 0.0 || radians == M_PI { // 0 or 180 degrees
        rotatedContext?.translateBy(x: rotatedCenterX, y: rotatedCenterY)
        if radians == 0.0 {
            rotatedContext?.scaleBy(x: 1.0, y: -1.0)
        }else{
            rotatedContext?.scaleBy(x: -1.0, y: 1.0)
        }
        rotatedContext?.translateBy(x: -rotatedCenterX, y: -rotatedCenterY)
    }else if radians == M_PI_2 || radians == -M_PI_2 { // +/- 90 degrees
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

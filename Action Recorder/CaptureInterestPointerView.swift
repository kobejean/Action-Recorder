//
//  CaptureInterestPointerView.swift
//  Action Recorder
//
//  Created by Jean on 6/25/15.
//  Copyright (c) 2015 mobileuse. All rights reserved.
//

import UIKit
import CoreGraphics
import QuartzCore

// MARK: Constants


class CaptureInterestPointerView: UIView {
    // MARK: Properties
    
    // MARK: |  Default State
    fileprivate let _defaultWidth: CGFloat = 100.0
    fileprivate let _defaultHeight: CGFloat = 100.0
    fileprivate let _defaultPointerAxisLinePathDistanceFromBorder: CGFloat = 15.0
    fileprivate let _defaultPointerSquareBorderDistanceFromBorder: CGFloat = 0.0
    
    // MARK: |  Locked State
    fileprivate let _lockedWidth: CGFloat = 100.0
    fileprivate let _lockedHeight: CGFloat = 100.0
    fileprivate let _lockedPointerAxisLinePathDistanceFromBorder: CGFloat = 50.0
    fileprivate let _lockedPointerSquareBorderDistanceFromBorder: CGFloat = 30.0
    fileprivate let _lockedStrokeColor = UIColor.gray.cgColor
    fileprivate let _lockedAdjustingStrokeColor = UIColor.red.cgColor
    
    // MARK: |  ShapeLayer
    fileprivate var _shapeLayer: CAShapeLayer! = nil
    fileprivate let _shapeLayerAnimationDuration: CFTimeInterval = 0.3
    fileprivate let _shadowColor = UIColor.black.cgColor
    fileprivate let _shadowOffset = CGSize(width: 0.0, height: 1.0)
    fileprivate let _shadowOpacity: Float = 1.0
    fileprivate let _shadowRadius: CGFloat = 1.0
    
    // MARK: |  StrokeColor
    fileprivate let _defaultAdjustingStrokeColor = UIColor.yellow.cgColor
    fileprivate let _defaultStrokeColor = UIColor.green.cgColor
    
    // MARK: |  ShowAndHide
    fileprivate let _showAndHideDuration = 0.8
    fileprivate var _showAndHideTimerCount: Int = 0
    
    // MARK: |  Constraints
    fileprivate var _centerXConstraint: NSLayoutConstraint! = nil
    fileprivate var _centerYConstraint: NSLayoutConstraint! = nil
    fileprivate var _widthConstraint: NSLayoutConstraint! = nil
    fileprivate var _heightConstraint: NSLayoutConstraint! = nil
    
    // MARK: |  Internal Public
    
    fileprivate var _locked: Bool = false
    fileprivate var _adjusting: Bool = false
    
    // MARK: |  Public
    var locked: Bool {
        set {
            if newValue != locked {
                _locked = newValue
                if automaticallyShowAndHide {
                    if newValue {
                        _showAndHideTimerCount += 1
                    }else{
                        _showAndHideTimerCount -= 1
                    }
                    self.show(hideAfterDelay: _showAndHideDuration)
                    self.drawShapeLayer(true)
                }
                self.updateApearance()
            }
        }
        
        get {
            return _locked
        }
        
    }
    
    var adjusting: Bool {
        set {
            if newValue != adjusting{
                _adjusting = newValue
                if self.automaticallyShowAndHide {
                    if newValue {
                        _showAndHideTimerCount += 1
                    }else{
                        _showAndHideTimerCount -= 1
                    }
                }
                self.updateApearance()
            }
            if self.automaticallyShowAndHide {
                // adds more delay
                self.show(hideAfterDelay: _showAndHideDuration)
            }
        }
        
        get {
            return _adjusting
        }
    }
    
    var automaticallyShowAndHide: Bool = true
    
    // MARK: |  Override
    // downcast as CapturePreviewView
    override var superview: CapturePreviewView? {
        get {
            return super.superview as? CapturePreviewView
        }
    }
    
    // MARK: Methods
    // MARK: |  Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        if frame.isEmpty || frame == CGRect.zero  {
            self.frame = CGRect(x: 0.0, y: 0.0, width: _defaultWidth, height: _defaultHeight)
        }
        self.setHidden(true, animated: false)
        //self.backgroundColor = UIColor.whiteColor()
        self.drawShapeLayer(false)
        self.layer.addSublayer(_shapeLayer)
    }
    

    required convenience init(coder aDecoder: NSCoder) {
        self.init(frame: CGRect.zero)
    }
    
    convenience init(devicePoint: CGPoint, inView previewView: CapturePreviewView) {
        self.init(frame: CGRect.zero)
        previewView.addSubview(self)
        self.moveInterestPointerTo(devicePoint)
    }
    
    // MARK: |  Layout and Apearance
    
    
    func drawShapeLayer(_ animated:Bool) {
        var pointerAxisLinePathDistanceFromBorder = _defaultPointerAxisLinePathDistanceFromBorder
        var pointerSquareBorderDistanceFromBorder = _defaultPointerSquareBorderDistanceFromBorder
        var width = _defaultWidth
        var height = _defaultHeight
        
        if (locked) {
            pointerAxisLinePathDistanceFromBorder = _lockedPointerAxisLinePathDistanceFromBorder
            pointerSquareBorderDistanceFromBorder = _lockedPointerSquareBorderDistanceFromBorder
            width = _lockedWidth
            height = _lockedHeight
        }
        let marginX = (frame.width - width)/2
        let marginY = (frame.height - height)/2
        
        let center = CGPoint(x: frame.width/2, y: frame.width/2)
        
        
        let squareRect = CGRect(x: marginX + pointerSquareBorderDistanceFromBorder, y: marginY + pointerSquareBorderDistanceFromBorder, width: frame.width - (2*(marginX+pointerSquareBorderDistanceFromBorder)), height: frame.height - (2*(marginY+pointerSquareBorderDistanceFromBorder)))
        let squarePath = UIBezierPath(ovalIn: squareRect).cgPath
        
        let topPointerAxisLinePath = CGMutablePath()
        let rightPointerAxisLinePath = CGMutablePath()
        let bottomPointerAxisLinePath = CGMutablePath()
        let leftPointerAxisLinePath = CGMutablePath()
        
        topPointerAxisLinePath.move(to: CGPoint(x:center.x, y:marginY+pointerAxisLinePathDistanceFromBorder))
        topPointerAxisLinePath.addLine(to: CGPoint(x:center.x, y:marginY));
        
        rightPointerAxisLinePath.move(to: CGPoint(x:frame.width - pointerAxisLinePathDistanceFromBorder - marginX, y:center.y))
        rightPointerAxisLinePath.addLine(to: CGPoint(x:width + marginX, y:center.y));
        
        bottomPointerAxisLinePath.move(to: CGPoint(x:center.x, y:frame.height - pointerAxisLinePathDistanceFromBorder - marginY));
        bottomPointerAxisLinePath.addLine(to: CGPoint(x:center.x, y:frame.height - marginY));
        
        leftPointerAxisLinePath.move(to: CGPoint(x:marginX+pointerAxisLinePathDistanceFromBorder, y:center.y));
        leftPointerAxisLinePath.addLine(to: CGPoint(x:marginY, y:center.y));
        
        let combinedPath: CGMutablePath = squarePath.mutableCopy()!;
        combinedPath.addPath(topPointerAxisLinePath);
        combinedPath.addPath(rightPointerAxisLinePath);
        combinedPath.addPath(bottomPointerAxisLinePath);
        combinedPath.addPath(leftPointerAxisLinePath);
        
        
        // Create initial shape of the view
        if _shapeLayer == nil {
            _shapeLayer = CAShapeLayer()
            _shapeLayer.path = combinedPath
            _shapeLayer.shadowColor = _shadowColor
            _shapeLayer.shadowOffset = _shadowOffset
            _shapeLayer.shadowOpacity = _shadowOpacity
            _shapeLayer.shadowRadius = _shadowRadius
            _shapeLayer.masksToBounds = false
            _shapeLayer.strokeColor = UIColor.clear.cgColor
            _shapeLayer.fillColor = UIColor.clear.cgColor
        }else if animated {
            
            let animation = CABasicAnimation(keyPath: "path")
            animation.fromValue = _shapeLayer.path// we are pretending that the path hasnt changed yet
            animation.duration = _shapeLayerAnimationDuration
            // 3
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut) // animation curve is Ease Out
            animation.fillMode = kCAFillModeBoth // keep to value after finishing
            animation.isRemovedOnCompletion = false // don't remove after finishing
            // 4
            _shapeLayer.add(animation, forKey: animation.keyPath)
            _shapeLayer.path = combinedPath
        }
    }
    
    func updateApearance()
    {
        if adjusting {
            if locked {
                _shapeLayer.strokeColor = _lockedAdjustingStrokeColor
            }else{
                _shapeLayer.strokeColor = _defaultAdjustingStrokeColor
            }
        }else{
            if locked {
                _shapeLayer.strokeColor = _lockedStrokeColor
            }else{
                _shapeLayer.strokeColor = _defaultStrokeColor
            }
        }
    }
    
    func setHidden(_ hidden: Bool, animated: Bool) {
        //animate hide/show
        self.isHidden = hidden
    }
    
    func show(hideAfterDelay delay: Double) {
        //show
        self.setHidden(false, animated: false)
        //hide after delay
        let delayNSEC = delay * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        let dispatchTime = DispatchTime.now() + Double(Int64(delayNSEC)) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
            // Subtract 1 from timer count
            self._showAndHideTimerCount -= 1
            if self._showAndHideTimerCount == 0 {
                self.setHidden(true, animated: true)
            }
        })
        // Add 1 to timer count
        self._showAndHideTimerCount += 1
    }
    
    func moveInterestPointerTo(_ devicePoint: CGPoint){
        //if self.superview != previewView {println("Warning! self.superview != previewView. Positioning might be incorrect. \n moveToPointInsideView()")}
        DispatchQueue.main.async(execute: {
            if self.superview != nil {
                //self.superview?.removeConstraints(self.constraints())
                //println("layer.height:\(self.superview?.layer.bounds.height) view.height:\(self.superview?.frame.height)")
                let coordinateInterestPoint = self.superview!.layer.pointForCaptureDevicePoint(ofInterest: devicePoint)
                var proportionalPoint = CGPoint(x: coordinateInterestPoint.x/self.superview!.frame.width, y: coordinateInterestPoint.y/self.superview!.frame.height)
                
                //pointForCaptureDevicePointOfInterest not accurate so use devicePoint
                if devicePoint == coordinateInterestPoint{
                    proportionalPoint = devicePoint
                    //self.adjusting = false
                }
                
                let width = self._defaultWidth
                let height = self._defaultHeight
                
                /*if self.locked {
                width = self.lockedWidth
                height = self.lockedHeight
                }*/
                
                
                self.translatesAutoresizingMaskIntoConstraints = false
                
                let centerXConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self.superview, attribute: NSLayoutAttribute.right, multiplier: proportionalPoint.x, constant: 0)
                centerXConstraint.identifier = "centerXConstraint"
                
                let centerYConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self.superview, attribute: NSLayoutAttribute.bottom, multiplier: proportionalPoint.y, constant: 0)
                centerXConstraint.identifier = "centerYConstraint"
                
                let widthConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0, constant: width)
                centerXConstraint.identifier = "widthConstraint"
                
                let heightConstraint = NSLayoutConstraint(item: self, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 0, constant: height)
                centerXConstraint.identifier = "centerXConstraint"
                
                self.removeConstraintIfNeedsReplaced(self._centerXConstraint)
                self.removeConstraintIfNeedsReplaced(self._centerYConstraint)
                self.removeConstraintIfNeedsReplaced(self._widthConstraint)
                self.removeConstraintIfNeedsReplaced(self._heightConstraint)
                
                self.superview!.addConstraints([centerXConstraint, centerYConstraint, widthConstraint, heightConstraint])
                
                self._centerXConstraint = centerXConstraint
                self._centerYConstraint = centerYConstraint
                self._widthConstraint = widthConstraint
                self._heightConstraint = heightConstraint
                
            }else{
                self.center = CGPoint.zero
                print("\n\n\n\nInterestPointer has no superview and can not be moved")
            }
            
            if self.automaticallyShowAndHide {
                self.adjusting = true
            }
            
        })
        //println("con: \(self.superview?.constraints())")
    }
    
    // MARK: |  Utilities
    
    func removeConstraintIfNeedsReplaced(_ constraint: NSLayoutConstraint?) {
        if constraint != nil {
            self.superview!.removeConstraint(constraint!)
        }
    }
    
}

//
//  CaptureViewController.swift
//  Action Recorder
//
//  Created by Jean on 6/24/15.
//  Copyright (c) 2015 mobileuse. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary

protocol CaptureViewControllerDelegate {
    func didCaptureImage(_ image:CGImage)
}

enum CaptureFocusMode {
    case locked, tap, auto
}

enum CaptureExposureMode {
    case locked, tap, auto
}

enum CaptureWhiteBalanceMode {
    case locked, tap, auto
}

extension AVCaptureVideoOrientation {
    var uiInterfaceOrientation: UIInterfaceOrientation {
        get {
            switch self {
            case .landscapeLeft:        return .landscapeLeft
            case .landscapeRight:       return .landscapeRight
            case .portrait:             return .portrait
            case .portraitUpsideDown:   return .portraitUpsideDown
            }
        }
    }
    
    init(ui:UIInterfaceOrientation) {
        switch ui {
        case .landscapeRight:       self = .landscapeRight
        case .landscapeLeft:        self = .landscapeLeft
        case .portrait:             self = .portrait
        case .portraitUpsideDown:   self = .portraitUpsideDown
        default:                    self = .portrait
        }
    }
}

typealias KVOContext = UInt8

var CapturingStillImageContext = KVOContext()
var RecordingContext = KVOContext()
var SessionRunningAndDeviceAuthorizedContext = KVOContext()

var AdjustingFocusContext = KVOContext()
var AdjustingExposureContext = KVOContext()

var FocusModeContext = KVOContext()
var ExposureModeContext = KVOContext()
var WhiteBalanceModeContext = KVOContext()
var LensPositionContext = KVOContext()
var ExposureDurationContext = KVOContext()
var ISOContext = KVOContext()
var ExposureTargetOffsetContext = KVOContext()
var DeviceWhiteBalanceGainsContext = KVOContext()
var LensStabilizationContext = KVOContext()

let kExposureDurationPower: Double = 5 // Higher numbers will give the slider more sensitivity at shorter durations
let kExposureMinimumDuration:Double = 1.0/1000 // Limit exposure duration to a useful range

let capturePreviewAspectRatio: CGFloat = 16/9

class CaptureViewController: UIViewController {
    
    //MARK: Properties
    
    //MARK: |   config constants
    
    // toolbar
    fileprivate let _TBWidth: CGFloat = 120
    
    // multi purpose button
    fileprivate let _MPBWidth: CGFloat = 40
    fileprivate let _MPBHeight: CGFloat = 40
    fileprivate let _MPBMargin: CGFloat = 5
    
    // Settings View
    
    fileprivate var _SVLabelColor = UIColor.white
    fileprivate var _SVValueLabelColor = UIColor.white
    fileprivate var _SVLabels = [UILabel]()
    fileprivate var _SVValueLabels = [UILabel]()
    @IBOutlet fileprivate var _SVControl: UISegmentedControl!
    
    // Focus Settings View
    @IBOutlet fileprivate var _FSVBottom: NSLayoutConstraint!
    @IBOutlet fileprivate var _FSVTrailing: NSLayoutConstraint!
    @IBOutlet fileprivate var _FSVLeading: NSLayoutConstraint!
    @IBOutlet fileprivate var _FSVTop: NSLayoutConstraint!
    fileprivate var _FSVConstraints = [NSLayoutConstraint]()
    
    @IBOutlet fileprivate var _FSV: UIView!
    @IBOutlet fileprivate var _FSVFocusValueLabel: UILabel!
    @IBOutlet fileprivate var _FSVFocusLabel: UILabel!
    @IBOutlet fileprivate var _FSVModeLabel: UILabel!
    @IBOutlet fileprivate var _FSVFocusSlider: UISlider!
    @IBOutlet fileprivate var _FSVModeControl: UISegmentedControl!
    fileprivate var _FSVModes: [CaptureFocusMode] = [.locked, .tap, .auto]
    fileprivate var _FSVShouldUpdateFocusSlider = true
    
    
    // Exposure Settings View
    @IBOutlet fileprivate var _ESVLeading: NSLayoutConstraint!
    @IBOutlet fileprivate var _ESVTop: NSLayoutConstraint!
    @IBOutlet fileprivate var _ESVBottom: NSLayoutConstraint!
    @IBOutlet fileprivate var _ESVTrailing: NSLayoutConstraint!
    fileprivate var _ESVConstraints = [NSLayoutConstraint]()
    
    @IBOutlet fileprivate var _ESV: UIView!
    @IBOutlet fileprivate var _ESVISOValueLabel: UILabel!
    @IBOutlet fileprivate var _ESVDurationValueLabel: UILabel!
    @IBOutlet fileprivate var _ESVISOLabel: UILabel!
    @IBOutlet fileprivate var _ESVDurationLabel: UILabel!
    @IBOutlet fileprivate var _ESVModeLabel: UILabel!
    @IBOutlet fileprivate var _ESVISOSlider: UISlider!
    @IBOutlet fileprivate var _ESVDurationSlider: UISlider!
    @IBOutlet fileprivate var _ESVModeControl: UISegmentedControl!
    fileprivate var _ESVModes: [CaptureExposureMode] = [.locked, .tap, .auto]//.Custom
    fileprivate var _ESVShouldUpdateDurationSlider = true
    fileprivate var _ESVShouldUpdateISOSlider = true
    
    
    // White Balance Settings View
    @IBOutlet fileprivate var _WBSVTrailing: NSLayoutConstraint!
    @IBOutlet fileprivate var _WBSVBottom: NSLayoutConstraint!
    @IBOutlet fileprivate var _WBSVTop: NSLayoutConstraint!
    @IBOutlet fileprivate var _WBSVLeading: NSLayoutConstraint!
    fileprivate var _WBSVConstraints = [NSLayoutConstraint]()
    
    @IBOutlet fileprivate var _WBSV: UIView!
    @IBOutlet fileprivate var _WBSVTempValueLabel: UILabel!
    @IBOutlet fileprivate var _WBSVTintValueLabel: UILabel!
    @IBOutlet fileprivate var _WBSVTempLabel: UILabel!
    @IBOutlet fileprivate var _WBSVTintLabel: UILabel!
    @IBOutlet fileprivate var _WBSVModeLabel: UILabel!
    @IBOutlet fileprivate var _WBSVTempSlider: UISlider!
    fileprivate let _WBSVTempDefaultMin:Float = 3000
    fileprivate let _WBSVTempDefaultMax:Float = 8000
    @IBOutlet fileprivate var _WBSVTintSlider: UISlider!
    fileprivate let _WBSVTintDefaultMin:Float = -150
    fileprivate let _WBSVTintDefaultMax:Float = 150
    @IBOutlet fileprivate var _WBSVModeControl: UISegmentedControl!
    fileprivate var _WBSVModes: [CaptureWhiteBalanceMode] = [.locked, .tap, .auto]
    fileprivate var _WBSVShouldUpdateTempSlider = true
    fileprivate var _WBSVShouldUpdateTintSlider = true
    
    //MARK: |   subviews
    @IBOutlet var previewView: CapturePreviewView!
    
    var toolbar: CaptureViewToolbar! = nil
    var multiPurposeButton: CaptureViewMultiPurposeButton! = nil
    
    var toolbarTrailingSpaceConstraint: NSLayoutConstraint! = nil
    
    //MARK: |   Session Management
    
    let session = AVCaptureSession()
    var sessionQueue: DispatchQueue! = nil
    var deviceInput = AVCaptureDeviceInput()
    var device: AVCaptureDevice! = nil
    fileprivate var _deviceSupportedFocusModes: [CaptureFocusMode : AVCaptureFocusMode?]! = nil
    fileprivate var _deviceSupportedExposureModes: [CaptureExposureMode : AVCaptureExposureMode?]! = nil
    fileprivate var _deviceSupportedWhiteBalanceModes: [CaptureWhiteBalanceMode : AVCaptureWhiteBalanceMode?]! = nil
    //var movieFileOutput = AVCaptureMovieFileOutput()
    var stillImageOutput = AVCaptureStillImageOutput()
    
    
    var delegate: CaptureViewControllerDelegate? = nil
    
    fileprivate var _overlayImage: CGImage? = nil
    var overlayImage: CGImage? {
        set{
            _overlayImage = newValue
            if newValue != nil {
                previewView.overlayImage = newValue
            }
        }
        
        get{
            return _overlayImage
        }
    }
    
    //MARK: |   Utilities
    
    var lockInterfaceRotation: Bool = false
    var deviceAuthorized: Bool = false
    var backgroundRecordingID = UIBackgroundTaskIdentifier()
    var runtimeErrorHandlingObserver: AnyObject? = nil
    var sessionRunningAndDeviceAuthorized: Bool {
            return self.session.isRunning && self.deviceAuthorized
    }
    
    var lockWasToggledOn: Bool = false
    
    var adjustingFocus: Bool = false
    var adjustingExposure: Bool = false
    
    fileprivate var _focusMode: CaptureFocusMode! = nil
    var focusMode: CaptureFocusMode! {
        set{
            if focusMode != newValue {
                guard device != nil else {print("focusMode: device was nil");return}
                do {
                    try device.lockForConfiguration()
                    _focusMode = newValue
                    device.focusMode = _AVFocusModeForFocusMode(focusMode)
                    _FSVModeControl.selectedSegmentIndex = _FSVModes.index(of: focusMode)!
                    if focusMode == .auto {
                        moveAutoPoint(autoPoint)
                    }
                    if focusMode != nil && exposureMode != nil {
                        device.isSubjectAreaChangeMonitoringEnabled = (focusMode == .auto || exposureMode == .auto)
                    }
                    device.unlockForConfiguration()
                } catch {print("focusMode: catch try device.lockForConfiguration()")}
            }
        }
        get{
            return _focusMode
        }
    }
    
    fileprivate var _exposureMode: CaptureExposureMode! = nil
    var exposureMode: CaptureExposureMode! {
        set {
            if exposureMode != newValue {
                guard device != nil else {print("exposureMode: device was nil");return}
                do {
                    try device.lockForConfiguration()
                    _exposureMode = newValue
                    device.exposureMode = _AVExposureModeForExposureMode(exposureMode)
                    _ESVModeControl.selectedSegmentIndex = _ESVModes.index(of: exposureMode)!
                    if exposureMode == .auto {
                        moveAutoPoint(autoPoint)
                    }
                    if focusMode != nil && exposureMode != nil {
                        device.isSubjectAreaChangeMonitoringEnabled = (focusMode == .auto || exposureMode == .auto)
                    }
                    device.unlockForConfiguration()
                } catch {print("exposureMode: catch try device.lockForConfiguration()")}
            }
        }
        get {
            return _exposureMode
        }
    }
    
    fileprivate var _whiteBalanceMode: CaptureWhiteBalanceMode! = nil
    var whiteBalanceMode: CaptureWhiteBalanceMode! {
        set {
            if whiteBalanceMode != newValue {
                guard device != nil else {print("whiteBalanceMode: device was nil");return}
                do {
                    try device.lockForConfiguration()
                    _whiteBalanceMode = newValue
                    device.whiteBalanceMode = _AVWhiteBalanceModeForWhiteBalanceMode(whiteBalanceMode)
                    _WBSVModeControl.selectedSegmentIndex = _WBSVModes.index(of: whiteBalanceMode)!
                    if whiteBalanceMode == .auto {
                        moveAutoPoint(autoPoint)
                    }
                    device.unlockForConfiguration()
                } catch {print("whiteBalanceMode: catch try device.lockForConfiguration()")}
            }
        }
        get {
            return _whiteBalanceMode
        }
    }
    
    var autoPoint: CGPoint! = CGPoint(x: 0.5, y: 0.5)
    
    //MARK: Methods
    //MARK: |   UIViewController
    
    override func loadView() {
        view = Bundle.main.loadNibNamed("CaptureViewController", owner: self, options: nil)?.first as! UIView

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup CapturePreviewView
        
        self._FSVConstraints  = [_FSVTop, _FSVTrailing, _FSVBottom, _FSVLeading]
        self._ESVConstraints  = [_ESVTop, _ESVTrailing, _ESVBottom, _ESVLeading]
        self._WBSVConstraints  = [_WBSVTop, _WBSVTrailing, _WBSVBottom, _WBSVLeading]
        
        NSLayoutConstraint.deactivate(_FSVConstraints)
        NSLayoutConstraint.deactivate(_ESVConstraints)
        NSLayoutConstraint.deactivate(_WBSVConstraints)
        _FSV.isHidden = true
        _ESV.isHidden = true
        _WBSV.isHidden = true
        
        _SVLabels = [_FSVFocusLabel, _FSVModeLabel, _ESVISOLabel, _ESVDurationLabel, _ESVModeLabel, _WBSVTempLabel, _WBSVTintLabel, _WBSVModeLabel]
        _SVValueLabels = [_FSVFocusValueLabel, _ESVISOValueLabel, _ESVDurationValueLabel, _WBSVTempValueLabel, _WBSVTintValueLabel]
        
        for label in _SVLabels {
            label.textColor = _SVLabelColor
        }
        
        for valueLabel in _SVValueLabels {
            valueLabel.textColor = _SVValueLabelColor
        }
        
        self.previewView.session = self.session
        
        // Check for device authorization
        self.checkDeviceAuthorizationStatus()
        // -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue so that the main queue isn't blocked (which keeps the UI responsive).
        self.sessionQueue = DispatchQueue(label: "session queue", attributes: [])
        self.sessionQueue.async(execute: {
            self.backgroundRecordingID = UIBackgroundTaskInvalid
            
            self.beginSession()
            
            // set up still image output
            
            let stillImageOutput = AVCaptureStillImageOutput()
            if self.session.canAddOutput(stillImageOutput){
                stillImageOutput.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
                self.session.addOutput(stillImageOutput)
                self.stillImageOutput = stillImageOutput
            }else{print("self.session.canAddOutput(stillImageOutput) == false \n could not addOutput(stillImageOutput) \n viewDidLoad")}
        })
        DispatchQueue.main.async(execute: {
            self.configureControls()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.startRunningSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.stopRunningSession()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //handle rotation
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        //all good change orientation
        self.previewView.videoOrientation = AVCaptureVideoOrientation(ui:toInterfaceOrientation)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.landscape// | Int(UIInterfaceOrientationMask.PortraitUpsideDown.rawValue)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let newValue = change![NSKeyValueChangeKey.newKey]
        let oldValue = change![NSKeyValueChangeKey.oldKey]
        func updatePointerView() {
            DispatchQueue.main.async(execute: {
                if !self.adjustingFocus && !self.adjustingExposure {
                    self.previewView.pointer.adjusting = false
                }else if self.adjustingFocus || self.adjustingExposure{
                    self.previewView.pointer.adjusting = true
                }
            })
        }
        
        if context == &CapturingStillImageContext {
            let isCapturingStillImage = newValue as! Bool
            if isCapturingStillImage {
                //self.runStillImageCaptureAnimation()
            }
        }else if context == &RecordingContext {

        }else if context == &SessionRunningAndDeviceAuthorizedContext {
            
        }else if context == &AdjustingFocusContext {
            self.adjustingFocus = newValue as! Bool
            updatePointerView()
        }else if context == &AdjustingExposureContext {
            self.adjustingExposure = newValue as! Bool
            updatePointerView()
        }else if context == &FocusModeContext {
            /*guard let newRawValue = newValue as? Int else {print(newValue);return}
            //guard let oldRawValue = oldValue as? Int else {print(oldValue);return}
            let newAVFocusMode = AVCaptureFocusMode(rawValue: newRawValue)!
            var newFocusMode: CaptureFocusMode! = nil
            switch newAVFocusMode {
            case .Locked, .AutoFocus:
                newFocusMode = self.previewView.pointer.locked ? .Locked : .Tap
            case .ContinuousAutoFocus:
                newFocusMode = .Auto
            }
            dispatch_async(dispatch_get_main_queue(), {
                self._FSVModeControl.selectedSegmentIndex = self._FSVModes.indexOf(newFocusMode) ?? -1
            })*/
        }else if context == &ExposureModeContext {
            /*guard let newRawValue = newValue as? Int else {print(newValue);return}
            //guard let oldRawValue = oldValue as? Int else {print(oldValue);return}
            let newAVExposureMode = AVCaptureExposureMode(rawValue: newRawValue)!
            dispatch_async(dispatch_get_main_queue(), {
                self._ESVModeControl.selectedSegmentIndex = self._ESVModes.indexOf(newAVExposureMode) ?? -1
            })*/
        }else if context == &WhiteBalanceModeContext {
            /*guard let newRawValue = newValue?.integerValue else {print(newValue);return}
            //guard let oldRawValue = oldValue as? Int else {print(oldValue);return}
            let newWhiteBalanceMode = AVCaptureWhiteBalanceMode(rawValue: newRawValue)!
            dispatch_async(dispatch_get_main_queue(), {
                self._WBSVModeControl.selectedSegmentIndex = self._WBSVModes.indexOf(newWhiteBalanceMode) ?? -1
            })*/
        }else if context == &LensPositionContext {
            guard let newFloatValue = (newValue as AnyObject).floatValue else {print(newValue as Any);return}
            //guard let oldFloatValue = oldValue as? Float else {print(oldValue);return}
            DispatchQueue.main.async(execute: {
                if self.focusMode != .locked {
                    self._FSVFocusSlider.value = newFloatValue
                    self._FSVUpdateFocusValueLabel(newFloatValue)
                }
            })
        }else if context == &ExposureDurationContext {
            guard let newTimeValue = (newValue as AnyObject).timeValue else {print("ExposureDurationContext \((newValue as AnyObject).timeValue)");return}
            
            DispatchQueue.main.async(execute: {
                if self.exposureMode != .locked {
                    self._ESVDurationSlider.value = self._valueFromCMTime(newTimeValue)
                    self._ESVUpdateDurationValueLabel(newTimeValue)
                }
            })
        }else if context == &ISOContext {
            guard let newFloatValue = newValue as? Float else {print(newValue as Any);return}
            //guard let oldFloatValue = oldValue as? Float else {print(oldValue);return}
            DispatchQueue.main.async(execute: {
                if self.exposureMode != .locked {
                    self._ESVISOSlider.value = newFloatValue
                    self._ESVUpdateISOValueLabel(newFloatValue)
                }
            })
        }else if context == &ExposureTargetOffsetContext {
        }else if context == &DeviceWhiteBalanceGainsContext {
            let newGains = device.deviceWhiteBalanceGains
            let newTempAndTint = device.temperatureAndTintValues(forDeviceWhiteBalanceGains: newGains)
            DispatchQueue.main.async(execute: {
                if self.whiteBalanceMode != .locked {
                    self._WBSVTempSlider.value = newTempAndTint.temperature
                    self._WBSVTintSlider.value = newTempAndTint.tint
                    self._WBSVUpdateTempValueLabel(newTempAndTint.temperature)
                    self._WBSVUpdateTintValueLabel(newTempAndTint.tint)
                }
            })
        }else if context == &LensStabilizationContext {
        }else{
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
        
        /*
        var FocusModeContext = &FocusModeContext;
        var ExposureModeContext = &ExposureModeContext;
        var WhiteBalanceModeContext = &WhiteBalanceModeContext;
        var LensPositionContext = &LensPositionContext;
        var ExposureDurationContext = &ExposureDurationContext;
        var ISOContext = &ISOContext;
        var ExposureTargetOffsetContext = &ExposureTargetOffsetContext;
        var DeviceWhiteBalanceGainsContext = &DeviceWhiteBalanceGainsContext;
        var LensStabilizationContext = &LensStabilizationContext;
        */
    }
    
    
    
    //MARK: |   Authorization
    
    func keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized() -> NSSet {
        return NSSet(objects: "session.running", "deviceAuthorized")
    }
    
    func checkDeviceAuthorizationStatus() {
        let mediaType = AVMediaTypeVideo
        AVCaptureDevice.requestAccess(forMediaType: mediaType, completionHandler: {(granted) -> Void in
            if (granted){
                self.deviceAuthorized = true
            }else{
                //alert about private settings
                DispatchQueue.main.async(execute: {
                    let title = appName
                    let message = "\(appName) doesn't have permission to use Camera, please change privacy settings"
                    let cancelButtonTitle = "OK"
                    
                    let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
                    let cancelAction = UIAlertAction(title: cancelButtonTitle, style: UIAlertActionStyle.cancel, handler: {(action) in})
                    
                    alertController.addAction(cancelAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                })
            }
        })
    }
    
    
    
    //MARK: |  Session
    
    func startRunningSession(){
        self.sessionQueue.async(execute: {
            self.addObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", options: ([.new, .old]), context: &CapturingStillImageContext)
            //self.addObserver(self, forKeyPath: "movieFileOutput.recording", options: (.New | .Old), context: &RecordingContext)
            self.addObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized", options: ([.new, .old]), context: &SessionRunningAndDeviceAuthorizedContext)
            self.addObserver(self, forKeyPath: "device.adjustingFocus", options: ([.new, .old]), context: &AdjustingFocusContext)
            self.addObserver(self, forKeyPath: "device.adjustingExposure", options: ([.new, .old]), context: &AdjustingExposureContext)
            
            self.addObserver(self, forKeyPath: "device.focusMode", options: ([.new, .old]), context: &FocusModeContext)
            self.addObserver(self, forKeyPath: "device.exposureMode", options: ([.new, .old]), context: &ExposureModeContext)
            self.addObserver(self, forKeyPath: "device.whitBalanceMode", options: ([.new, .old]), context: &WhiteBalanceModeContext)
            self.addObserver(self, forKeyPath: "device.ISO", options: ([.new, .old]), context: &ISOContext)
            self.addObserver(self, forKeyPath: "device.exposureTargetOffset", options: ([.new, .old]), context: &ExposureTargetOffsetContext)
            self.addObserver(self, forKeyPath: "device.exposureDuration", options: ([.new, .old]), context: &ExposureDurationContext)
            self.addObserver(self, forKeyPath: "device.deviceWhiteBalanceGains", options: ([.new, .old]), context: &DeviceWhiteBalanceGainsContext)
            self.addObserver(self, forKeyPath: "device.lensPosition", options: ([.new, .old]), context: &LensPositionContext)
            
            
            NotificationCenter.default.addObserver(self, selector: #selector(CaptureViewController.subjectAreaDidChange(_:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: self.deviceInput.device)
            
            weak var weakSelf = self
            self.runtimeErrorHandlingObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureSessionRuntimeError, object: self.session, queue: nil, using: {(notification) -> Void in
                let strongSelf = weakSelf!
                strongSelf.sessionQueue.async(execute: {
                    print("AVCaptureSessionRuntimeErrorNotification \n startRunningSession()")
                    // Manually restarting the session since it must have been stopped due to an error.
                    strongSelf.session.startRunning()
                    //[[strongSelf recordButton] setTitle:NSLocalizedString(@"Record", @"Recording button record title") forState:UIControlStateNormal];
                })
            })
            self.session.startRunning()
        })
    }
    
    func stopRunningSession(){
        self.sessionQueue.async(execute: {
            self.session.startRunning()
            
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: self.deviceInput.device)
            NotificationCenter.default.removeObserver(self.runtimeErrorHandlingObserver!)
            
            self.removeObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", context: &CapturingStillImageContext)
            //self.removeObserver(self, forKeyPath: "movieFileOutput.recording", context: &RecordingContext)
            self.removeObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized", context: &SessionRunningAndDeviceAuthorizedContext)
            self.previewView.pointer.removeObserver(self, forKeyPath: "adjustingFocus", context: &AdjustingFocusContext)
            self.previewView.pointer.removeObserver(self, forKeyPath: "adjustingExposure", context: &AdjustingExposureContext)
            
            self.removeObserver(self, forKeyPath: "device.focusMode", context: &FocusModeContext)
            self.removeObserver(self, forKeyPath: "device.exposureMode", context: &ExposureModeContext)
            self.removeObserver(self, forKeyPath: "device.whitBalanceMode", context: &WhiteBalanceModeContext)
            self.removeObserver(self, forKeyPath: "device.ISO", context: &ISOContext)
            self.removeObserver(self, forKeyPath: "device.exposureTargetOffset", context: &ExposureTargetOffsetContext)
            self.removeObserver(self, forKeyPath: "device.exposureDuration", context: &ExposureDurationContext)
            self.removeObserver(self, forKeyPath: "device.deviceWhiteBalanceGains", context: &DeviceWhiteBalanceGainsContext)
            self.removeObserver(self, forKeyPath: "device.lensPosition", context: &LensPositionContext)
        })
    }
    
    
    
    // MARK: |   Actions
    
    func subjectAreaDidChange(_: Notification!){
        let devicePoint : CGPoint = CGPoint(x: 0.5, y: 0.5)
        self.moveAutoPoint(devicePoint)
    }
    
    @IBAction func longPressLock(_ sender: UIGestureRecognizer) {
        if (sender.state == UIGestureRecognizerState.began){
            let interestPoint = sender.location(in: sender.view)
            let devicePoint = self.previewView.layer.captureDevicePointOfInterest(for: interestPoint)
            self.focusWithMode(AVCaptureFocusMode.autoFocus, exposureMode: AVCaptureExposureMode.autoExpose, devicePoint: devicePoint)
            self.previewView.pointer.locked = true
            self.focusMode = .locked
            self.exposureMode = .locked
            self.whiteBalanceMode = .locked
        }
    }
    
    @IBAction func doubleTapToggleLock(_ sender: UIGestureRecognizer) {
        //self.previewView.pointer.locked = !self.previewView.pointer.locked
        self.focusMode = self.previewView.pointer.locked ? .locked : .auto
        self.exposureMode = self.previewView.pointer.locked ? .locked : .auto
        self.whiteBalanceMode = self.previewView.pointer.locked ? .locked : .auto
    }
    
    @IBAction func tapFocus(_ sender: UIGestureRecognizer){
        let tapLocation = sender.location(in: sender.view)
        let devicePoint = self.previewView.layer.captureDevicePointOfInterest(for: tapLocation)
        switch _SVControl.selectedSegmentIndex {
        case 0:// focus
            switch focusMode! {
            case .locked:
                print("tapFocus: .Locked")
            case .tap:
                focusWithMode(_AVFocusModeForFocusMode(focusMode), exposureMode: nil, devicePoint: devicePoint)
            case .auto:
                moveAutoPoint(devicePoint)
            }
        case 1:// exposure
            switch exposureMode! {
            case .locked:
                print("tapFocus: .Locked")
            case .tap:
                focusWithMode(nil, exposureMode: _AVExposureModeForExposureMode(exposureMode), devicePoint: devicePoint)
            case .auto:
                moveAutoPoint(devicePoint)
            }
        case 2:// white balance
            switch whiteBalanceMode! {
            case .locked:
                print("tapFocus: .Locked")
            case .tap:
                focusWithMode(nil, exposureMode: nil, devicePoint: devicePoint)
                do {
                    try device.lockForConfiguration()
                    device.setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains(device.grayWorldDeviceWhiteBalanceGains, completionHandler: nil)
                    device.unlockForConfiguration()
                } catch{print(error);return}
            case .auto:
                moveAutoPoint(devicePoint)
            }
        default:// off
            if focusMode == .auto || exposureMode == .auto || whiteBalanceMode == .auto {
                moveAutoPoint(devicePoint)
            }
        }
    }
    
    func performIfPointIsInPreviewBounds(pointInView point: CGPoint, perform: () -> Void) {
        let previewViewAspectRatio = self.previewView.frame.width/self.previewView.frame.height
        var xMargin:CGFloat = 0
        var yMargin:CGFloat = 0

        if previewViewAspectRatio > capturePreviewAspectRatio  {
            // if there is margin in x axis and height of layer and view are equal
            xMargin = (self.previewView.frame.width - self.previewView.frame.height * capturePreviewAspectRatio)/2
            
            if point.x > xMargin && point.x <= self.previewView.frame.width - xMargin {
                // if tap point is in range
                perform()
            }
        }else if previewViewAspectRatio < capturePreviewAspectRatio {
            // if there is margin in y axis and width of layer and view are equal
            yMargin = (self.previewView.frame.height -  self.previewView.frame.width / capturePreviewAspectRatio)/2
            
            if point.y > yMargin && point.y <= self.previewView.frame.height - yMargin {
                // if tap point is in range
                perform()
            }
        }else{
            // aspect ratios are equal go ahead and focus
            perform()
        }
    }

    @IBAction func captureStillPhoto() {
        self.sessionQueue.async(execute: {
                let connection = self.stillImageOutput.connection(withMediaType: AVMediaTypeVideo)
                if connection != nil &&  self.previewView.connection != nil{
                    // Update the orientation on the still image output video connection before capturing.
                    connection?.videoOrientation = self.previewView.videoOrientation
                    // Flash set to Auto for Still Capture
                    //self.setFlashMode
                    self.stillImageOutput.captureStillImageAsynchronously(from: connection){
                        (imageSampleBuffer, error) in
                        
                        if((imageSampleBuffer) != nil){
                            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
                            let image: UIImage = UIImage(data: imageData!)!
                            
                            let orientation = image.imageOrientation
                            self.delegate?.didCaptureImage(CGImageOrientation(image.cgImage!, orientation: orientation))
                            //self.project.appendAnimationFrame(AnimationFrame(image: CGImageOrientation(image.CGImage, orientation), frameCountDuration: 2))
                            ALAssetsLibrary().writeImage(toSavedPhotosAlbum: image.cgImage, orientation: ALAssetOrientation(rawValue: image.imageOrientation.rawValue)!, completionBlock: { (path:URL?, error:Error?) -> Void in
                                // photo saved
                                print("\(path)")
                            })
                        }
                        else{print("imageSampleBuffer == nil \n could not complete captureStillPhoto() \n captureStillPhoto()")}
                    }
                }
                else{print("connection or self.previewView.connection == nil \n could not complete captureStillPhoto() \n captureStillPhoto()")}
        })
    }

    @IBAction func settingsViewControlValueChanged(_ sender: UISegmentedControl) {
        func setActivatedForConstraints(_ constraints: [NSLayoutConstraint], _ activated: Bool) {
            if activated {
                NSLayoutConstraint.activate(constraints)
            } else {
                NSLayoutConstraint.deactivate(constraints)
            }
        }
        
        setActivatedForConstraints(_FSVConstraints, sender.selectedSegmentIndex == 0)
        setActivatedForConstraints(_ESVConstraints, sender.selectedSegmentIndex == 1)
        setActivatedForConstraints(_WBSVConstraints, sender.selectedSegmentIndex == 2)
        _FSV.isHidden = !(sender.selectedSegmentIndex == 0)
        _ESV.isHidden = !(sender.selectedSegmentIndex == 1)
        _WBSV.isHidden = !(sender.selectedSegmentIndex == 2)
}
    
    @IBAction func changeLensPosition(_ sender: UISlider) {
        do {
            try device.lockForConfiguration()
            device.setFocusModeLockedWithLensPosition(sender.value, completionHandler: nil)
            device.unlockForConfiguration()
        }
        catch {
            print(error)
        }
        _FSVUpdateFocusValueLabel(sender.value)
    }
    
    @IBAction func changeISO(_ sender: UISlider) {
        do {
            try device.lockForConfiguration()
            device.setExposureModeCustomWithDuration(_CMTimeFromValue(_ESVDurationSlider.value), iso: sender.value, completionHandler: nil)
            device.unlockForConfiguration()
        }
        catch {
            print(error)
        }
        _ESVUpdateISOValueLabel(sender.value)
    }
    
    @IBAction func changeDuration(_ sender: UISlider) {
        do {
            try device.lockForConfiguration()
            device.setExposureModeCustomWithDuration(_CMTimeFromValue(sender.value) , iso: _ESVISOSlider.value, completionHandler: nil)
            device.unlockForConfiguration()
        }
        catch {
            print(error)
        }
        _ESVUpdateDurationValueLabel(_CMTimeFromValue(sender.value))
    }
    
    @IBAction func changeTemperature(_ sender: UISlider) {
        let tempAndTint = AVCaptureWhiteBalanceTemperatureAndTintValues(temperature: _WBSVTempSlider.value, tint: _WBSVTintSlider.value)
        let wbgains = _gainsForTempAandTint(tempAndTint)

        do {
            try device.lockForConfiguration()
            device.setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains(_normalizeGains(wbgains), completionHandler: nil)
            device.unlockForConfiguration()
        }
        catch {
            print(error)
        }
        _WBSVUpdateTempValueLabel(sender.value)
    }
    
    @IBAction func changeTint(_ sender: UISlider) {
        let tempAndTint = AVCaptureWhiteBalanceTemperatureAndTintValues(temperature: _WBSVTempSlider.value, tint: _WBSVTintSlider.value)
        let wbgains = _gainsForTempAandTint(tempAndTint)
        
        do {
            try device.lockForConfiguration()
            device.setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains(_normalizeGains(wbgains), completionHandler: nil)
            device.unlockForConfiguration()
        }
        catch {
            print(error)
        }
        _WBSVUpdateTintValueLabel(sender.value)
    }
    
    @IBAction func focusSliderAction(_ sender: UISlider, forEvent event: UIEvent) {
        guard let touch = event.allTouches?.first else {print("focusSliderAction: \(event)");return}
        if touch.phase == .began {
            _FSVShouldUpdateFocusSlider = false
            if focusMode == .auto || focusMode == .tap {
                focusMode = .locked
            }
        }else if touch.phase == .ended || touch.phase == .cancelled {
            _FSVShouldUpdateFocusSlider = true
        }
    }
    
    @IBAction func ISOSliderAction(_ sender: UISlider, forEvent event: UIEvent) {
        guard let touch = event.allTouches?.first else {print("ISOSliderAction: \(event)");return}
        if touch.phase == .began {
            _ESVShouldUpdateISOSlider = false
            if exposureMode == .auto || exposureMode == .tap {
                exposureMode = .locked
            }
        }else if touch.phase == .ended || touch.phase == .cancelled {
            _ESVShouldUpdateISOSlider = true
        }
    }
    
    @IBAction func durationSliderAction(_ sender: UISlider, forEvent event: UIEvent) {
        guard let touch = event.allTouches?.first else {print("durationSliderAction: \(event)");return}
        if touch.phase == .began {
            _ESVShouldUpdateDurationSlider = false
            if self.exposureMode != .locked {
                exposureMode = .locked
            }
        }else if touch.phase == .ended || touch.phase == .cancelled {
            _ESVShouldUpdateDurationSlider = true
        }
    }
    
    @IBAction func tempSliderAction(_ sender: UISlider, forEvent event: UIEvent) {
        guard let touch = event.allTouches?.first else {print("tempSliderAction: \(event)");return}
        if touch.phase == .began {
            _WBSVShouldUpdateTempSlider = false
            if whiteBalanceMode == .auto || whiteBalanceMode == .tap {
                whiteBalanceMode = .locked
            }
        }else if touch.phase == .ended || touch.phase == .cancelled {
            _WBSVShouldUpdateTempSlider = true
            //_setMaxAndMinTint()
        }
    }
    
    @IBAction func tintSliderAction(_ sender: UISlider, forEvent event: UIEvent) {
        guard let touch = event.allTouches?.first else {print("tintSliderAction: \(event)");return}
        if touch.phase == .began {
            _WBSVShouldUpdateTintSlider = false
            if whiteBalanceMode == .auto || whiteBalanceMode == .tap {
                whiteBalanceMode = .locked
            }
        }else if touch.phase == .ended || touch.phase == .cancelled {
            _WBSVShouldUpdateTintSlider = true
        }
    }

    @IBAction func whiteBalanceModeChanged(_ sender: UISegmentedControl) {
        whiteBalanceMode = self._WBSVModes[sender.selectedSegmentIndex]
    }
    
    @IBAction func exposerModeChanged(_ sender: UISegmentedControl) {
        exposureMode = self._ESVModes[sender.selectedSegmentIndex]
    }
    
    @IBAction func focusModeChanged(_ sender: UISegmentedControl) {
        focusMode = self._FSVModes[sender.selectedSegmentIndex]
    }
    
    //MARK: |   UI
    
    func configureControls(){
        // focus controls
        _FSVFocusSlider.minimumValue = 0.0;
        _FSVFocusSlider.maximumValue = 1.0;
        
        
        // exposure controls
        _ESVISOSlider.minimumValue = self.device?.activeFormat.minISO ?? 0
        _ESVISOSlider.maximumValue = self.device?.activeFormat.maxISO ?? 0
            // Use 0-1 as the slider range and do a non-linear mapping from the slider value to the actual device exposure duration
        _ESVDurationSlider.minimumValue = 0
        _ESVDurationSlider.maximumValue = 1
        
        
        // white balance controls
        _WBSVTempSlider.minimumValue = 3000;
        _WBSVTempSlider.maximumValue = 8000;
            //
        _WBSVTintSlider.minimumValue = -150;
        _WBSVTintSlider.maximumValue = 150;

    }
    
    //MARK: |   Session
    
    func beginSession() {
        //device
        let device = self.deviceWithMediaType(AVMediaTypeVideo as NSString!, preferredPosition: .back)
        
        var deviceInput: AVCaptureDeviceInput! = nil
        do {
            deviceInput = try AVCaptureDeviceInput(device: device)
            
        } catch {
            //video device error
            print("video device error:\n \(error) \n viewDidLoad()")
        }
        
        if self.session.canAddInput(deviceInput) {
            self.session.addInput(deviceInput)
            self.deviceInput = deviceInput!
            self.device = device
            configureDevice()
            DispatchQueue.main.async(execute: {
                // Why are we dispatching this to the main queue?
                // Because AVCaptureVideoPreviewLayer is the backing layer for AVCamPreviewView and UIView can only be manipulated on main thread.
                // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                self.previewView.videoOrientation = AVCaptureVideoOrientation(ui:UIApplication.shared.statusBarOrientation)
            })
        }else{print("self.session.canAddInput(deviceInput) == false \n could not addInput(deviceInput) \n viewDidLoad")}
    }
    
    //MARK: |   Device Configuration
    
    func configureDevice() {
        _checkSupportedModes()
        focusMode = .auto
        exposureMode = .auto
        whiteBalanceMode = .auto
    }
    
    fileprivate func _checkSupportedModes() {
        //reset
        _deviceSupportedFocusModes = [.locked : nil, .tap : nil, .auto : nil]
        _deviceSupportedExposureModes = [.locked : nil, .tap : nil, .auto : nil]
        _deviceSupportedWhiteBalanceModes = [.locked : nil, .tap : nil, .auto : nil]
        guard device != nil else {print("device was nil");return}
        if device.isFocusModeSupported(.locked) {
            _deviceSupportedFocusModes[.locked] = AVCaptureFocusMode.locked
        }
        if device.isFocusModeSupported(.autoFocus) {
            _deviceSupportedFocusModes[.tap] = AVCaptureFocusMode.autoFocus
        }
        if device.isFocusModeSupported(.continuousAutoFocus) {
            _deviceSupportedFocusModes[.auto] = AVCaptureFocusMode.continuousAutoFocus
        }else if device.isFocusModeSupported(.autoFocus){
            _deviceSupportedFocusModes[.auto] = AVCaptureFocusMode.autoFocus
        }
        
        if device.isExposureModeSupported(.locked) {
            _deviceSupportedExposureModes[.locked] = AVCaptureExposureMode.locked
        }
        if device.isExposureModeSupported(.autoExpose) {
            _deviceSupportedExposureModes[.tap] = AVCaptureExposureMode.autoExpose
        }
        if device.isExposureModeSupported(.continuousAutoExposure) {
            _deviceSupportedExposureModes[.auto] = AVCaptureExposureMode.continuousAutoExposure
        }else if device.isExposureModeSupported(.autoExpose){
            _deviceSupportedExposureModes[.auto] = AVCaptureExposureMode.autoExpose
        }
        
        if device.isWhiteBalanceModeSupported(.locked) {
            _deviceSupportedWhiteBalanceModes[.locked] = AVCaptureWhiteBalanceMode.locked
        }
        if device.isWhiteBalanceModeSupported(.autoWhiteBalance) {
            _deviceSupportedWhiteBalanceModes[.tap] = AVCaptureWhiteBalanceMode.autoWhiteBalance
        }else if device.isWhiteBalanceModeSupported(.locked) {
            _deviceSupportedWhiteBalanceModes[.tap] = AVCaptureWhiteBalanceMode.locked
        }
        if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
            _deviceSupportedWhiteBalanceModes[.auto] = AVCaptureWhiteBalanceMode.continuousAutoWhiteBalance
        }else if device.isWhiteBalanceModeSupported(.autoWhiteBalance){
            _deviceSupportedWhiteBalanceModes[.auto] = AVCaptureWhiteBalanceMode.autoWhiteBalance
        }
    }
    
    func setMonitorSubjectAreaChange(_ monitorSubjectAreaChange:Bool){
        self.sessionQueue.async(execute: {
            guard let device = self.device else{print("device nil");return}
            do {
                try device.lockForConfiguration()
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {fatalError("setMonitorSubjectAreaChange: try device.lockForConfiguration()")}
        })
    }
    
    func focusWithMode(_ focusMode:AVCaptureFocusMode?, exposureMode:AVCaptureExposureMode?, devicePoint:CGPoint) {
        //xself.previewView.pointer.moveInterestPointerTo(devicePoint)
        self.sessionQueue.async(execute: {
            guard let device = self.device else{print("device nil");return}
            do {
                try device.lockForConfiguration()
                if focusMode != nil && device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode!){
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode!
                }
                if exposureMode != nil && device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode!){
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode!
                }
                device.unlockForConfiguration()
                //self.autoPoint = devicePoint
            } catch {fatalError("focusWithMode: try device.lockForConfiguration()")}
        })
    }
    
    
    
    func moveAutoPoint(_ devicePoint:CGPoint) {
        self.previewView.pointer.moveInterestPointerTo(devicePoint)
        self.sessionQueue.async(execute: {
            guard let device = self.device else{print("device nil");return}
            do {
                try device.lockForConfiguration()
                let AVFocusMode = self._AVFocusModeForFocusMode(self.focusMode)
                let AVExposureMode = self._AVExposureModeForExposureMode(self.exposureMode)
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(AVFocusMode) && self.focusMode == .auto {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = AVFocusMode
                }
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(AVExposureMode) && self.exposureMode == .auto {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = AVExposureMode
                }
                device.unlockForConfiguration()
                self.autoPoint = devicePoint
            } catch {fatalError("moveAutoPoint: try device.lockForConfiguration()")}
        })
    }
    
    func deviceWithMediaType(_ mediaType:NSString!, preferredPosition:AVCaptureDevicePosition) -> AVCaptureDevice! {
        let devices = AVCaptureDevice.devices(withMediaType: mediaType as String)
        if let captureDevice = devices?.first as? AVCaptureDevice {
            for object in devices! {
                //if object is AVCaptureDevice
                if let device = object as? AVCaptureDevice {
                    //if device position is preferred position use that device
                    if device.position == preferredPosition {
                        return device
                    }
                }
                else{NSLog("if let device = object as? AVCaptureDevice failed \n deviceWithMediaType()", "")}
            }
            return captureDevice
        }
        else{NSLog("if let captureDevice = devices.first as? AVCaptureDevice \n deviceWithMediaType()", "")}
        return nil
    }
    
    fileprivate func _FSVUpdateFocusValueLabel(_ value: Float) {
        self._FSVFocusValueLabel.text = NSString(format: "%.1f", value) as String
    }
    
    fileprivate func _ESVUpdateDurationValueLabel(_ value: CMTime) {
        let doubleValue = max(CMTimeGetSeconds(value), kExposureMinimumDuration)
        if ( doubleValue < 1 ) {
            let digits = max( 0, 2 + floor( log10( doubleValue ) ) )
            self._ESVDurationValueLabel.text = NSString(format: "1/%.*f", digits, 1/doubleValue) as String
        }
        else {
            self._ESVDurationValueLabel.text = NSString(format: "%.2f", doubleValue) as String
        }
    }
    
    fileprivate func _ESVUpdateISOValueLabel(_ value: Float) {
        self._ESVISOValueLabel.text = "\(Int(value))"
    }
    
    fileprivate func _WBSVUpdateTempValueLabel(_ value: Float) {
        self._WBSVTempValueLabel.text = "\(Int(value))"
    }
    
    fileprivate func _WBSVUpdateTintValueLabel(_ value: Float) {
        self._WBSVTintValueLabel.text = "\(Int(value))"
    }
    
    private func _normalizeGains(_ g:AVCaptureWhiteBalanceGains) -> AVCaptureWhiteBalanceGains{
        var g = g
        //print("\(g)")
        g.redGain = max( 1.0, g.redGain )
        g.greenGain = max( 1.0, g.greenGain )
        g.blueGain = max( 1.0, g.blueGain )
        
        g.redGain = min( self.device.maxWhiteBalanceGain, g.redGain )
        g.greenGain = min( self.device.maxWhiteBalanceGain, g.greenGain )
        g.blueGain = min( self.device.maxWhiteBalanceGain, g.blueGain )
        return g
    }
    
    fileprivate func _setMaxAndMinTint(){
        let cGains = device.deviceWhiteBalanceGains
        let maxGain = device.maxWhiteBalanceGain
        
        // set max tint
        
        //estimateGains
        var eMaxGains = _normalizeGains(cGains)
        //estimateTempAndTint
        var eMaxTempAndTint: AVCaptureWhiteBalanceTemperatureAndTintValues {
            get {
                return _tempAndTintForGains(eMaxGains)
            }
            set {
                eMaxGains = _gainsForTempAandTint(newValue)
            }
        }
        
        let incTint = {(displacement:Float, handleIncramentOutOfRange:() -> Void) -> Void in
            var newTempAndTint = eMaxTempAndTint
            newTempAndTint.tint += displacement
            let tintInRange = (self._WBSVTintDefaultMin <= newTempAndTint.tint && newTempAndTint.tint <= self._WBSVTintDefaultMax)
            if self._gainsInRange(self._gainsForTempAandTint(newTempAndTint)) && tintInRange {
                eMaxTempAndTint = newTempAndTint
                print("incTint:\(newTempAndTint.tint)")
            }else{
                handleIncramentOutOfRange()
            }
        }
        var continueMaxLoop = true
        while continueMaxLoop {
            incTint(40){incTint(10){incTint(2){incTint(0.6){incTint(0.1){
                continueMaxLoop = false
                //self._WBSVTintSlider.maximumValue = eMaxTempAndTint.tint
                print("setMaxTint:\(eMaxTempAndTint.tint)")
            }}}}}
        }
        // set min tint
        
        //estimateGains
        var eMinGains = _normalizeGains(cGains)
        //estimateTempAndTint
        var eMinTempAndTint: AVCaptureWhiteBalanceTemperatureAndTintValues {
            get {
                return _tempAndTintForGains(eMinGains)
            }
            set {
                eMinGains = _gainsForTempAandTint(newValue)
            }
        }
        
        let decTint = {(displacement:Float, handleIncramentOutOfRange:() -> Void) -> Void in
            var newTempAndTint = eMinTempAndTint
            newTempAndTint.tint -= displacement
            let tintInRange = (self._WBSVTintDefaultMin <= newTempAndTint.tint && newTempAndTint.tint <= self._WBSVTintDefaultMax)
            if self._gainsInRange(self._gainsForTempAandTint(newTempAndTint)) && tintInRange {
                eMinTempAndTint = newTempAndTint
                print("decTint:\(newTempAndTint.tint)")
            }else{
                handleIncramentOutOfRange()
            }
        }
        var continueMinLoop = true
        while continueMinLoop {
            decTint(40){decTint(10){decTint(2){decTint(0.6){decTint(0.1){
                continueMinLoop = false
                //self._WBSVTintSlider.minimumValue = eMinTempAndTint.tint
                print("setMin:\(eMinTempAndTint.tint)")
                }}}}}
        }
    }
    
    fileprivate func _gainsInRange(_ gains:AVCaptureWhiteBalanceGains) -> Bool {
        let maxGain = device.maxWhiteBalanceGain
        let redIsFine = (1.0 <= gains.redGain && gains.redGain <= maxGain)
        let greenIsFine = (1.0 <= gains.greenGain && gains.greenGain <= maxGain)
        let blueIsFine = (1.0 <= gains.blueGain && gains.blueGain <= maxGain)
        return redIsFine && greenIsFine && blueIsFine
    }
    
    fileprivate func _tempAndTintForGains(_ gains:AVCaptureWhiteBalanceGains) -> AVCaptureWhiteBalanceTemperatureAndTintValues {
        return device.temperatureAndTintValues(forDeviceWhiteBalanceGains: gains)
    }
    
    fileprivate func _gainsForTempAandTint(_ tempAndTint:AVCaptureWhiteBalanceTemperatureAndTintValues) -> AVCaptureWhiteBalanceGains {
        return device.deviceWhiteBalanceGains(for: tempAndTint)
    }
    
    fileprivate func _CMTimeFromValue(_ value: Float) -> CMTime {
        let p = pow( Double(value), kExposureDurationPower ); // Apply power function to expand slider's low-end range
        let minDurationSeconds = max( CMTimeGetSeconds( self.device.activeFormat.minExposureDuration ), kExposureMinimumDuration );
        let maxDurationSeconds = CMTimeGetSeconds( self.device.activeFormat.maxExposureDuration );
        let newDurationSeconds = p * ( maxDurationSeconds - minDurationSeconds ) + minDurationSeconds; // Scale from 0-1 slider range to actual duration
        //print("to Time:\(CMTimeMakeWithSeconds( newDurationSeconds, 1000*1000*1000 ))")
        return CMTimeMakeWithSeconds( newDurationSeconds, 1000*1000*1000 )
    }
    
    fileprivate func _valueFromCMTime(_ time: CMTime) -> Float {
        let doubleValue: Double = CMTimeGetSeconds(time)
        let minDurationSeconds: Double = max( CMTimeGetSeconds( self.device.activeFormat.minExposureDuration ), kExposureMinimumDuration );
        let maxDurationSeconds: Double = CMTimeGetSeconds( self.device.activeFormat.maxExposureDuration )
        let p: Double = (doubleValue - minDurationSeconds ) / ( maxDurationSeconds - minDurationSeconds )// Scale to 0-1
        //print("to val:\(Float(pow( p, 1/kExposureDurationPower)))")
        return Float(pow( p, 1/kExposureDurationPower))
    }
    
    // avfocusmode for focusmode
    fileprivate func _AVFocusModeForFocusMode(_ focusMode:CaptureFocusMode) -> AVCaptureFocusMode{
        guard let focusMode = _deviceSupportedFocusModes[focusMode]! else{print("supportedMode \(_deviceSupportedFocusModes)");return device.focusMode}
        return focusMode
    }

    fileprivate func _AVExposureModeForExposureMode(_ exposureMode:CaptureExposureMode) -> AVCaptureExposureMode{
        guard let supportedMode = _deviceSupportedExposureModes[exposureMode]! else{print("supportedMode \(_deviceSupportedExposureModes)");return device.exposureMode}
        return supportedMode
    }

    fileprivate func _AVWhiteBalanceModeForWhiteBalanceMode(_ whiteBalanceMode:CaptureWhiteBalanceMode) -> AVCaptureWhiteBalanceMode{
        guard let supportedMode = _deviceSupportedWhiteBalanceModes[whiteBalanceMode]! else{print("supportedMode \(_deviceSupportedWhiteBalanceModes)");return device.whiteBalanceMode}
        return supportedMode
    }
}

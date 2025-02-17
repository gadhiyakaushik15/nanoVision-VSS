//
//  CameraViewController.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 08/04/24.
//

import UIKit
import AVFoundation
import ParavisionFL
import ParavisionFR
import Photos
import PhotosUI
import SideMenu

enum CameraControllerError: Error {
    case cameraAccessDenied
    case cameraConfigError
    case invalidInput
    case invalidOutput
    case sessionError
    case unknown
}

class CameraViewController: UIViewController {
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var cameraPermissionView: UIView!
    @IBOutlet weak var cameraPermissionLabel: UILabel!
    @IBOutlet weak var chooseFileButton: UIButton!
    
    private var previewView: CameraPreviewView!
    private var captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var sessionQueue = DispatchQueue(label: "session")
    private var bufferQueue = DispatchQueue(label: "buffer")
    private var videoPosition: AVCaptureDevice.Position = .front
    private var torchMode: AVCaptureDevice.TorchMode = .off
    private var isProcessing = true
    private var isScanning = false
    private var paravisionServices: ParavisionServices?
    private var stopSessionObserver: NSObjectProtocol?
    private var backgroundObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.scanButton.isHidden = !UserDefaultsServices.shared.isManualScanMode()
        self.setLogo()
        LocalDataService.shared.syncCompleted = {
            self.setLogo()
            if Utilities.shared.isMQTTEnabled() {
                MQTTManager.shared().checkRelayChange()
            }
        }
#if targetEnvironment(simulator)
        self.paravisionServices = ParavisionServices.shared
        self.mainView.isHidden = true
        self.chooseFileButton.isHidden = false
#else
        self.mainView.isHidden = false
        self.chooseFileButton.isHidden = true
        self.prepare { status in
            if status {
                self.cameraPermissionView.isHidden = true
                if !self.captureSession.isRunning {
                    self.startSession()
                }
            } else {
                self.cameraPermissionView.isHidden = false
            }
        }
#endif
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.isProcessing = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.isProcessing = false
    }
    
    // MARK: Config UI
    func configUI() {
#if targetEnvironment(simulator)
    
#else
        self.cameraPermissionLabel.text = Message.CameraPermissionMessage
        self.stopSessionObserver = NotificationCenter.default.addObserver(forName: .stopSession, object: nil, queue: .main) { [unowned self] notification in
            self.stopSession()
        }
        self.backgroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [unowned self] notification in
            self.stopSession()
        }
#endif
        
        if Utilities.shared.isMQTTEnabled() {
            MQTTManager.shared().initializeMQTT()
        }
    }
    
    deinit {
        if let stopSessionObserver = self.stopSessionObserver {
            NotificationCenter.default.removeObserver(stopSessionObserver)
        }
        if let backgroundObserver = self.backgroundObserver {
            NotificationCenter.default.removeObserver(backgroundObserver)
        }
    }
 
    // MARK: - Camera Configuration
    func configPreviewLayer() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1)  {
            self.previewView = CameraPreviewView(frame: self.cameraView.bounds)
            self.cameraView.addSubview(self.previewView)
            self.previewView.previewLayer.session = self.captureSession
            self.previewView.previewLayer.videoGravity = .resizeAspectFill
        }
    }
    
    // MARK: Set Logo
    func setLogo() {
        self.logoImageView.image = Utilities.shared.getAppLogo()
    }
    
    func startSession() {
        self.sessionQueue.async {
            do {
                self.paravisionServices = ParavisionServices.shared
                self.captureSession.sessionPreset = .high
                self.captureSession.beginConfiguration()
                if self.previewView == nil {
                    self.configPreviewLayer()
                }
                try self.configCameraInput()
                try self.configCameraOutput()
                self.captureSession.commitConfiguration()
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }
    
    func stopSession() {
        if self.captureSession.isRunning {
            self.sessionQueue.async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    private func prepare(_ completionHandler: @escaping (Bool) -> Void) {
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            completionHandler(true)
        } else if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    completionHandler(true)
                } else {
                    completionHandler(false)
                }
            }
        } else {
            completionHandler(false)
        }
    }
    
    private func configCameraInput() throws {
        guard let camera = self.getCamera() else {
            throw CameraControllerError.cameraConfigError
        }
        if let currentInput = captureSession.inputs.first {
            captureSession.removeInput(currentInput)
        }
        let input = try AVCaptureDeviceInput(device: camera)
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        } else {
            throw CameraControllerError.invalidInput
        }
    }
    
    private func getCamera() -> AVCaptureDevice? {
        let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: videoPosition)
        return camera
    }
    
    private func configCameraOutput() throws {
        videoOutput.setSampleBufferDelegate(self, queue: bufferQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): kCMPixelFormat_32BGRA]
        captureSession.removeOutput(videoOutput)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            throw CameraControllerError.invalidOutput
        }
        guard let connection = videoOutput.connection(with: .video) else {
            fatalError()
        }
        connection.videoOrientation = .portrait
        if videoPosition == .front {
            connection.isVideoMirrored = true
        }
    }
    
    // MARK: - Button Action
    @IBAction func menuAction(_ sender: Any) {
        if let leftSideMenu = self.getViewController(storyboard: Storyboard.sideMenu, id: "LeftMenuNavigationController") as? SideMenuNavigationController {
            Utilities.shared.sideMenuSettings(leftSideMenu: leftSideMenu)
            self.present(leftSideMenu, animated: true)
        }
    }
    
    @IBAction func flashChangeAction(_ sender: UIButton)  {
        if let device = AVCaptureDevice.default(for: .video) {
            if (device.hasTorch) {
                do {
                    try device.lockForConfiguration()
                    if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                        device.torchMode = AVCaptureDevice.TorchMode.off
                        sender.setImage(UIImage(named: "flashOn"), for: .normal)
                    } else {
                        try device.setTorchModeOn(level: 1)
                        sender.setImage(UIImage(named: "flashOff"), for: .normal)
                    }
                    device.unlockForConfiguration()
                } catch {
                    debugPrint(error)
                }
            }
        }
    }
    
    @IBAction func cameraChangeAction(_ sender: Any)  {
        if self.videoPosition == .front {
            self.videoPosition = .back
            if let device = AVCaptureDevice.default(for: .video), device.hasTorch {
                self.flashButton.isEnabled = true
            }
        } else {
            self.videoPosition = .front
            self.flashButton.isEnabled = false
            self.flashButton.setImage(UIImage(named: "flashOn"), for: .normal)
        }
        self.stopSession()
        self.startSession()
    }
    
    @IBAction func scanFaceAction(_ sender: Any) {
        if self.isProcessing == false && self.isScanning == false {
            self.isScanning = true
        }
    }
    
    @IBAction func goToSettings(_ sender: Any) {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                debugPrint("Settings opened: \(success)")
            })
        }
    }
    
    @IBAction func choosePhotoAction(_ sender: Any) {
        PHPhotoLibrary.requestAuthorization({
            (newStatus) in
            DispatchQueue.main.async {
                //debugPrint("status is \(newStatus)")
                if newStatus ==  PHAuthorizationStatus.authorized {
                    self.openPHPicker()
                }
            }
        })
    }
    
    // MARK: - Open image picker
    func openPHPicker() {
        var phPickerConfig = PHPickerConfiguration(photoLibrary: .shared())
        phPickerConfig.selectionLimit = 1
        phPickerConfig.filter = PHPickerFilter.any(of: [.images])
        let phPickerVC = PHPickerViewController(configuration: phPickerConfig)
        phPickerVC.delegate = self
        present(phPickerVC, animated: true)
    }
    
    //MARK: - Paravision Service
    private func checkValidness(image: UIImage) {
        if let paravisionServices = self.paravisionServices, let validness = paravisionServices.validness(image: image) {
            if validness.isValid && !self.isProcessing {
                self.isProcessing = true
                self.checkLiveness(image: image, validness: validness)
            } else {
                debugPrint(String(describing: validness))
            }
        }
    }
    
    private func checkLiveness(image: UIImage, validness: PNLivenessValidness?) {
        if UserDefaultsServices.shared.isLiveness() {
            if let paravisionServices = self.paravisionServices, let liveness = paravisionServices.liveness(image: image) {
                self.identifyFace(image: image, validness: validness, liveness: liveness)
            } else {
                self.isProcessing = false
            }
        } else {
            self.identifyFace(image: image, validness: validness, liveness: nil)
        }
    }
    
    private func identifyFace(image: UIImage, validness: PNLivenessValidness?, liveness: PNLiveness?) {
        if let paravisionServices = self.paravisionServices, let data = paravisionServices.identify(image: image) {
            if let liveness = liveness {
                if liveness.livenessProbability >= Constants.LivenessThreshold {
                    self.presentResultView(type: .faceRecognition, image: image, peoples: data, validness: validness, liveness: liveness, qrCode: nil)
                } else {
                    self.presentResultView(type: .faceLiveness, image: image, peoples: data, validness: validness, liveness: liveness, qrCode: nil)
                }
            } else {
                self.presentResultView(type: .faceRecognition, image: image, peoples: data, validness: validness, liveness: liveness, qrCode: nil)
            }
        } else {
            self.isProcessing = false
        }
    }
    
    //MARK: - Present Result Controller
    private func presentResultView(type: ParavisionType, image: UIImage, peoples: [Peoples]?, validness: PNLivenessValidness?, liveness: PNLiveness?, qrCode: String?) {
        var logMatchScore = 0
        var message = ""
        var logPeopleId = 0
        var logPeopleName = ""
        var apiResponse = ""
        var listId = ""
        var logEventId: Int?
        var logEventName = ""
        var logDeviceId: Int?
        var scanType: ScanType = .success
        var logUserType = ""
        var logUniqueId = ""
        var backgroundColor: UIColor = .clear
        var textAlignment: NSTextAlignment = .natural
        var text = ""
        var imageBase64: Data?
        
        if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails {
            if let eventIdDetails = devicesDetails.eventidDetails, let eventIdDetail = eventIdDetails.first {
                if let eventId = eventIdDetail.eventid {
                    logEventId = eventId
                }
                if let eventname = eventIdDetail.eventname {
                    logEventName = eventname
                }
            }
            if let devices = devicesDetails.device, let device = devices.first, let deviceId = device.deviceid {
                logDeviceId = deviceId
            }
        }
        
        if let validness = validness {
            apiResponse = String(describing: validness)
            if let liveness = liveness {
                apiResponse = apiResponse + " " + String(describing: liveness)
            }
        } else {
            if let liveness = liveness {
                apiResponse = String(describing: liveness)
            }
        }
        debugPrint("apiResponse = \(apiResponse)")
        
        if type == .faceValidness {
            scanType = .livenessFailed
            backgroundColor = .warningScanColor ?? .clear
            message = "Liveness check failed"
            var validnessfeedback = ""
            if let validness = validness, let feedbacks = validness.feedbacks.first {
                switch feedbacks {
                case .FACE_ACCEPTABILITY_POOR:
                    validnessfeedback = "Face acceptability poor"
                    break
                case .UNKNOWN:
                    validnessfeedback = "Face acceptability poor"
                    break
                case .FACE_QUALITY_POOR:
                    validnessfeedback = "Face quality poor"
                    break
                case .IMG_LIGHTING_DARK:
                    validnessfeedback = "Image lighting dark"
                    break
                case .IMG_LIGHTING_BRIGHT:
                    validnessfeedback = "Image lighting bright"
                    break
                case .FACE_SIZE_SMALL:
                    validnessfeedback = "Face size small"
                    break
                case .FACE_SIZE_LARGE:
                    validnessfeedback = "Face size large"
                    break
                case .FACE_POS_LEFT:
                    validnessfeedback = "Face position left"
                    break
                case .FACE_POS_RIGHT:
                    validnessfeedback = "Face position right"
                    break
                case .FACE_POS_HIGH:
                    validnessfeedback = "Face position high"
                    break
                case .FACE_POS_LOW:
                    validnessfeedback = "Face position low"
                    break
                case .FACE_MASK_FOUND:
                    validnessfeedback = "Face mask found"
                    break
                case .FACE_FRONTALITY_POOR:
                    validnessfeedback = "Face acceptability poor"
                    break
                case .FACE_SHARPNESS_POOR:
                    validnessfeedback = "Face sharpness poor"
                    break
                @unknown default:
                    validnessfeedback = "Face acceptability poor"
                    break
                }
            }
            textAlignment = .center
            text = "\(message)\n\n\(validnessfeedback)"
        } else if type == .faceLiveness {
            if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails, let eventIdDetails = devicesDetails.eventidDetails, let eventIdDetail = eventIdDetails.first, let eventId = eventIdDetail.eventid, let data = peoples, data.count > 0 {
                if let matched = data.max(by: { first, second in
                    if eventId == second.eventID {
                        return true
                    } else if eventId == first.eventID {
                        return false
                    } else {
                        if (first.matchScore ?? 0) < (second.matchScore ?? 0) {
                            return true
                        } else {
                            return false
                        }
                    }
                }) {
                    if let matchScore = matched.matchScore {
                        logMatchScore = matchScore
                    }
                    logPeopleId = Int(matched.peopleid)
                    if let uniqueId = matched.uniqueId {
                        logUniqueId = uniqueId
                    }
                    logPeopleName = "\(matched.firstname ?? "") \(matched.lastname ?? "")"
                    logUserType = matched.usertype ?? ""
                    if let listIdArray = matched.listid {
                        listId = listIdArray.joined(separator: ",")
                    }
                }
            }
            scanType = .livenessFailed
            backgroundColor = .warningScanColor ?? .clear
            message = "Liveness check failed"
            textAlignment = .center
            text = "\(message)\n\nReason: Oops! It seems the image is either blurred or not an actual person. Ensure a clear and well-lit view of your face, and try again."
        } else {
            if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails, let eventIdDetails = devicesDetails.eventidDetails, let eventIdDetail = eventIdDetails.first, let kioskDetails = devicesDetails.kioskDetails, let kioskDetail = kioskDetails.first {
                
                var isFutureEvent = false
                var isExpiredEvent = false
                
                if let enableFutureEventScan = kioskDetail.enablefutureeventscan, enableFutureEventScan == false {
                    if let eventStartDateTime = eventIdDetail.eventstartdatetime, let eventStartDate = Utilities.shared.convertStringToNSDateFormat(date: eventStartDateTime, currentFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ"), Date().toLocalTime() < eventStartDate {
                        isFutureEvent = true
                    } else if let enableExpiredEventScan = kioskDetail.enableexpiredeventscan, enableExpiredEventScan == false {
                        if let eventEndDateTime = eventIdDetail.eventenddatetime, let eventEndDate = Utilities.shared.convertStringToNSDateFormat(date: eventEndDateTime, currentFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ"),  Date().toLocalTime() > eventEndDate{
                            isExpiredEvent = true
                        }
                    }
                } else if let enableExpiredEventScan = kioskDetail.enableexpiredeventscan, enableExpiredEventScan == false {
                    if let eventEndDateTime = eventIdDetail.eventenddatetime, let eventEndDate = Utilities.shared.convertStringToNSDateFormat(date: eventEndDateTime, currentFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ"),  Date().toLocalTime() > eventEndDate{
                        isExpiredEvent = true
                    }
                }
                
                if isFutureEvent {
                    scanType = .futureEvent
                    backgroundColor = .warningScanColor ?? .clear
                    if let futureEventScanMsg = kioskDetail.futureeventscanmsg, futureEventScanMsg != "" {
                        message = futureEventScanMsg
                    } else {
                        message = Message.FutureEventMessage
                    }
                    textAlignment = .center
                  text = message
                    if let eventId = eventIdDetail.eventid, let data = peoples, data.count > 0 {
                        if let matched = data.max(by: { first, second in
                            if eventId == second.eventID {
                                return true
                            } else if eventId == first.eventID {
                                return false
                            } else {
                                if (first.matchScore ?? 0) < (second.matchScore ?? 0) {
                                    return true
                                } else {
                                    return false
                                }
                            }
                        }) {
                            if let matchScore = matched.matchScore {
                                logMatchScore = matchScore
                            }
                            logPeopleId = Int(matched.peopleid)
                            if let uniqueId = matched.uniqueId {
                                logUniqueId = uniqueId
                            }
                            logPeopleName = "\(matched.firstname ?? "") \(matched.lastname ?? "")"
                            logUserType = matched.usertype ?? ""
                            if let listIdArray = matched.listid {
                                listId = listIdArray.joined(separator: ",")
                            }
                        }
                    }
                } else if isExpiredEvent {
                    scanType = .expiredEvent
                    backgroundColor = .warningScanColor ?? .clear
                    if let expiredEventScanMsg = kioskDetail.expiredeventscanmsg, expiredEventScanMsg != "" {
                        message = expiredEventScanMsg
                    } else {
                        message = Message.ExpiredEventMessage
                    }
                    textAlignment = .center
                    text = message
                    if let eventId = eventIdDetail.eventid, let data = peoples, data.count > 0 {
                        if let matched = data.max(by: { first, second in
                            if eventId == second.eventID {
                                return true
                            } else if eventId == first.eventID {
                                return false
                            } else {
                                if (first.matchScore ?? 0) < (second.matchScore ?? 0) {
                                    return true
                                } else {
                                    return false
                                }
                            }
                        }) {
                            if let matchScore = matched.matchScore {
                                logMatchScore = matchScore
                            }
                            logPeopleId = Int(matched.peopleid)
                            if let uniqueId = matched.uniqueId {
                                logUniqueId = uniqueId
                            }
                            logPeopleName = "\(matched.firstname ?? "") \(matched.lastname ?? "")"
                            logUserType = matched.usertype ?? ""
                            if let listIdArray = matched.listid {
                                listId = listIdArray.joined(separator: ",")
                            }
                        }
                    }
                } else {
                    if let eventId = eventIdDetail.eventid, let data = peoples, data.count > 0 {
                        if let matched = data.max(by: { first, second in
                            if eventId == second.eventID {
                                return true
                            } else if eventId == first.eventID {
                                return false
                            } else {
                                if (first.matchScore ?? 0) < (second.matchScore ?? 0) {
                                    return true
                                } else {
                                    return false
                                }
                            }
                        }) {
                            if eventId == matched.eventID && matched.isactive {
                                if Utilities.shared.isMQTTEnabled() {
                                    MQTTManager.shared().publish(topic: MQTT.PublisherTopic, message: MQTT.OnCommand)
                                }
                                scanType = .success
                                backgroundColor = .successScanColor ?? .clear
                                if let peopleSpecificMsg = kioskDetail.peoplespecificmsg, let welComeMsg = matched.welcomemsg, peopleSpecificMsg, welComeMsg != "" {
                                    message = welComeMsg
                                } else if let scanSuccess = kioskDetail.scansuccess, scanSuccess != "" {
                                    message = "\(Message.Welcome) \(matched.firstname ?? "") \(matched.lastname ?? "")\n\n\(scanSuccess)"
                                } else {
                                    message = Message.AuthorisedPerson
                                }
                                textAlignment = .center
                                text = message
                            } else {
                                scanType = .unauthorized
                                backgroundColor = .failedScanColor ?? .clear
                                if let scanFailure = kioskDetail.scanfailure, scanFailure != "" {
                                    message = scanFailure
                                } else {
                                    message = Message.UnauthorisedPerson
                                }
                               textAlignment = .center
                                text = message
                            }
                            if let matchScore = matched.matchScore {
                                logMatchScore = matchScore
                            }
                            logPeopleId = Int(matched.peopleid)
                            if let uniqueId = matched.uniqueId {
                                logUniqueId = uniqueId
                            }
                            logPeopleName = "\(matched.firstname ?? "") \(matched.lastname ?? "")"
                            logUserType = matched.usertype ?? ""
                            if let listIdArray = matched.listid {
                                listId = listIdArray.joined(separator: ",")
                            }
                        } else {
                            scanType = .unauthorized
                            backgroundColor = .failedScanColor ?? .clear
                            if let scanFailure = kioskDetail.scanfailure, scanFailure != "" {
                                message = scanFailure
                            } else {
                                message = Message.UnauthorisedPerson
                            }
                            textAlignment = .center
                            text = message
                        }
                    } else {
                        scanType = .unauthorized
                        backgroundColor = .failedScanColor ?? .clear
                        if let scanFailure = kioskDetail.scanfailure, scanFailure != "" {
                            message = scanFailure
                        } else {
                            message = Message.UnauthorisedPerson
                        }
                        textAlignment = .center
                        text = message
                    }
                }
            } else {
                scanType = .unauthorized
                backgroundColor = .failedScanColor ?? .clear
                message = Message.UnauthorisedPerson
                textAlignment = .center
                text = message
            }
        }
        
        if let compressData = image.jpegData(compressionQuality: 0.01) {
            imageBase64 = compressData
        }
        
        DispatchQueue.main.async {
            if let controller = self.getViewController(storyboard: Storyboard.result, id: "ResultViewController") as? ResultViewController, self.presentedViewController == nil  {
                controller.backgroundColor = backgroundColor
                controller.textAlignment = textAlignment
                controller.text = text
                controller.scanType = scanType
                controller.logUniqueId = logUniqueId
                controller.imageBase64 = imageBase64
                controller.message = message
                controller.logPeopleId = logPeopleId
                controller.logPeopleName = logPeopleName
                controller.logMatchScore = logMatchScore
                controller.apiResponse = apiResponse
                controller.listId = listId
                controller.logEventId = logEventId
                controller.logEventName = logEventName
                controller.logDeviceId = logDeviceId
                controller.logUserType = logUserType
                self.present(controller, animated: true)
            }
        }
    }
}

//MARK: - Preview view type
extension CameraViewController {
    private class CameraPreviewView: UIView {
        var previewLayer: AVCaptureVideoPreviewLayer {
            guard let layer = layer as? AVCaptureVideoPreviewLayer else {
                fatalError("AVCaptureVideoPreviewLayer is expected")
            }
            return layer
        }

        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
    }
}

//MARK: - Session delegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
        
    func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !self.isProcessing && (self.isScanning || !UserDefaultsServices.shared.isManualScanMode()) {
            if self.isScanning {
                self.isScanning = false
            }
            if let image = UIImage(buffer: sampleBuffer), let compressData = image.jpegData(compressionQuality: 0.01), let pickedImage = UIImage(data: compressData) {
                var qrCode = ""
                if let detector: CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh]), let ciImage: CIImage = CIImage(image: pickedImage), let features = detector.features(in: ciImage) as? [CIQRCodeFeature] {
                    features.forEach { feature in
                        if let messageString = feature.messageString {
                            qrCode += messageString
                        }
                    }
                }
                if qrCode != "" {
                    self.isProcessing = true
                    let peoples = OfflinePeoples.shared.peoples.filter{ ($0.qrcode ?? "") == qrCode }
                    self.presentResultView(type: .qrCode, image: pickedImage, peoples: peoples, validness: nil, liveness: nil, qrCode: qrCode)
                } else {
                    if !UserDefaultsServices.shared.isValidness() {
                        self.checkValidness(image: pickedImage)
                    } else {
                        self.isProcessing = true
                        self.checkLiveness(image: pickedImage, validness: nil)
                    }
                }
            }
        }
    }
}

// MARK: - Picker delegate
extension CameraViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true, completion: nil)
        if !self.isProcessing && (self.isScanning || !UserDefaultsServices.shared.isManualScanMode()) {
            if self.isScanning {
                self.isScanning = false
            }
            guard let firstResult = results.first else { return }
            if firstResult.itemProvider.canLoadObject(ofClass: UIImage.self) {
                firstResult.itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
                    if let image = reading as? UIImage, let compressData = image.jpegData(compressionQuality: 0.1), let pickedImage = UIImage(data: compressData) {
                        var qrCode = ""
                        if let detector: CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh]), let ciImage: CIImage = CIImage(image: pickedImage), let features = detector.features(in: ciImage) as? [CIQRCodeFeature] {
                            features.forEach { feature in
                                if let messageString = feature.messageString {
                                    qrCode += messageString
                                }
                            }
                        }
                        if qrCode != "" {
                            self.isProcessing = true
                            let peoples = OfflinePeoples.shared.peoples.filter{ ($0.qrcode ?? "") == qrCode }
                            self.presentResultView(type: .qrCode, image: pickedImage, peoples: peoples, validness: nil, liveness: nil, qrCode: qrCode)
                        } else {
                            if !UserDefaultsServices.shared.isValidness() {
                                self.checkValidness(image: pickedImage)
                            } else {
                                self.isProcessing = true
                                self.checkLiveness(image: pickedImage, validness: nil)
                            }
                        }
                    }
                }
            }
        }
    }
}

extension CameraViewController: SideMenuNavigationControllerDelegate {
    func sideMenuWillAppear(menu: SideMenuNavigationController, animated: Bool) {
        self.isProcessing = true
    }
    
    func sideMenuDidDisappear(menu: SideMenuNavigationController, animated: Bool) {
        self.isProcessing = false
        if !self.captureSession.isRunning {
            self.startSession()
        }
    }
}

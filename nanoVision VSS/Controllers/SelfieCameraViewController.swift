//
//  SelfieCameraViewController.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 30/05/24.
//

import UIKit
import AVFoundation
import PhotosUI

class SelfieCameraViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var captureView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var cameraPermissionView: UIView!
    @IBOutlet weak var cameraPermissionLabel: UILabel!
    @IBOutlet weak var chooseFileButton: UIButton!
    
    private var previewView: CameraPreviewView!
    private var captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var sessionQueue = DispatchQueue(label: "session")
    private var bufferQueue = DispatchQueue(label: "buffer")
    private var videoPosition: AVCaptureDevice.Position = .front
    private var paravisionServices: ParavisionServices?
    private var isProcessing = false
    private var isCapturing = false
    private var backgroundObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setLogo()
        LocalDataService.shared.syncCompleted = {
            DispatchQueue.main.async() {
                Utilities.shared.dismissSVProgressHUD()
                self.setLogo()
            }
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
                self.startSession()
            } else {
                self.cameraPermissionView.isHidden = false
            }
        }
#endif
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
#if targetEnvironment(simulator)
#else
        self.stopSession()
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
    
    override func viewDidLayoutSubviews() {
        self.cameraView.cornerRadiusV = 20
        self.captureView.cornerRadiusV = self.captureView.frame.height / 2
        self.captureButton.cornerRadiusV = self.captureButton.frame.height / 2
    }
    
    // MARK: Config UI
    func configUI() {
        NotificationCenter.default.post(name: .stopSession, object: nil)
        Utilities.shared.addSideRadiusWithOpacity(view: self.lineView, radius: 0, shadowRadius: 4, opacity: 1, shadowOffset: CGSize(width: 0 , height: 4), shadowColor: UIColor.black.withAlphaComponent(0.25), corners: [])
        
        if Utilities.shared.isPadDevice() {
            let backConfig = UIImage.SymbolConfiguration(
                pointSize: 26, weight: .heavy, scale: .large)
            let backImage = UIImage(systemName: "arrow.backward", withConfiguration: backConfig)
            self.backButton.setImage(backImage, for: .normal)
        } else {
            let backConfig = UIImage.SymbolConfiguration(
                pointSize: 18, weight: .heavy, scale: .medium)
            let backImage = UIImage(systemName: "arrow.backward", withConfiguration: backConfig)
            self.backButton.setImage(backImage, for: .normal)
        }
        
#if targetEnvironment(simulator)
        
#else
        self.cameraPermissionLabel.text = Message.CameraPermissionMessage
        self.backgroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [unowned self] notification in
            self.stopSession()
        }
#endif
    }
    
    deinit {
        if let backgroundObserver = self.backgroundObserver {
            NotificationCenter.default.removeObserver(backgroundObserver)
        }
    }
    
    // MARK: Set Logo
    func setLogo() {
        self.logoImageView.image = Utilities.shared.getAppLogo()
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
    
    func startSession() {
        if !self.captureSession.isRunning {
            self.sessionQueue.async {
                do {
                    self.paravisionServices = ParavisionServices.shared
                    self.captureSession.sessionPreset = .photo
                    self.captureSession.beginConfiguration()
                    if self.previewView == nil {
                        self.cameraView.alpha = 0.0
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
    }
    
    func stopSession() {
        if self.captureSession.isRunning {
            self.sessionQueue.async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    // MARK: - Camera Configuration
    func configPreviewLayer() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1)  {
            self.previewView = CameraPreviewView(frame: self.cameraView.bounds)
            self.cameraView.addSubview(self.previewView)
            self.previewView.previewLayer.session = self.captureSession
            self.previewView.previewLayer.videoGravity = .resizeAspectFill
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.cameraView.alpha = 1.0
                self.setMaskView()
            }
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
    
    func setMaskView() {
        let sampleMask = UIView(frame: CGRect(x: 0.0, y: 0.0, width: self.cameraView.frame.width, height: self.cameraView.frame.height))
        sampleMask.backgroundColor =  UIColor.black.withAlphaComponent(0.8)
        
        let maskLayer = CALayer()
        maskLayer.frame = sampleMask.frame
        let circleLayer = CAShapeLayer()
        circleLayer.frame = CGRect(x: sampleMask.frame.origin.x, y: sampleMask.frame.origin.y, width: sampleMask.frame.width, height: sampleMask.frame.height)
        let finalPath = UIBezierPath(roundedRect: CGRect(x: sampleMask.frame.origin.x, y: sampleMask.frame.origin.y, width: sampleMask.frame.width, height: sampleMask.frame.height), cornerRadius: 0)
        var circlePath = UIBezierPath(ovalIn: CGRect(x: 20, y: 40, width: sampleMask.frame.width - 40, height: sampleMask.frame.height - 80))
        if Utilities.shared.isPadDevice() {
            circlePath = UIBezierPath(ovalIn: CGRect(x: 60, y: 30, width: sampleMask.frame.width - 120, height: sampleMask.frame.height - 60))
        }
        finalPath.append(circlePath.reversing())
        circleLayer.path = finalPath.cgPath
        maskLayer.addSublayer(circleLayer)
        sampleMask.layer.mask = maskLayer
        
        self.cameraView.addSubview(sampleMask)
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
    
    func navigateVisitorPass(image: UIImage, embeddings: String, visitor: VisitorResult?) {
        if let controller = self.getViewController(storyboard: Storyboard.visitorDetails, id: "VisitorDetailsViewController") as? VisitorDetailsViewController {
            controller.selfieImage = image
            controller.embeddings = embeddings
            controller.visitor = visitor
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    //MARK: - Paravision Service
    private func checkValidness(image: UIImage) {
        if let paravisionServices = self.paravisionServices, let validness = paravisionServices.validness(image: image) {
            if validness.isValid {
                self.createEmbeddings(image: image)
            } else {
                debugPrint(String(describing: validness))
                self.isProcessing = false
            }
        } else {
            self.isProcessing = false
        }
    }
    
    private func createEmbeddings(image: UIImage) {
        DispatchQueue.main.async {
            if let paravisionServices = self.paravisionServices {
                let data = paravisionServices.createEmbeddings(image: image)
                if let embeddings = data.0 {
                    if let peoples = data.1, let people = peoples.first {
                        var phoneNumber: String?
                        if let phone = people.phone {
                            phoneNumber = String(phone)
                        }
                        if let userType = people.usertype, userType.lowercased() == UserType.Visitor {
                            let visitor = VisitorResult(firstname: people.firstname, lastname: people.lastname, email: people.email, phone: phoneNumber, visitorID: 0, visitorImage: people.embeddedimage)
                            self.navigateVisitorPass(image: image, embeddings: embeddings, visitor: visitor)
                        } else {
                            self.isProcessing = false
                            self.showAlert(text: Message.RestrictUserForCreatingVisitorPassMessage)
                        }
                    } else {
                        self.navigateVisitorPass(image: image, embeddings: embeddings, visitor: nil)
                    }
                } else {
                    self.isProcessing = false
                }
            } else {
                self.isProcessing = false
            }
        }
    }
    
    // MARK: - Button Action
    @IBAction func backAction(_ sender: Any) {
        self.dismiss(animated: true)
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
                if newStatus ==  PHAuthorizationStatus.authorized {
                    self.openPHPicker()
                }
            }
        })
        
//        if let image = UIImage(named: "Kaushik_Gadhiya"), let compressData = image.jpegData(compressionQuality: 0.01), let pickedImage = UIImage(data: compressData) {
//            self.isProcessing = true
//            self.checkValidness(image: pickedImage)
//        }
    }
    
    @IBAction func captureAction(_ sender: Any) {
        if APIManager.isConnectedToInternet() {
            if self.isProcessing == false && self.isCapturing == false {
                self.isCapturing = true
            }
        } else {
            self.showAlert(text: Message.PleaseCheckYourInternetConnection)
        }
    }
}

//MARK: - Preview view type
extension SelfieCameraViewController {
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
extension SelfieCameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let image = UIImage(buffer: sampleBuffer), let compressData = image.jpegData(compressionQuality: 0.01), let pickedImage = UIImage(data: compressData), self.isProcessing == false, self.isCapturing == true {
            self.isCapturing = false
            self.isProcessing = true
            self.checkValidness(image: pickedImage)
        }
    }
}

// MARK: - Picker delegate
extension SelfieCameraViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true, completion: nil)
        guard let firstResult = results.first else { return }
        if firstResult.itemProvider.canLoadObject(ofClass: UIImage.self) {
            firstResult.itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
                if let image = reading as? UIImage, let compressData = image.jpegData(compressionQuality: 0.01), let pickedImage = UIImage(data: compressData) {
                    self.isProcessing = true
                    self.checkValidness(image: pickedImage)
                }
            }
        }
    }
}

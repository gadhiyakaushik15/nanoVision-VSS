//
//  ResultViewController.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 08/04/24.
//

import UIKit
import ParavisionFL
import SideMenu

enum ParavisionType {
    case faceRecognition
    case faceValidness
    case faceLiveness
    case qrCode
}

enum ScanType: Int {
    case success = 1
    case livenessFailed = 2
    case futureEvent = 3
    case expiredEvent = 4
    case unauthorized = 5
}

class ResultViewController: UIViewController {
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var backgroundColor: UIColor = .clear
    var textAlignment: NSTextAlignment = .natural
    var text = ""
    var scanType: ScanType?
    var isPresented = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.SetMessageUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setLogo()
        LocalDataService.shared.syncCompleted = {
            self.setLogo()
            if Utilities.shared.isMQTTEnabled() {
                MQTTManager.shared().checkRelayChange()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.isPresented = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.isPresented {
            self.isPresented = false
            self.autoDismiss()
        }
    }
    
    // MARK: Set Logo
    func setLogo() {
        self.logoImageView.image = Utilities.shared.getAppLogo()
    }
    
    func SetMessageUI() {
        if self.scanType == .success {
            self.imageView.isHidden = false
            let imageData = NSData(contentsOf: Bundle.main.url(forResource: "successGIF", withExtension: "gif")!)
            let successGif = UIImage.gif(data: imageData! as Data)
            self.imageView.image = successGif
        } else {
            self.imageView.isHidden = true
        }
        self.statusView.backgroundColor = self.backgroundColor
        self.nameLabel.textAlignment = self.textAlignment
        self.nameLabel.text = self.text
        self.playScanSound()
        self.autoDismiss()
    }
    
    func playScanSound() {
        if UserDefaultsServices.shared.isScanSound() {
            let scanSound: ScanSound?
            switch self.scanType {
            case .success:
                scanSound = ScanSound(name: "successSound", type: "mp3")
            case .livenessFailed, .futureEvent, .expiredEvent, .unauthorized:
                scanSound = ScanSound(name: "failedSound", type: "mp3")
            case .none:
                scanSound = ScanSound(name: "failedSound", type: "mp3")
            }
            if let scanSound = scanSound {
                scanSound.play()
            }
        }
    }
    
    func autoDismiss() {
        if self.scanType == .success {
            if !UserDefaultsServices.shared.isTapScanSuccess() {
                let delay = UserDefaultsServices.shared.getNextScanDelay()
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(Int(delay))) {
                    if self.isPresented == false {
                        self.dismiss(animated: true)
                    }
                }
            }
        } else {
            if !UserDefaultsServices.shared.isTapScanFailure() {
                let delay = UserDefaultsServices.shared.getNextScanDelay()
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(Int(delay))) {
                    if self.isPresented == false {
                        self.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
    @IBAction func menuAction(_ sender: Any) {
        if let leftSideMenu = self.getViewController(storyboard: Storyboard.sideMenu, id: "LeftMenuNavigationController") as? SideMenuNavigationController {
            Utilities.shared.sideMenuSettings(leftSideMenu: leftSideMenu)
            self.present(leftSideMenu, animated: true)
        }
    }
    
    @IBAction func dismissAction(_ sender: Any) {
        if let scanType = self.scanType {
            if scanType == .success {
                if UserDefaultsServices.shared.isTapScanSuccess() {
                    self.dismiss(animated: true)
                }
            } else {
                if UserDefaultsServices.shared.isTapScanFailure() {
                    self.dismiss(animated: true)
                }
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ResultViewController: SideMenuNavigationControllerDelegate {
    func sideMenuWillAppear(menu: SideMenuNavigationController, animated: Bool) {
        self.isPresented = true
    }
    
    func sideMenuDidDisappear(menu: SideMenuNavigationController, animated: Bool) {
        if self.isPresented {
            self.isPresented = false
            self.autoDismiss()
        }
    }
}

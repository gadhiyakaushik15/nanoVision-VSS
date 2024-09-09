//
//  VisitorSuccessViewController.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 11/06/24.
//

import UIKit

class VisitorSuccessViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var startScanningButton: UIButton!

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
    }
    
    // MARK: Config UI
    func configUI() {
        Utilities.shared.addSideRadiusWithOpacity(view: self.lineView, radius: 0, shadowRadius: 4, opacity: 1, shadowOffset: CGSize(width: 0 , height: 4), shadowColor: UIColor.black.withAlphaComponent(0.25), corners: [])
        LocalDataService.shared.starSyncData()
        self.messageLabel.text = Message.VisitorRegistrationSuccessfully
    }
    
    override func viewDidLayoutSubviews() {
        self.startScanningButton.cornerRadiusV = self.startScanningButton.frame.height / 2
    }
    
    // MARK: Set Logo
    func setLogo() {
        self.logoImageView.image = Utilities.shared.getAppLogo()
    }
    
    // MARK: - Button Action
    @IBAction func startScanningAction(_ sender: Any) {
        if let controller = self.getViewController(storyboard: Storyboard.camera, id: "CameraViewController") as? CameraViewController {
            controller.modalTransitionStyle = .crossDissolve
            self.present(controller, animated: true)
        }
    }
}

//
//  SideMenuViewController.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 28/05/24.
//

import UIKit


enum SideMenuData: String, CaseIterable {
//    case visitorPass
    case controlCenter
    
    var title: String {
        switch self {
//        case .visitorPass:
//            return "Visitor's Pass"
        case .controlCenter:
            return "Control Center"
        }
    }
    
    var image: UIImage? {
        switch self {
//        case .visitorPass:
//            return UIImage(named: "visitorPass")
        case .controlCenter:
            return UIImage(named: "controlCenter")
        }
    }
}

class SideMenuViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var orgImageContainerView: UIView!
    @IBOutlet weak var orgImageView: UIImageView!
    @IBOutlet weak var orgNameLabel: UILabel!
    @IBOutlet weak var orgIdLabel: UILabel!
    @IBOutlet weak var macAddressLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    
    let sideMenuData = SideMenuData.allCases
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configUI()
        self.setupTableView()
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
    
    override func viewDidLayoutSubviews() {
        self.orgImageContainerView.cornerRadiusV = self.orgImageContainerView.frame.height / 2
    }
    
    // MARK: Config UI
    func configUI() {
        if Utilities.shared.isPadDevice() {
            self.orgImageContainerView.borderWidthV = 1.0
            self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 0)
        } else {
            self.orgImageContainerView.borderWidthV = 0.65
            self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        }
        self.versionLabel.text = "\(Bundle.main.displayName ?? "") - Version \(Bundle.main.version ?? "")"
    }
    
    func setupTableView() {
        if #available(iOS 15.0, *) {
            self.tableView.sectionHeaderTopPadding = 0.0
        }
        self.tableView.tableHeaderView = self.headerView
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: .leastNormalMagnitude))
        self.tableView.estimatedRowHeight = 200.0
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.register(UINib.init(nibName: "SideMenuTableViewCell", bundle: nil), forCellReuseIdentifier: "SideMenuCell")
        
        if let headerView = self.tableView.tableHeaderView {
            var headerViewFrame = headerView.frame
            if Utilities.shared.isPadDevice() {
                headerViewFrame.size.height = 201
            } else {
                headerViewFrame.size.height = 121
            }
            headerView.frame = headerViewFrame
            self.tableView.tableHeaderView = headerView
        }
    }
    
    // MARK: Set Logo
    func setLogo() {
        self.orgImageView.image = Utilities.shared.getAppLogo()
        if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails {
            
            if let devices = devicesDetails.device, let device = devices.first {
                self.orgNameLabel.text = device.accountname ?? "-"
                self.orgIdLabel.text = "Org Id: \(device.orgID ?? "-")"
                self.macAddressLabel.text = "Device MAC: \(device.devicemac ?? "-")"
            } else {
                self.orgNameLabel.text = "-"
                self.orgIdLabel.text = "Org Id: -"
                self.macAddressLabel.text = "Device MAC: \(KeychainServices.shared.getDeviceMac())"
            }
        }
    }
    
    // MARK: - Button Action
    @IBAction func privacyPolicyAction(_ sender: Any) {
        if let presentingViewController = self.presentingViewController, let controller = self.getViewController(storyboard: Storyboard.webView, id: "WebViewViewController") as? WebViewViewController {
            self.dismiss(animated: true)
            controller.url = URL(string: Constants.PrivacyPolicyUrl)
            controller.strTitle = Message.PrivacyPolicy
            presentingViewController.present(controller, animated: true)
        }
    }
    
    @IBAction func termsOfUseAction(_ sender: Any) {
       if let presentingViewController = self.presentingViewController, let controller = self.getViewController(storyboard: Storyboard.webView, id: "WebViewViewController") as? WebViewViewController {
           self.dismiss(animated: true)
            controller.url = URL(string: Constants.TermsAndConditionsUrl)
            controller.strTitle = Message.TermsOfUse
           presentingViewController.present(controller, animated: true)
        }
    }
}


extension SideMenuViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sideMenuData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SideMenuCell", for: indexPath as IndexPath) as! SideMenuTableViewCell
        
        let data = self.sideMenuData[indexPath.row]
        
        cell.sideMenuImageView.image = data.image
        cell.sideMenuTitleLabel.text = data.title
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.sideMenuData[indexPath.row] {
//        case .visitorPass:
//            if APIManager.isConnectedToInternet() {
//                if let presentingViewController = self.presentingViewController, let controller = self.getViewController(storyboard: Storyboard.selfieCamera, id: "SelfieCameraNavigationController") as? UINavigationController {
//                    self.dismiss(animated: true)
//                    presentingViewController.present(controller, animated: true)
//                }
//            } else {
//                self.showAlert(text: Message.PleaseCheckYourInternetConnection)
//            }
        case .controlCenter:
            if let presentingViewController = self.presentingViewController, let controller = self.getViewController(storyboard: Storyboard.controlCenter, id: "ControlCenterViewController") as? ControlCenterViewController {
                self.dismiss(animated: true)
                controller.isFromCamera = true
                controller.isInit = false
                controller.modalTransitionStyle = .coverVertical
                presentingViewController.present(controller, animated: true)
            }
        }
    }
}

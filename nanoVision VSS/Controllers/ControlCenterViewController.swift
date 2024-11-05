//
//  ControlCenterViewController.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 06/04/24.
//

import UIKit
import BiometricAuthentication

class ControlCenterViewController: UIViewController {

    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var orgImageContainerView: UIView!
    @IBOutlet weak var orgImageView: UIImageView!
    @IBOutlet weak var orgNameLabel: UILabel!
    @IBOutlet weak var orgIdLabel: UILabel!
    @IBOutlet weak var macAddressLabel: UILabel!
    @IBOutlet weak var startScanningButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var securityView: UIView!
    @IBOutlet weak var blurView: UIView!
    @IBOutlet weak var faceIdButton: UIButton!
    
    var isFromCamera = false
    var isInit = false
    
    let headerArray = [Message.ScanSettings, Message.EventDetails, Message.LogsAndStats, Message.DataAndPrivacy]
    var controlCenterArray = [[ControlCenter]]()
    var eventValue = "-"
    var eventExpired = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configUI()
        self.setupTableView()
        if self.isFromCamera == false {
            LocalDataService.shared.syncData()
        }
        self.showTouchAndFaceID()
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
        if self.isInit {
            Utilities.shared.showSVProgressHUD(message: Message.PleaseWaitSyncInProcess)
            LocalDataService.shared.getDeviceStatus()
        }
    }
    
    override func viewDidLayoutSubviews() {
        self.orgImageContainerView.cornerRadiusV = self.orgImageContainerView.frame.height / 2
        self.startScanningButton.cornerRadiusV = self.startScanningButton.frame.height / 2
        self.signOutButton.cornerRadiusV = self.signOutButton.frame.height / 2
        self.faceIdButton.cornerRadiusV = self.faceIdButton.frame.height / 2
    }
    
    // MARK: Config UI
    func configUI() {
        self.blurView.addBlurEffect()
        Utilities.shared.addSideRadiusWithOpacity(view: self.lineView, radius: 0, shadowRadius: 4, opacity: 1, shadowOffset: CGSize(width: 0 , height: 4), shadowColor: UIColor.black.withAlphaComponent(0.25), corners: [])
        if Utilities.shared.isPadDevice() {
            self.orgImageContainerView.borderWidthV = 1.0
            self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 0)
        } else {
            self.orgImageContainerView.borderWidthV = 0.65
            self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        }
    }
    
    func setupTableView() {
        if #available(iOS 15.0, *) {
            self.tableView.sectionHeaderTopPadding = 0.0
        }
        self.tableView.tableHeaderView = self.headerView
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: .leastNormalMagnitude))
        self.tableView.estimatedRowHeight = 200.0
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.register(UINib.init(nibName: "ControlCenterTableViewCell", bundle: nil), forCellReuseIdentifier: "ControlCenterCell")
        self.tableView.register(UINib.init(nibName: "ControlCenterHeaderView", bundle: nil), forCellReuseIdentifier: "ControlCenterHeader")
        
        if let headerView = self.tableView.tableHeaderView {
            var headerViewFrame = headerView.frame
            if Utilities.shared.isPadDevice() {
                headerViewFrame.size.height = 230
            } else {
                headerViewFrame.size.height = 170
            }
            headerView.frame = headerViewFrame
            self.tableView.tableHeaderView = headerView
        }
    }
    
    func dataBind() {
        self.controlCenterArray.removeAll()
        var sectionOne = [ControlCenter]()
        sectionOne.append(ControlCenter(type: .isSwitch, title: Message.ManualScanMode, value: nil, subValue: nil, switchOn: UserDefaultsServices.shared.isManualScanMode(), sliderTitle: nil, sliderValue: nil,sliderMeasureTitle: nil, sliderMaximumValue: nil, sliderMinimumValue: nil, tips: Message.ManualScanModeTips))
        sectionOne.append(ControlCenter(type: .isSwitch, title: Message.LivenessCheck, value: nil, subValue: nil, switchOn: UserDefaultsServices.shared.isLiveness(), sliderTitle: nil, sliderValue: nil,sliderMeasureTitle: nil, sliderMaximumValue: nil, sliderMinimumValue: nil, tips: Message.LivenessCheckTips))
        sectionOne.append(ControlCenter(type: .isSwitch, title: Message.Sound, value: nil, subValue: nil, switchOn: UserDefaultsServices.shared.isScanSound(), sliderTitle: nil, sliderValue: nil,sliderMeasureTitle: nil, sliderMaximumValue: nil, sliderMinimumValue: nil, tips: Message.ScanSoundTips))
        sectionOne.append(ControlCenter(type: .isSwitch, title: Message.TapToScanOnSuccess, value: nil, subValue: nil, switchOn: UserDefaultsServices.shared.isTapScanSuccess(), sliderTitle: nil, sliderValue: nil,sliderMeasureTitle: nil, sliderMaximumValue: nil, sliderMinimumValue: nil, tips: Message.TapToScanOnSuccessTips))
        sectionOne.append(ControlCenter(type: .isSwitch, title: Message.TapToScanOnFailure, value: nil, subValue: nil, switchOn: UserDefaultsServices.shared.isTapScanFailure(), sliderTitle: nil, sliderValue: nil,sliderMeasureTitle: nil, sliderMaximumValue: nil, sliderMinimumValue: nil, tips: Message.TapToScanOnFailureTips))
        sectionOne.append(ControlCenter(type: .isSlider, title: nil, value: nil, subValue: nil, switchOn: true, sliderTitle: Message.NextScanDelay, sliderValue: UserDefaultsServices.shared.getNextScanDelay(), sliderMeasureTitle: (UserDefaultsServices.shared.getNextScanDelay() > 1 ? Message.Seconds : Message.Second), sliderMaximumValue: Constants.NextScanDelayMaximum, sliderMinimumValue: Constants.NextScanDelayMinimum, tips: Message.NextScanDelayTips))

        self.controlCenterArray.append(sectionOne)
        
        var sectionTwo = [ControlCenter]()
        sectionTwo.append(ControlCenter(type: .isValue, title: Message.SelectedEvent, value: self.eventValue, subValue: self.eventExpired, switchOn: nil, sliderTitle: nil, sliderValue: nil,sliderMeasureTitle: nil, sliderMaximumValue: nil, sliderMinimumValue: nil, tips: nil))
        sectionTwo.append(ControlCenter(type: .isNavigation, title: Message.HallEntryExistGateScanning, value: nil, subValue: nibName, switchOn: nil, sliderTitle: nil, sliderValue: nil,sliderMeasureTitle: nil, sliderMaximumValue: nil, sliderMinimumValue: nil, tips: nil))
        self.controlCenterArray.append(sectionTwo)
        
        var sectionThree = [ControlCenter]()
        sectionThree.append(ControlCenter(type: .isNavigation, title: Message.ScanLogs, value: nil, subValue: nibName, switchOn: nil, sliderTitle: nil, sliderValue: nil,sliderMeasureTitle: nil, sliderMaximumValue: nil, sliderMinimumValue: nil, tips: nil))
        sectionThree.append(ControlCenter(type: .isNavigation, title: Message.SyncStats, value: nil, subValue: nil, switchOn: nil, sliderTitle: nil, sliderValue: nil,sliderMeasureTitle: nil, sliderMaximumValue: nil, sliderMinimumValue: nil, tips: nil))
        self.controlCenterArray.append(sectionThree)
        
        var sectionFour = [ControlCenter]()
        sectionFour.append(ControlCenter(type: .isNavigation, title: Message.TermsOfUse, value: nil, subValue: nil, switchOn: nil, sliderTitle: nil, sliderValue: nil,sliderMeasureTitle: nil, sliderMaximumValue: nil, sliderMinimumValue: nil, tips: nil))
        sectionFour.append(ControlCenter(type: .isNavigation, title: Message.PrivacyPolicy, value: nil, subValue: nil, switchOn: nil, sliderTitle: nil, sliderValue: nil,sliderMeasureTitle: nil, sliderMaximumValue: nil, sliderMinimumValue: nil, tips: nil))
        self.controlCenterArray.append(sectionFour)

        self.tableView.reloadData()
    }
    
    // MARK: Set Logo
    func setLogo() {
        self.logoImageView.image = Utilities.shared.getAppLogo()
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
            
            
            if let eventIdDetails = devicesDetails.eventidDetails,  let eventIdDetail = eventIdDetails.first {
                if let eventName = eventIdDetail.eventname {
//                    let eventStartDate = Utilities.shared.convertStringToNSDateFormat(date: eventStartDateTime, currentFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ")
//                    let eventStartDateString = Utilities.shared.convertNSDateToStringFormat(date: eventStartDate, requiredFormat: "dd-MM-yyyy")
                    self.eventValue = "\(eventName)"
                } else {
                    self.eventValue = "-"
                    self.eventExpired = ""
                }
                if let eventEndDateTime = eventIdDetail.eventenddatetime, let eventEndDate = Utilities.shared.convertStringToNSDateFormat(date: eventEndDateTime, currentFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ"), Date().toLocalTime() > eventEndDate {
                    self.eventExpired = Message.Expired
                } else {
                    self.eventExpired = ""
                }
            } else {
                self.eventValue = "-"
                self.eventExpired = ""
            }
        } else {
            self.eventValue = "-"
            self.eventExpired = ""
        }
        self.dataBind()
    }
    
    func showTouchAndFaceID(){
        BioMetricAuthenticator.authenticateWithBioMetrics(reason: Message.UnlockControlCenter, cancelTitle: Message.Cancel) { (result) in
            switch result {
            case .success( _):
                self.securityView.isHidden = true
            case .failure(let error):
                switch error {
                case .biometryNotAvailable:
                    self.showPasscodeAuthentication()
                case .biometryNotEnrolled:
                    self.showPasscodeAuthentication()
                case .fallback:
                    self.showPasscodeAuthentication()
                case .biometryLockedout:
                    self.showPasscodeAuthentication()
                case .canceledBySystem, .canceledByUser:
                    break
                default:
                    self.showAlert(text: error.message())
                }
            }
        }
    }
    
    // show passcode authentication
    func showPasscodeAuthentication() {
        BioMetricAuthenticator.authenticateWithPasscode(reason: Message.UnlockControlCenter, cancelTitle: Message.Cancel) { (result) in
            switch result {
            case .success( _):
                self.securityView.isHidden = true
            case .failure(let error):
                switch error {
                case .canceledByUser, .fallback, .canceledBySystem:
                    break
                default:
                    self.showAlert(text: error.message())
                }
            }
        }
    }
    
    // MARK: - Button Action    
    @IBAction func manualSyncAction(_ sender: Any) {
        if APIManager.isConnectedToInternet() {
            Utilities.shared.showSVProgressHUD(message: Message.PleaseWaitSyncInProcess)
            LocalDataService.shared.starSyncData()
        } else {
            self.showAlert(text: Message.PleaseCheckYourInternetConnection)
        }
    }
    
    @IBAction func startScanningAction(_ sender: Any) {
        if let presentingViewController1 = self.presentingViewController, self.isFromCamera {
            if presentingViewController1.isKind(of: CameraViewController.self) {
                self.dismiss(animated: true)
            } else {
                presentingViewController1.presentingViewController?.dismiss(animated: true)
            }
        } else {
            if let controller = self.getViewController(storyboard: Storyboard.camera, id: "CameraViewController") as? CameraViewController {
                self.present(controller, animated: true)
            }
        }
    }

    @IBAction func signOutAction(_ sender: Any) {
        let alert = UIAlertController(title: Message.Confirm,
                                      message: Message.AreYouSureYouWantToLogout,
                                      preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: Message.Confirm, style: .destructive) { (action) in
            if let controller = self.getViewController(storyboard: Storyboard.login, id: "LoginViewController") as? LoginViewController {
                self.present(controller, animated: true) {
                    Utilities.shared.logout()
                }
            }
        }
        let noAction = UIAlertAction(title: Message.Cancel, style: .default) { (action) in}
        
        alert.addAction(noAction)
        alert.addAction(yesAction)
        self.present(alert, animated: true)
    }
    
    @IBAction func openFaceIdAction(_ sender: Any) {
        self.showTouchAndFaceID()
    }
}

enum ControlCenterType {
    case isValue
    case isSwitch
    case isNavigation
    case isSlider
}

struct ControlCenter {
    let type: ControlCenterType?
    let title: String?
    let value: String?
    let subValue: String?
    let switchOn: Bool?
    let sliderTitle: String?
    let sliderValue: Float?
    let sliderMeasureTitle: String?
    let sliderMaximumValue: Float?
    let sliderMinimumValue: Float?
    let tips: String?
}


extension ControlCenterViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.controlCenterArray.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCell(withIdentifier: "ControlCenterHeader") as! ControlCenterHeaderView
        headerCell.titleLabel.text = self.headerArray[section]
        return headerCell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.controlCenterArray[section].count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ControlCenterCell", for: indexPath as IndexPath) as! ControlCenterTableViewCell
        
        let data = self.controlCenterArray[indexPath.section][indexPath.row]
        cell.titleLabel.text = data.title ?? ""
        switch data.type {
        case .isSwitch:
            cell.switchStackView.isHidden = false
            cell.switchControl.isHidden = false
            cell.switchControl.setOn(data.switchOn ?? false, animated: false)
            cell.valueView.isHidden = true
            cell.indicatorImageView.isHidden = true
            cell.valueLabel.text = ""
            cell.subValueLabel.text = ""
            cell.sliderView.isHidden = true
            cell.sliderTitleLabel.text = ""
            cell.sliderValueLabel.text = ""
            cell.sliderMeasureTitleLabel.text = ""
        case .isSlider:
            cell.switchStackView.isHidden = true
            cell.switchControl.isHidden = false
            cell.switchControl.setOn(data.switchOn ?? false, animated: false)
            cell.valueView.isHidden = true
            cell.indicatorImageView.isHidden = true
            cell.valueLabel.text = ""
            cell.subValueLabel.text = ""
            cell.sliderView.isHidden = false
            cell.sliderTitleLabel.text = data.sliderTitle ?? ""
            cell.sliderValueLabel.text = "\(Int(data.sliderValue ?? 0))"
            cell.sliderMeasureTitleLabel.text = "\(data.sliderMeasureTitle ?? "")"
            cell.sliderControl.value = data.sliderValue ?? 0
            cell.sliderControl.maximumValue = data.sliderMaximumValue ?? 0
            cell.sliderControl.minimumValue = data.sliderMinimumValue ?? 0
        case .isValue:
            cell.switchStackView.isHidden = false
            cell.valueView.isHidden = false
            cell.valueLabel.text = data.value ?? ""
            if let subValue = data.subValue, subValue != "" {
                cell.subValueLabel.isHidden = false
                cell.subValueLabel.text = "  (\(subValue))"
            } else {
                cell.subValueLabel.isHidden = true
                cell.subValueLabel.text = ""
            }
            cell.switchControl.isHidden = true
            cell.indicatorImageView.isHidden = true
            cell.sliderView.isHidden = true
            cell.sliderTitleLabel.text = ""
            cell.sliderValueLabel.text = ""
            cell.sliderMeasureTitleLabel.text = ""
        case .isNavigation:
            cell.switchStackView.isHidden = false
            cell.indicatorImageView.isHidden = false
            cell.switchControl.isHidden = true
            cell.valueView.isHidden = true
            cell.valueLabel.text = ""
            cell.subValueLabel.text = ""
            cell.sliderView.isHidden = true
            cell.sliderTitleLabel.text = ""
            cell.sliderValueLabel.text = ""
            cell.sliderMeasureTitleLabel.text = ""
        default: break
        }
        
        if indexPath.section == 0 {
            cell.switchInfoButton.isHidden = false
            cell.sliderInfoButton.isHidden = false
        } else {
            cell.switchInfoButton.isHidden = true
            cell.sliderInfoButton.isHidden = true
        }
        cell.indexPath = indexPath
        cell.data = data
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            if indexPath.row == 1 {
                if let controller = self.getViewController(storyboard: Storyboard.dayLocation, id: "DayLocationViewController") as? DayLocationViewController {
                    controller.isFromControlCenter = true
                    controller.modalTransitionStyle = .coverVertical
                    self.present(controller, animated: true)
                }
            }
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                if let controller = self.getViewController(storyboard: Storyboard.logs, id: "LogsViewController") as? LogsViewController {
                    self.present(controller, animated: true)
                }
            } else if indexPath.row == 1 {
                if let controller = self.getViewController(storyboard: Storyboard.syncStats, id: "SyncStatsViewController") as? SyncStatsViewController {
                    self.present(controller, animated: true)
                }
            }
        } else if indexPath.section == 3 {
            if indexPath.row == 0 {
                if let controller = self.getViewController(storyboard: Storyboard.webView, id: "WebViewViewController") as? WebViewViewController {
                    controller.url = URL(string: Constants.TermsAndConditionsUrl)
                    controller.strTitle = Message.TermsOfUse
                    self.present(controller, animated: true)
                }
            } else if indexPath.row == 1 {
                if let controller = self.getViewController(storyboard: Storyboard.webView, id: "WebViewViewController") as? WebViewViewController {
                    controller.url = URL(string: Constants.PrivacyPolicyUrl)
                    controller.strTitle = Message.PrivacyPolicy
                    self.present(controller, animated: true)
                }
            }
        }
    }
}

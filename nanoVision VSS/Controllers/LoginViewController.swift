//
//  LoginViewController.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 04/04/24.
//

import UIKit
import TTTAttributedLabel

class LoginViewController: UIViewController {

    @IBOutlet weak var organizationIdTextField: UITextField!
    @IBOutlet weak var apikeyTextFiled: CustomSecureTextField!
    @IBOutlet weak var apiKeyShowHideButton: UIButton!
    @IBOutlet var agreeLabel: TTTAttributedLabel!
    @IBOutlet weak var versionLabel: UILabel!
    
    let urlTC = URL(string: Constants.TermsAndConditionsUrl)!
    let urlPP = URL(string: Constants.PrivacyPolicyUrl)!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configUI()
        self.setupTTAndPP()
        self.apiKeyShowHideAction(1)
    }
    
    // MARK: Config UI
    func configUI() {
        self.versionLabel.text = "\(Bundle.main.displayName ?? "") - Version \(Bundle.main.version ?? "")"
    }
    
    func setupTTAndPP() {
        self.agreeLabel.delegate = self
        let termsConditionText = Message.AgreeTo
        let strTC = Message.TermsOfUse
        let strPP = Message.PrivacyPolicy
        
        var linkFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
        var fullFont = UIFont.systemFont(ofSize: 13, weight: .medium)
        if Utilities.shared.isPadDevice() {
            linkFont = UIFont.systemFont(ofSize: 24, weight: .semibold)
            fullFont = UIFont.systemFont(ofSize: 24, weight: .medium)
        }
        
        let linkAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.lightBlueLabelColor!.cgColor,
            NSAttributedString.Key.underlineStyle: false,
            NSAttributedString.Key.font: linkFont] as [NSAttributedString.Key : Any]
        self.agreeLabel.linkAttributes = linkAttributes
        self.agreeLabel.activeLinkAttributes = linkAttributes
        self.agreeLabel.inactiveLinkAttributes = linkAttributes
        
        let fullAttributedString = NSAttributedString(string:termsConditionText, attributes: [
            NSAttributedString.Key.foregroundColor: UIColor.whiteLabelColor!.cgColor,
            NSAttributedString.Key.font: fullFont])
        self.agreeLabel.attributedText = fullAttributedString
        
        let rangeTC =  NSString(string: termsConditionText).range(of: strTC)
        let rangePP =  NSString(string: termsConditionText).range(of: strPP)
        self.agreeLabel.addLink(to: urlTC, with: rangeTC)
        self.agreeLabel.addLink(to: urlPP, with: rangePP)
    }
    
    // MARK: - Button Action
    @IBAction func apiKeyShowHideAction(_ sender: Any) {
        if self.apikeyTextFiled.isSecureTextEntry {
            if Utilities.shared.isPadDevice() {
                let backConfig = UIImage.SymbolConfiguration(
                    pointSize: 22, weight: .heavy, scale: .large)
                let backImage = UIImage(systemName: "eye.slash.fill", withConfiguration: backConfig)
                self.apiKeyShowHideButton.setImage(backImage, for: .normal)
            } else {
                let backConfig = UIImage.SymbolConfiguration(
                    pointSize: 18, weight: .heavy, scale: .medium)
                let backImage = UIImage(systemName: "eye.slash.fill", withConfiguration: backConfig)
                self.apiKeyShowHideButton.setImage(backImage, for: .normal)
            }
        } else {
            if Utilities.shared.isPadDevice() {
                let backConfig = UIImage.SymbolConfiguration(
                    pointSize: 22, weight: .heavy, scale: .large)
                let backImage = UIImage(systemName: "eye.fill", withConfiguration: backConfig)
                self.apiKeyShowHideButton.setImage(backImage, for: .normal)
            } else {
                let backConfig = UIImage.SymbolConfiguration(
                    pointSize: 18, weight: .heavy, scale: .medium)
                let backImage = UIImage(systemName: "eye.fill", withConfiguration: backConfig)
                self.apiKeyShowHideButton.setImage(backImage, for: .normal)
            }
        }
        self.apikeyTextFiled.isSecureTextEntry = !self.apikeyTextFiled.isSecureTextEntry
    }
    
    @IBAction func loginAction(_ sender: Any) {
        self.view.endEditing(true)
        if self.organizationIdTextField.text == "" {
            self.showAlert(text: Validation.OrganizationIdEnter)
        } else if self.apikeyTextFiled.text == "" {
            self.showAlert(text: Validation.APIKeyEnter)
        } else {
            self.login(orgId: self.organizationIdTextField.text ?? "", apiKey: self.apikeyTextFiled.text ?? "")
        }
    }
    
    func login(orgId: String, apiKey: String) {
        var deviceMac = KeychainServices.shared.getDeviceMac()
        if deviceMac == "" {
            deviceMac = "\(orgId)-\(Date().timestamp)"
        }
        
        LoginViewModel().loginApi(orgId: orgId, apiKey: apiKey, type: "body", deviceMac: deviceMac, isLoader: true) { data, error  in
            if let data = data, let status = data.status {
                if status.lowercased() == APIStatus.Success {
                    KeychainServices.shared.saveDeviceMac(deviceMac: deviceMac)
                    if let results = data.results, let authorizations = results.authorization, let authorization = authorizations.first, let accesstoken = authorization.accesstoken, let refreshtoken = authorization.refreshtoken, let devicesDetailsArray = results.devicesDetails, let devicesDetails = devicesDetailsArray.first {
                        UserDefaultsServices.shared.saveAccessToken(token: accesstoken)
                        UserDefaultsServices.shared.saveRefreshToken(token: refreshtoken)
                        UserDefaultsServices.shared.saveDevicesDetails(devicesDetails: devicesDetails)
                        OfflineDevicesDetails.shared.devicesDetails = devicesDetails
                        Utilities.shared.showSuccessSVProgressHUD(message: Message.SuccessfullyLoggedIn)
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                            Utilities.shared.dismissSVProgressHUD()
                            if let deviceStatus = devicesDetails.deviceStatus, let isDefaultKioskAssigned = devicesDetails.isDefaultKioskAssigned, let isDefaultEventAssigned = devicesDetails.isDefaultEventAssigned, deviceStatus.lowercased() == DeviceStatus.Approved {
                                if isDefaultKioskAssigned && isDefaultEventAssigned {
                                    if Utilities.shared.isMQTTEnabled() {
                                        if Utilities.shared.getAssignedRelay() != nil {
                                            self.goToCamera()
                                        } else {
                                            if let controller = self.getViewController(storyboard: Storyboard.deviceStatus, id: "DeviceStatusViewController") as? DeviceStatusViewController {
                                                self.present(controller, animated: true)
                                            }
                                        }
                                    } else {
                                        self.goToCamera()
                                    }
                                } else {
                                    if let controller = self.getViewController(storyboard: Storyboard.deviceStatus, id: "DeviceStatusViewController") as? DeviceStatusViewController {
                                        self.present(controller, animated: true)
                                    }
                                }
                            } else {
                                if let controller = self.getViewController(storyboard: Storyboard.deviceStatus, id: "DeviceStatusViewController") as? DeviceStatusViewController {
                                    self.present(controller, animated: true)
                                }
                            }
                        }
                    } else {
                        self.showAlert(text: Validation.SomethingWrong)
                    }
                } else if let message = data.message {
                    self.showAlert(text: message)
                } else {
                    self.showAlert(text: Validation.SomethingWrong)
                }
            } else {
                if let error = error {
                    self.showAlert(text: error.localizedDescription)
                } else {
                    self.showAlert(text: Validation.SomethingWrong)
                }
            }
        }
    }
    
    func goToCamera() {
        LocalDataService.shared.syncCompleted = {
            DispatchQueue.main.async() {
                Utilities.shared.dismissSVProgressHUD()
                if let controller = self.getViewController(storyboard: Storyboard.dayLocation, id: "DayLocationViewController") as? DayLocationViewController {
                    controller.isFromDeviceStatus = false
                    self.present(controller, animated: true)
                }
            }
        }
        Utilities.shared.showSVProgressHUD(message: Message.PleaseWaitSyncInProcess)
        LocalDataService.shared.getDeviceStatus()
    }
}

extension LoginViewController: TTTAttributedLabelDelegate {
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        if let controller = self.getViewController(storyboard: Storyboard.webView, id: "WebViewViewController") as? WebViewViewController {
            controller.url = url
            if url == self.urlTC {
                controller.strTitle = Message.TermsOfUse
            } else {
                controller.strTitle = Message.PrivacyPolicy
            }
            self.present(controller, animated: true)
        }
    }
}

class CustomSecureTextField: UITextField {
    override var isSecureTextEntry: Bool {
        didSet {
            if self.isFirstResponder {
                _ = self.becomeFirstResponder()
                if self.isSecureTextEntry, let text = self.text {
                    self.text = ""
                    self.insertText(text)
                    self.insertText(" ")
                    self.deleteBackward()
                }
            }
        }
    }

    override func becomeFirstResponder() -> Bool {
        let success = super.becomeFirstResponder()
        if self.isSecureTextEntry, let text = self.text {
            self.text = ""
            self.insertText(text)
            self.insertText(" ")
            self.deleteBackward()
        }
        return success
    }
}

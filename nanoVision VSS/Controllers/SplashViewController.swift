//
//  SplashViewController.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 04/04/24.
//

import UIKit

class SplashViewController: UIViewController {
    
    @IBOutlet weak var versionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configUI()
    }
    
    // MARK: Config UI
    func configUI() {
        self.versionLabel.text = "\(Bundle.main.displayName ?? "") - Version \(Bundle.main.version ?? "")"
        appDelegate.checkVersion { status in
            if status == false {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.5) {
                    self.showStartScreen()
                }
            }
        }
    }

    func showStartScreen() {
        DispatchQueue.main.async() {
            if UserDefaultsServices.shared.isLogin() {
                LocalDataService.shared.syncCompleted = {
                    DispatchQueue.main.async() {
                        Utilities.shared.dismissSVProgressHUD()
                        if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails, let deviceStatus =  devicesDetails.deviceStatus {
                            if deviceStatus.lowercased() == DeviceStatus.Approved {
                                if let isDefaultKioskAssigned = devicesDetails.isDefaultKioskAssigned, let isDefaultEventAssigned = devicesDetails.isDefaultEventAssigned, (isDefaultKioskAssigned && isDefaultEventAssigned) {
                                    if Utilities.shared.isMQTTEnabled() {
                                        if Utilities.shared.getAssignedRelay() != nil {
                                            if let controller = self.getViewController(storyboard: Storyboard.dayLocation, id: "DayLocationViewController") as? DayLocationViewController {
                                                controller.isFromDeviceStatus = false
                                                self.present(controller, animated: true)
                                            }
                                        } else {
                                            if let controller = self.getViewController(storyboard: Storyboard.deviceStatus, id: "DeviceStatusViewController") as? DeviceStatusViewController {
                                                self.present(controller, animated: true)
                                            }
                                        }
                                    } else {
                                        if let controller = self.getViewController(storyboard: Storyboard.dayLocation, id: "DayLocationViewController") as? DayLocationViewController {
                                            controller.isFromDeviceStatus = false
                                            self.present(controller, animated: true)
                                        }
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
                        } else {
                            Utilities.shared.logout()
                            if let controller = self.getViewController(storyboard: Storyboard.login, id: "LoginViewController") as? LoginViewController {
                                self.present(controller, animated: true)
                            }
                        }
                    }
                }
                OfflineDevicesDetails.shared.devicesDetails = UserDefaultsServices.shared.getDevicesDetails()
                Utilities.shared.showSVProgressHUD(message: Message.PleaseWaitSyncInProcess)
                LocalDataService.shared.getDeviceStatus()
            } else {
                Utilities.shared.logout()
                if let controller = self.getViewController(storyboard: Storyboard.login, id: "LoginViewController") as? LoginViewController {
                    self.present(controller, animated: true)
                }
            }
        }
    }
}

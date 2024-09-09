//
//  DeviceStatusViewController.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 05/04/24.
//

import UIKit

class DeviceStatusViewController: UIViewController {

    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var checkStatusButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var macAddressLabel: UILabel!
    
    var deviceStatusArray = [DeviceStatusData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configUI()
        self.setupTableView()
        self.dataBinding()
    }
    
    // MARK: Config UI
    func configUI() {
        Utilities.shared.addSideRadiusWithOpacity(view: self.lineView, radius: 0, shadowRadius: 4, opacity: 1, shadowOffset: CGSize(width: 0 , height: 4), shadowColor: UIColor.black.withAlphaComponent(0.25), corners: [])
    }
    
    override func viewDidLayoutSubviews() {
        self.checkStatusButton.cornerRadiusV = self.checkStatusButton.frame.height / 2
        self.signOutButton.cornerRadiusV = self.signOutButton.frame.height / 2
    }
    
    func setupTableView() {
        if #available(iOS 15.0, *) {
            self.tableView.sectionHeaderTopPadding = 0.0
        }
        self.tableView.tableHeaderView = self.headerView
        self.tableView.tableFooterView = UIView(frame: .zero)
        self.tableView.estimatedRowHeight = 200.0
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.register(UINib.init(nibName: "DeviceStatusTableViewCell", bundle: nil), forCellReuseIdentifier: "DeviceStatusCell")
        
        if let headerView = self.tableView.tableHeaderView {
            var headerViewFrame = headerView.frame
            if Utilities.shared.isPadDevice() {
                headerViewFrame.size.height = 220
            } else {
                headerViewFrame.size.height = 170
            }
            headerView.frame = headerViewFrame
            self.tableView.tableHeaderView = headerView
        }
    }
    
    func dataBinding() {
        self.logoImageView.image = Utilities.shared.getAppLogo()
        self.macAddressLabel.text = "Device MAC: \(KeychainServices.shared.getDeviceMac())"
        self.deviceStatusArray.removeAll()
        if let devicesDetails = OfflineDevicesDetails.shared.devicesDetails {
            if let deviceStatus = devicesDetails.deviceStatus {
                var data = DeviceStatusData(title: Message.DeviceApproval, message: "", status: deviceStatus.lowercased())
                if deviceStatus.lowercased() == DeviceStatus.Pending {
                    data.message = Message.DevicePendingMessage
                } else if deviceStatus.lowercased() == DeviceStatus.Rejected {
                    data.message = Message.DeviceRejectedMessage
                } else {
                    data.message = Message.DeviceApprovedMessage
                }
                self.deviceStatusArray.append(data)
            }
            
            if let isDefaultKioskAssigned = devicesDetails.isDefaultKioskAssigned {
                var data = DeviceStatusData(title: Message.KioskAssignment, message: "", status: DeviceStatus.Pending)
                if isDefaultKioskAssigned == false {
                    data.message = Message.KioskAssignmentPending
                    data.status = DeviceStatus.Pending
                } else {
                    data.message = Message.KioskAssigned
                    data.status = DeviceStatus.Approved
                }
                self.deviceStatusArray.append(data)
            }
            
            if let isDefaultEventAssigned = devicesDetails.isDefaultEventAssigned {
                var data = DeviceStatusData(title: Message.EventAssignment, message: "", status: DeviceStatus.Pending)
                if isDefaultEventAssigned == false {
                    data.message = Message.EventAssignmentPending
                    data.status = DeviceStatus.Pending
                } else {
                    data.message = Message.EventAssigned
                    data.status = DeviceStatus.Approved
                }
                self.deviceStatusArray.append(data)
            }
            
            if Utilities.shared.isMQTTEnabled() {
                var data = DeviceStatusData(title: Message.RelayAssignment, message: "", status: DeviceStatus.Pending)
                if Utilities.shared.getAssignedRelay() == nil {
                    data.message = Message.RelayAssignmentPending
                    data.status = DeviceStatus.Pending
                } else {
                    data.message = Message.RelayAssigned
                    data.status = DeviceStatus.Approved
                }
                self.deviceStatusArray.append(data)
            }
        }
        self.tableView.reloadData()
    }
    
    // MARK: - Button Action
    @IBAction func checkStatusAction(_ sender: Any) {
        LoginViewModel().getDeviceStatus(deviceMac: KeychainServices.shared.getDeviceMac(), isLoader: true) { data in
            if let data = data, let status = data.status {
                if status.lowercased() == APIStatus.Success {
                    if let results = data.results, let devicesDetailsArray = results.devicesDetails, let devicesDetails = devicesDetailsArray.first, let deviceStatus = devicesDetails.deviceStatus {
                        UserDefaultsServices.shared.saveDevicesDetails(devicesDetails: devicesDetails)
                        OfflineDevicesDetails.shared.devicesDetails = devicesDetails
                        if deviceStatus.lowercased() == DeviceStatus.Approved {
                            if let isDefaultKioskAssigned = devicesDetails.isDefaultKioskAssigned, let isDefaultEventAssigned = devicesDetails.isDefaultEventAssigned, (isDefaultKioskAssigned && isDefaultEventAssigned) {
                                if Utilities.shared.isMQTTEnabled() {
                                    if Utilities.shared.getAssignedRelay() != nil {
                                        if let controller = self.getViewController(storyboard: Storyboard.dayLocation, id: "DayLocationViewController") as? DayLocationViewController {
                                            controller.isFromDeviceStatus = true
                                            self.present(controller, animated: true)
                                        }
                                    } else {
                                        self.dataBinding()
                                    }
                                } else {
                                    if let controller = self.getViewController(storyboard: Storyboard.dayLocation, id: "DayLocationViewController") as? DayLocationViewController {
                                        controller.isFromDeviceStatus = true
                                        self.present(controller, animated: true)
                                    }
                                }
                            } else {
                                self.dataBinding()
                            }
                        } else {
                            self.dataBinding()
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
                self.showAlert(text: Validation.SomethingWrong)
            }
        }
    }
    
    @IBAction func signOutAction(_ sender: Any) {
        let alert = UIAlertController(title: Message.Confirm,
                                      message: Message.AreYouSureYouWantToLogout,
                                      preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: Message.Confirm, style: .destructive) { (action) in
            Utilities.shared.logout()
            if let controller = self.getViewController(storyboard: Storyboard.login, id: "LoginViewController") as? LoginViewController {
                self.present(controller, animated: true)
            }
        }
        let noAction = UIAlertAction(title: Message.Cancel, style: .default) { (action) in}
        
        alert.addAction(noAction)
        alert.addAction(yesAction)
        self.present(alert, animated: true)
    }
}

struct DeviceStatusData {
    var title = ""
    var message = ""
    var status = ""
}

extension DeviceStatusViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.deviceStatusArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceStatusCell", for: indexPath as IndexPath) as! DeviceStatusTableViewCell
        
        let data = self.deviceStatusArray[indexPath.row]
        
        cell.titleLabel.text = data.title
        cell.statusLabel.text = data.message
        if data.status == DeviceStatus.Approved {
            cell.statusImageView.image = .approved
        } else if data.status == DeviceStatus.Rejected {
            cell.statusImageView.image = .rejected
        } else {
            cell.statusImageView.image = .pending
        }
        
        return cell
    }
}

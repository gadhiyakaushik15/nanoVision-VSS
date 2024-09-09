//
//  SyncStatsViewController.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 06/04/24.
//

import UIKit

class SyncStatsViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var syncSuccessfullyLabel: UILabel!
    
    let headerArray = [Message.PeopleSyncDetails, Message.LogSyncDetails]
    var syncArray = [[ControlCenter]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configUI()
        self.setupTableView()
        self.setLogo()
        self.bindData(isLoader: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        LocalDataService.shared.syncCompleted = {
            DispatchQueue.main.async() {
                self.syncSuccessfullyLabel.isHidden = false
                self.setLogo()
                self.bindData()
                DispatchQueue.main.asyncAfter(deadline: .now() + (Constants.AutoSyncTime - (Constants.AutoSyncTime/4))) {
                    self.syncSuccessfullyLabel.isHidden = true
                }
            }
            if Utilities.shared.isMQTTEnabled() {
                MQTTManager.shared().checkRelayChange()
            }        }
    }
    
    // MARK: Config UI
    func configUI() {
        Utilities.shared.addSideRadiusWithOpacity(view: self.lineView, radius: 0, shadowRadius: 4, opacity: 1, shadowOffset: CGSize(width: 0 , height: 4), shadowColor: UIColor.black.withAlphaComponent(0.25), corners: [])
        if Utilities.shared.isPadDevice() {
            self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 0)
            let config = UIImage.SymbolConfiguration(
                pointSize: 26, weight: .heavy, scale: .large)
            let image = UIImage(systemName: "arrow.backward", withConfiguration: config)
            self.backButton.setImage(image, for: .normal)
        } else {
            self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
            let config = UIImage.SymbolConfiguration(
                pointSize: 18, weight: .heavy, scale: .medium)
            let image = UIImage(systemName: "arrow.backward", withConfiguration: config)
            self.backButton.setImage(image, for: .normal)
        }
        
        self.syncSuccessfullyLabel.isHidden = true
    }
    
    func setupTableView() {
        if #available(iOS 15.0, *) {
            self.tableView.sectionHeaderTopPadding = 0.0
        }
        self.tableView.tableHeaderView = self.headerView
        self.tableView.tableFooterView = self.footerView
        self.tableView.estimatedRowHeight = 200.0
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.register(UINib.init(nibName: "ControlCenterTableViewCell", bundle: nil), forCellReuseIdentifier: "ControlCenterCell")
        self.tableView.register(UINib.init(nibName: "ControlCenterHeaderView", bundle: nil), forCellReuseIdentifier: "ControlCenterHeader")
        
        if let headerView = self.tableView.tableHeaderView {
            var headerViewFrame = headerView.frame
            if Utilities.shared.isPadDevice() {
                headerViewFrame.size.height = 100
            } else {
                headerViewFrame.size.height = 60
            }
            headerView.frame = headerViewFrame
            self.tableView.tableHeaderView = headerView
        }
    }
    
    // MARK: Data Bind
    func bindData(isLoader: Bool = false) {
        if isLoader {
            Utilities.shared.showSVProgressHUD()
        }
        LocalDataService.shared.fetchLogs { logs in
            DispatchQueue.main.async {
                Utilities.shared.dismissSVProgressHUD()
                let peoplesLastSyncTime = UserDefaultsServices.shared.getPeoplesLastSyncDate() ?? "-"
                let peoples = OfflinePeoples.shared.peoples
                let totalPeoples = "\(peoples.count) \(Message.People)"
                
                let logsLastSyncTime = UserDefaultsServices.shared.getLogsLastSyncDate() ?? "-"
                var totalLogs = ""
                if logs.count > 1 {
                    totalLogs = "\(logs.count) \(Message.Logs)"
                } else {
                    totalLogs = "\(logs.count) \(Message.Log)"
                }
                let syncLogs = logs.filter { $0.iscreated == true}
                var totalSyncLogs = ""
                if syncLogs.count > 1 {
                    totalSyncLogs = "\(syncLogs.count) \(Message.Logs)"
                } else {
                    totalSyncLogs = "\(syncLogs.count) \(Message.Log)"
                }
                
                self.syncArray.removeAll()
                var sectionOne = [ControlCenter]()
                sectionOne.append(ControlCenter(type: .isValue, title: Message.LastSyncTime, value: peoplesLastSyncTime, subValue: nil, switchOn: nil, sliderTitle: nil, sliderValue: nil,sliderMeasureTitle: nil, sliderMaximumValue: nil, sliderMinimumValue: nil, tips: nil))
                sectionOne.append(ControlCenter(type: .isValue, title: Message.TotalNumberOfPeople, value: totalPeoples, subValue: nil, switchOn: nil, sliderTitle: nil, sliderValue: nil,sliderMeasureTitle: nil, sliderMaximumValue: nil, sliderMinimumValue: nil, tips: nil))
                self.syncArray.append(sectionOne)
                
                var sectionTwo = [ControlCenter]()
                sectionTwo.append(ControlCenter(type: .isValue, title: Message.LastSyncTime, value: logsLastSyncTime, subValue: nil, switchOn: nil, sliderTitle: nil, sliderValue: nil,sliderMeasureTitle: nil, sliderMaximumValue: nil, sliderMinimumValue: nil, tips: nil))
                sectionTwo.append(ControlCenter(type: .isValue, title: Message.TotalNumberOfLogs, value: totalLogs, subValue: nil, switchOn: nil, sliderTitle: nil, sliderValue: nil,sliderMeasureTitle: nil, sliderMaximumValue: nil, sliderMinimumValue: nil, tips: nil))
                sectionTwo.append(ControlCenter(type: .isValue, title: Message.SyncedWithServer, value: totalSyncLogs, subValue: nil, switchOn: nil, sliderTitle: nil, sliderValue: nil,sliderMeasureTitle: nil, sliderMaximumValue: nil, sliderMinimumValue: nil, tips: nil))
                self.syncArray.append(sectionTwo)
                
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: Set Logo
    func setLogo() {
        self.logoImageView.image = Utilities.shared.getAppLogo()
    }
    
    // MARK: - Button Action
    @IBAction func backAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func manualSyncAction(_ sender: Any) {
        if APIManager.isConnectedToInternet() {
            self.syncSuccessfullyLabel.isHidden = true
            Utilities.shared.showSVProgressHUD(message: Message.PleaseWaitSyncInProcess)
            LocalDataService.shared.starSyncData(isSyncLogs: true)
        } else {
            self.showAlert(text: Message.PleaseCheckYourInternetConnection)
        }
    }
}

extension SyncStatsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.syncArray.count
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
        self.syncArray[section].count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ControlCenterCell", for: indexPath as IndexPath) as! ControlCenterTableViewCell
        
        let data = self.syncArray[indexPath.section][indexPath.row]
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
        cell.switchInfoButton.isHidden = true
        cell.sliderInfoButton.isHidden = true
        
        return cell
    }
}

//
//  LogsViewController.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 08/04/24.
//

import UIKit

class LogsViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var filterButton: UIButton!
    
    var isFirsTime = true
    var isSearching: Bool = false
    var allLogs = [Logs]()
    var logs = [Logs]()
    var searchLogs = [Logs]()
    var filters = LogsFilters()
    var lastEventId = Utilities.shared.getSelectedEventId()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configUI()
        self.setupTableView()
        self.setLogo()
        self.getAllLogs()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        LocalDataService.shared.syncCompleted = {
            DispatchQueue.main.async() {
                self.setLogo()
                let latestEventId = Utilities.shared.getSelectedEventId()
                if self.lastEventId != latestEventId {
                    self.lastEventId = latestEventId
                    Utilities.shared.showSVProgressHUD()
                    LocalDataService.shared.fetchLogs { logs in
                        DispatchQueue.main.async {
                            Utilities.shared.dismissSVProgressHUD()
                            self.allLogs = logs
                            self.logs = self.allLogs
                            self.applyFilters()
                            if self.isSearching {
                                self.searchUser(text: self.searchBar.text ?? "")
                            }
                            self.tableView.reloadData()
                        }
                    }
                }
            }
            if Utilities.shared.isMQTTEnabled() {
                MQTTManager.shared().checkRelayChange()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: Config UI
    func configUI() {
        Utilities.shared.addSideRadiusWithOpacity(view: self.lineView, radius: 0, shadowRadius: 4, opacity: 1, shadowOffset: CGSize(width: 0 , height: 4), shadowColor: UIColor.black.withAlphaComponent(0.25), corners: [])
        
        if Utilities.shared.isPadDevice() {
            let backConfig = UIImage.SymbolConfiguration(
                pointSize: 26, weight: .heavy, scale: .large)
            let backImage = UIImage(systemName: "arrow.backward", withConfiguration: backConfig)
            self.backButton.setImage(backImage, for: .normal)
            let filterConfig = UIImage.SymbolConfiguration(
                pointSize: 44, weight: .heavy, scale: .large)
            let filterImage = UIImage(systemName: "line.3.horizontal.decrease.circle", withConfiguration: filterConfig)
            self.filterButton.setImage(filterImage, for: .normal)
            self.searchBar.searchTextField.font = UIFont.systemFont(ofSize: 23.0, weight: .medium)
        } else {
            let backConfig = UIImage.SymbolConfiguration(
                pointSize: 18, weight: .heavy, scale: .medium)
            let backImage = UIImage(systemName: "arrow.backward", withConfiguration: backConfig)
            self.backButton.setImage(backImage, for: .normal)
            let filterConfig = UIImage.SymbolConfiguration(
                pointSize: 25, weight: .heavy, scale: .medium)
            let filterImage = UIImage(systemName: "line.3.horizontal.decrease.circle", withConfiguration: filterConfig)
            self.filterButton.setImage(filterImage, for: .normal)
            self.searchBar.searchTextField.font = UIFont.systemFont(ofSize: 13.0, weight: .medium)
        }
        self.searchBar.placeholder = Message.SearchUserName
    }

    // MARK: Set Logo
    func setLogo() {
        self.logoImageView.image = Utilities.shared.getAppLogo()
    }
    
    func getAllLogs() {
        Utilities.shared.showSVProgressHUD()
        LocalDataService.shared.fetchLogs() { logs in
            DispatchQueue.main.async {
                Utilities.shared.dismissSVProgressHUD()
                self.allLogs = logs
                self.logs = self.allLogs
                self.isFirsTime = false
                self.tableView.reloadData()
            }
        }
    }
    
    func setupTableView() {
        if #available(iOS 15.0, *) {
            self.tableView.sectionHeaderTopPadding = 0.0
        }
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: .leastNormalMagnitude))
        self.tableView.estimatedRowHeight = 200.0
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.register(UINib.init(nibName: "LogsTableViewCell", bundle: nil), forCellReuseIdentifier: "LogsCell")
        self.tableView.register(UINib.init(nibName: "LogsHeaderview", bundle: nil), forCellReuseIdentifier: "LogsHeader")
        self.tableView.register(UINib.init(nibName: "NoDataTableViewCell", bundle: nil), forCellReuseIdentifier: "NoDataCell")
    }
    
    func applyFilters() {
        self.logs = self.allLogs
        if !(self.filters.isSuccessfulTick && self.filters.isFailedTick) {
            if self.filters.isSuccessfulTick {
                self.logs = self.logs.filter({ log in
                    if let scanType = ScanType(rawValue: Int(log.scantype)), scanType == .success {
                        return true
                    } else {
                        return false
                    }
                })
            } else if self.filters.isFailedTick {
                self.logs = self.logs.filter({ log in
                    if let scanType = ScanType(rawValue: Int(log.scantype)), scanType != .success {
                        return true
                    } else {
                        return false
                    }
                })
            }
        }
        
        if self.filters.isVisitorTick {
            self.logs = self.logs.filter({ log in
                if let usertype = log.usertype, usertype.lowercased() == UserType.Visitor  {
                    return true
                } else {
                    return false
                }
            })
        }
    }
    
    // MARK: - Button Action
    @IBAction func backAction(_ sender: Any) {
        self.searchBar.resignFirstResponder()
        self.dismiss(animated: true)
    }
    
    @IBAction func filterAction(_ sender: Any) {
        self.searchBar.resignFirstResponder()
        if let controller = self.getViewController(storyboard: Storyboard.logsFilters, id: "LogsFiltersViewController") as? LogsFiltersViewController {
            controller.filters = self.filters
            controller.delegate = self
            self.present(controller, animated: true)
        }
    }
}

extension LogsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCell(withIdentifier: "LogsHeader") as! LogsHeaderview
        return headerCell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var tempLogs = [Logs]()
        if self.isSearching {
            tempLogs = self.searchLogs
        } else {
            tempLogs = self.logs
        }
        if tempLogs.count > 0 {
            return tempLogs.count
        } else {
            if self.isFirsTime {
                return 0
            } else {
                return 1
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var tempLogs = [Logs]()
        if self.isSearching {
            tempLogs = self.searchLogs
        } else {
            tempLogs = self.logs
        }
        if tempLogs.count > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LogsCell", for: indexPath as IndexPath) as! LogsTableViewCell
            
            var data = Logs()
            if self.isSearching {
                data = self.searchLogs[indexPath.row]
            } else {
                data = self.logs[indexPath.row]
            }
            
            if let scanType = ScanType(rawValue: Int(data.scantype)) {
                switch scanType {
                case .success:
                    cell.scanTypeView.backgroundColor = .successScanColor
                case .livenessFailed, .futureEvent, .expiredEvent:
                    cell.scanTypeView.backgroundColor = .warningScanColor
                case .unauthorized:
                    cell.scanTypeView.backgroundColor = .failedScanColor
                }
            } else {
                cell.scanTypeView.backgroundColor = .clear
            }
            
            if let createdDate = data.createddate, let date = Utilities.shared.convertStringToNSDateFormat(date: createdDate, currentFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") {
                
                cell.dateTimeLabel.text = Utilities.shared.convertNSDateToStringFormat(date: date, requiredFormat: "MMM d, yyyy h:mm a")
            } else {
                cell.dateTimeLabel.text = "-"
            }
            
            if let peopleName = data.peoplename, peopleName != "" {
                cell.userNameLabel.text = peopleName
            } else {
                cell.userNameLabel.text = "-"
            }
            if let message = data.message, message != "" {
                cell.messageLabel.text = message
            } else {
                cell.messageLabel.text = "-"
            }
            if let eventName = data.eventname, eventName != "" {
                cell.eventNameLabel.text = eventName
            } else {
                cell.eventNameLabel.text = "-"
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoDataCell", for: indexPath as IndexPath) as! NoDataTableViewCell
            
            cell.noDataLabel.text = Message.NoLogsFound
            
            return cell
        }
    }
}

extension LogsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchBar.text?.count)! > 0 {
            isSearching = true
            self.searchUser(text: searchBar.text ?? "")
        } else {
            self.isSearching = false
        }
        self.tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchUser(text: String) {
        self.searchLogs.removeAll()
        for log in self.logs {
            if (log.peoplename ?? "").lowercased().contains(text.lowercased()) {
                self.searchLogs.append(log)
            }
        }
    }
}

extension LogsViewController: LogsFiltersDelegate {
    func didLogsFilters(filters: LogsFilters) {
        self.filters = filters
        self.applyFilters()
        if self.isSearching {
            self.searchUser(text: self.searchBar.text ?? "")
        }
        self.tableView.reloadData()
    }
}

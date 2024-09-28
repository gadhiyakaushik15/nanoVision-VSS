//
//  ListViewViewController.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 31/05/24.
//

import UIKit

protocol ListViewDelegate {
    func getListData(people: Peoples)
}

class ListViewViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var searchPlaceholder = ""
    var isFirsTime = true
    var isSearching: Bool = false
    var peoples =  OfflinePeoples.shared.peoples
    var searchPeoples = [Peoples]()
    var delegate: ListViewDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configUI()
        self.setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        LocalDataService.shared.syncCompleted = {
            DispatchQueue.main.async() {
                Utilities.shared.dismissSVProgressHUD()
                self.peoples = OfflinePeoples.shared.peoples
                self.tableView.reloadData()
            }
            if Utilities.shared.isMQTTEnabled() {
                MQTTManager.shared().checkRelayChange()
            }
        }
    }
    
    // MARK: Config UI
    func configUI() {
        Utilities.shared.addSideRadiusWithOpacity(view: self.lineView, radius: 0, shadowRadius: 4, opacity: 1, shadowOffset: CGSize(width: 0 , height: 4), shadowColor: UIColor.black.withAlphaComponent(0.25), corners: [])
        
        if Utilities.shared.isPadDevice() {
            let backConfig = UIImage.SymbolConfiguration(
                pointSize: 26, weight: .heavy, scale: .large)
            let backImage = UIImage(systemName: "arrow.backward", withConfiguration: backConfig)
            self.backButton.setImage(backImage, for: .normal)
            self.searchBar.searchTextField.font = UIFont.systemFont(ofSize: 23.0, weight: .medium)
            self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 0)
        } else {
            let backConfig = UIImage.SymbolConfiguration(
                pointSize: 18, weight: .heavy, scale: .medium)
            let backImage = UIImage(systemName: "arrow.backward", withConfiguration: backConfig)
            self.backButton.setImage(backImage, for: .normal)
            self.searchBar.searchTextField.font = UIFont.systemFont(ofSize: 13.0, weight: .medium)
            self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        }
        self.searchBar.placeholder = searchPlaceholder
    }
    
    func setupTableView() {
        if #available(iOS 15.0, *) {
            self.tableView.sectionHeaderTopPadding = 0.0
        }
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: .leastNormalMagnitude))
        self.tableView.estimatedRowHeight = 200.0
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.register(UINib.init(nibName: "ListViewTableViewCell", bundle: nil), forCellReuseIdentifier: "ListViewCell")
        self.tableView.register(UINib.init(nibName: "NoDataTableViewCell", bundle: nil), forCellReuseIdentifier: "NoDataCell")
        
        self.isFirsTime = false
        self.tableView.reloadData()
    }
    
    // MARK: - Button Action
    @IBAction func backAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
}

extension ListViewViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var tempPeople = [Peoples]()
        if self.isSearching {
            tempPeople = self.searchPeoples
        } else {
            tempPeople = self.peoples
        }
        if tempPeople.count > 0 {
            return tempPeople.count
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
        var tempPeople = [Peoples]()
        if self.isSearching {
            tempPeople = self.searchPeoples
        } else {
            tempPeople = self.peoples
        }
        if tempPeople.count > 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ListViewCell", for: indexPath as IndexPath) as! ListViewTableViewCell
            
            var peopleData: Peoples?
            if self.isSearching {
                peopleData = self.searchPeoples[indexPath.row]
            } else {
                peopleData = self.peoples[indexPath.row]
            }
            
            if let data = peopleData {
                let firstName = data.firstname ?? ""
                let lastName = data.lastname ?? ""
                
                cell.shortNameLabel.text = "\(firstName.uppercased().prefix(1))\(lastName.uppercased().prefix(1))"
                cell.nameLabel.text = "\(firstName) \(lastName)"
            } else {
                cell.shortNameLabel.text = "-"
                cell.nameLabel.text = "-"
            }
                        
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoDataCell", for: indexPath as IndexPath) as! NoDataTableViewCell
            
            cell.noDataLabel.text = Message.NoDataFound
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var tempPeople = [Peoples]()
        if self.isSearching {
            tempPeople = self.searchPeoples
        } else {
            tempPeople = self.peoples
        }
        if tempPeople.count > 0 {
            self.delegate?.getListData(people: tempPeople[indexPath.row])
            self.backAction(1)
        }
    }
}

extension ListViewViewController: UISearchBarDelegate {
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
        self.searchPeoples.removeAll()
        for people in self.peoples {
            if (people.firstname ?? "").lowercased().contains(text.lowercased()) || (people.lastname ?? "").lowercased().contains(text.lowercased()){
                self.searchPeoples.append(people)
            }
        }
    }
}

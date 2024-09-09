//
//  DayLocationViewController.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 09/09/24.
//

import UIKit

class DayLocationViewController: UIViewController {

    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var dayDropDownTextField: DropDown!
    @IBOutlet weak var locationDropDownTextField: DropDown!
    @IBOutlet weak var continueButton: UIButton!
    
    var dayData: ListModel?
    var locationData: ListModel?
    var isFromDeviceStatus = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configUI()
        self.setLogo()
        self.setDayDropDown()
        self.setLocationDropDown()
        self.fetchData()
    }
    
    override func viewDidLayoutSubviews() {
        self.continueButton.cornerRadiusV = self.continueButton.frame.height / 2
    }
    
    // MARK: Config UI
    func configUI() {
        Utilities.shared.addSideRadiusWithOpacity(view: self.lineView, radius: 0, shadowRadius: 4, opacity: 1, shadowOffset: CGSize(width: 0 , height: 4), shadowColor: UIColor.black.withAlphaComponent(0.25), corners: [])
    }
    
    // MARK: Set Logo
    func setLogo() {
        self.logoImageView.image = Utilities.shared.getAppLogo()
    }
    
    func fetchData() {
        Utilities.shared.showSVProgressHUD()
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        self.getDay {
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        self.getLocation {
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            Utilities.shared.dismissSVProgressHUD()
        }
    }

    func getDay(completion:(() -> Void)?) {
        ViableSoftModel().getDays(isLoader: false) { data in
            if let dataArray = data {
                var optionArray = [ListModel]()
                let selectedDay =  UserDefaultsServices.shared.getSelectedDay()
                for (index, day) in dataArray.enumerated() {
                    optionArray.append(ListModel(listId: day.id, listImage: nil, listName: day.dayid))
                    if selectedDay == day.dayid {
                        self.dayData = ListModel(listId: day.id, listImage: nil, listName: day.dayid)
                        self.dayDropDownTextField.text = selectedDay
                        self.dayDropDownTextField.selectedIndex = index
                    }
                }
                self.dayDropDownTextField.optionArray = optionArray
            }
            completion?()
        }
    }
    
    func getLocation(completion:(() -> Void)?) {
        ViableSoftModel().getLocationTable(isLoader: false) { data in
            if let dataArray = data {
                var optionArray = [ListModel]()
                let selectedLocation =  UserDefaultsServices.shared.getSelectedLocation()
                for (index, location) in dataArray.enumerated() {
                    optionArray.append(ListModel(listId: location.id, listImage: nil, listName: location.gate))
                    if selectedLocation == location.gate {
                        self.locationData = ListModel(listId: location.id, listImage: nil, listName: location.gate)
                        self.locationDropDownTextField.text = selectedLocation
                        self.locationDropDownTextField.selectedIndex = index
                    }
                }
                self.locationDropDownTextField.optionArray = optionArray
            }
            completion?()
        }
    }
    
    func setDayDropDown() {
        if Utilities.shared.isPadDevice() {
            self.dayDropDownTextField.arrowSize = 22.0
            self.dayDropDownTextField.rowHeight = 50.0
            self.dayDropDownTextField.listHeight = self.dayDropDownTextField.rowHeight * 4
            self.dayDropDownTextField.paddingLeft = 15
            self.dayDropDownTextField.paddingRight = 50
        } else {
            self.dayDropDownTextField.arrowSize = 15.0
            self.dayDropDownTextField.rowHeight = 40.0
            self.dayDropDownTextField.listHeight = self.dayDropDownTextField.rowHeight * 4
            self.dayDropDownTextField.paddingLeft = 12
            self.dayDropDownTextField.paddingRight = 40
        }
        self.dayDropDownTextField.didSelectCompletion = { list in
            self.dayData = list
        }
    }
    
    func setLocationDropDown() {
        if Utilities.shared.isPadDevice() {
            self.locationDropDownTextField.arrowSize = 22.0
            self.locationDropDownTextField.rowHeight = 50.0
            self.locationDropDownTextField.listHeight = self.locationDropDownTextField.rowHeight * 4
            self.locationDropDownTextField.paddingLeft = 15
            self.locationDropDownTextField.paddingRight = 50
        } else {
            self.locationDropDownTextField.arrowSize = 15.0
            self.locationDropDownTextField.rowHeight = 40.0
            self.locationDropDownTextField.listHeight = self.locationDropDownTextField.rowHeight * 4
            self.locationDropDownTextField.paddingLeft = 12
            self.locationDropDownTextField.paddingRight = 40
        }
        self.locationDropDownTextField.didSelectCompletion = { list in
            self.locationData = list
        }
    }
    
    // MARK: - Button Action
    @IBAction func continueAction(_ sender: Any) {
        if self.dayData == nil {
            self.showAlert(text: Validation.DaySelect)
        } else if self.locationData == nil {
            self.showAlert(text: Validation.LocationSelect)
        } else {
            UserDefaultsServices.shared.saveSelectedDay(day: self.dayData?.listName ?? "")
            UserDefaultsServices.shared.saveSelectedLocation(location: self.locationData?.listName ?? "")
            if self.isFromDeviceStatus {
                if let controller = self.getViewController(storyboard: Storyboard.controlCenter, id: "ControlCenterViewController") as? ControlCenterViewController {
                    controller.isFromCamera = false
                    controller.isInit = true
                    self.present(controller, animated: true)
                }
            } else {
                if let controller = self.getViewController(storyboard: Storyboard.camera, id: "CameraViewController") as? CameraViewController {
                    controller.modalTransitionStyle = .crossDissolve
                    self.present(controller, animated: true) {
                        LocalDataService.shared.syncData()
                    }
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

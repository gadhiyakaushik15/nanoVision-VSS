//
//  LogsFiltersViewController.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 08/04/24.
//

import UIKit

protocol LogsFiltersDelegate {
    func didLogsFilters(filters: LogsFilters)
}

class LogsFiltersViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var successfulCheckBoxImageView: UIImageView!
    @IBOutlet weak var failedCheckBoxImageView: UIImageView!
    @IBOutlet weak var visitorCheckBoxImageView: UIImageView!
    @IBOutlet weak var selectedEventLabel: UILabel!
    @IBOutlet weak var applyButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    var delegate: LogsFiltersDelegate?
    var filters = LogsFilters()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configUI()
        self.setLogo()
        self.bindData()
        self.updateClearButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        LocalDataService.shared.syncCompleted = {
            DispatchQueue.main.async() {
                self.setLogo()
            }
            if Utilities.shared.isMQTTEnabled() {
                MQTTManager.shared().checkRelayChange()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        self.applyButton.cornerRadiusV = self.applyButton.frame.height / 2
        self.clearButton.cornerRadiusV = self.clearButton.frame.height / 2
    }
    
    // MARK: Config UI
    func configUI() {
        Utilities.shared.addSideRadiusWithOpacity(view: self.lineView, radius: 0, shadowRadius: 4, opacity: 1, shadowOffset: CGSize(width: 0 , height: 4), shadowColor: UIColor.black.withAlphaComponent(0.25), corners: [])
        
        if Utilities.shared.isPadDevice() {
            let config = UIImage.SymbolConfiguration(
                pointSize: 26, weight: .heavy, scale: .large)
            let image = UIImage(systemName: "arrow.backward", withConfiguration: config)
            self.backButton.setImage(image, for: .normal)
        } else {
            let config = UIImage.SymbolConfiguration(
                pointSize: 18, weight: .heavy, scale: .medium)
            let image = UIImage(systemName: "arrow.backward", withConfiguration: config)
            self.backButton.setImage(image, for: .normal)
        }
    }
    
    // MARK: Set Logo
    func setLogo() {
        self.logoImageView.image = Utilities.shared.getAppLogo()
        self.selectedEventLabel.text = Utilities.shared.getSelectedEventName()
    }
    
    func bindData() {
        if self.filters.isSuccessfulTick {
            self.successfulCheckBoxImageView.image = UIImage(named: "checkboxFill")
        } else {
            self.successfulCheckBoxImageView.image = UIImage(named: "checkboxBlank")
        }
        
        if self.filters.isFailedTick {
            self.failedCheckBoxImageView.image = UIImage(named: "checkboxFill")
        } else {
            self.failedCheckBoxImageView.image = UIImage(named: "checkboxBlank")
        }
        
        if self.filters.isVisitorTick {
            self.visitorCheckBoxImageView.image = UIImage(named: "checkboxFill")
        } else {
            self.visitorCheckBoxImageView.image = UIImage(named: "checkboxBlank")
        }
    }
    
    func updateClearButton() {
        if self.filters.isSuccessfulTick || self.filters.isFailedTick || self.filters.isVisitorTick {
            self.clearButton.backgroundColor = .blueBackgroundColor
            self.clearButton.isEnabled = true
        } else {
            self.clearButton.backgroundColor = .darkGrayBackgroundColor
            self.clearButton.isEnabled = false
        }
    }
    
    // MARK: - Button Action
    @IBAction func backAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func successfulAction(_ sender: Any) {
        self.filters.isSuccessfulTick = !self.filters.isSuccessfulTick
        if self.filters.isSuccessfulTick {
            self.successfulCheckBoxImageView.image = UIImage(named: "checkboxFill")
        } else {
            self.successfulCheckBoxImageView.image = UIImage(named: "checkboxBlank")
        }
        self.updateClearButton()
    }
    
    @IBAction func failedAction(_ sender: Any) {
        self.filters.isFailedTick = !self.filters.isFailedTick
        if self.filters.isFailedTick {
            self.failedCheckBoxImageView.image = UIImage(named: "checkboxFill")
        } else {
            self.failedCheckBoxImageView.image = UIImage(named: "checkboxBlank")
        }
        self.updateClearButton()
    }
    
    @IBAction func visitorAction(_ sender: Any) {
        self.filters.isVisitorTick = !self.filters.isVisitorTick
        if self.filters.isVisitorTick {
            self.visitorCheckBoxImageView.image = UIImage(named: "checkboxFill")
        } else {
            self.visitorCheckBoxImageView.image = UIImage(named: "checkboxBlank")
        }
        self.updateClearButton()
    }
    
    @IBAction func eventAction(_ sender: Any) {
        
    }
    
    @IBAction func applyAction(_ sender: Any) {
        self.delegate?.didLogsFilters(filters: self.filters)
        self.dismiss(animated: true)
    }
    
    @IBAction func clearAction(_ sender: Any) {
        filters = LogsFilters()
        self.bindData()
        self.updateClearButton()
    }
}

struct LogsFilters {
    var isSuccessfulTick:Bool = false
    var isFailedTick:Bool = false
    var isVisitorTick:Bool = false
}

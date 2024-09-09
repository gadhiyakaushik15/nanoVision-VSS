//
//  ControlCenterTableViewCell.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 23/04/24.
//

import UIKit
import MKToolTip

class ControlCenterTableViewCell: UITableViewCell {

    @IBOutlet weak var switchStackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var switchControl: UISwitch!
    @IBOutlet weak var valueView: UIView!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var subValueLabel: UILabel!
    @IBOutlet weak var indicatorImageView: UIImageView!
    @IBOutlet weak var switchInfoButton: UIButton!
    
    @IBOutlet weak var sliderView: UIView!
    @IBOutlet weak var sliderTitleLabel: UILabel!
    @IBOutlet weak var sliderValueLabel: UILabel!
    @IBOutlet weak var sliderMeasureTitleLabel: UILabel!
    @IBOutlet weak var sliderControl: UISlider!
    @IBOutlet weak var sliderInfoButton: UIButton!
    
    var indexPath: IndexPath?
    var data: ControlCenter?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if Utilities.shared.isPadDevice() {
            let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold, scale: .medium)
            let image = UIImage(systemName: "info.circle.fill", withConfiguration: config)
            self.switchInfoButton.setImage(image, for: .normal)
            self.sliderInfoButton.setImage(image, for: .normal)
        } else {
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold, scale: .small)
            let image = UIImage(systemName: "info.circle.fill", withConfiguration: config)
            self.switchInfoButton.setImage(image, for: .normal)
            self.sliderInfoButton.setImage(image, for: .normal)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func switchValueChangeAction(_ sender: UISwitch) {
        if let indexPath = self.indexPath, indexPath.section == 0 {
            if indexPath.row == 0 {
                UserDefaultsServices.shared.saveManualScanMode(value: sender.isOn)
            } else if indexPath.row == 1 {
                UserDefaultsServices.shared.saveLiveness(value: sender.isOn)
            } else if indexPath.row == 2 {
                UserDefaultsServices.shared.saveScanSound(value: sender.isOn)
            } else if indexPath.row == 3 {
                UserDefaultsServices.shared.saveTapScanSuccess(value: sender.isOn)
            } else if indexPath.row == 4 {
                UserDefaultsServices.shared.saveTapScanFailure(value: sender.isOn)
            }
        }
    }
    
    @IBAction func sliderValueChangeAction(_ sender: UISlider) {
        if let indexPath = self.indexPath, indexPath.section == 0, indexPath.row == 5 {
            let roundValue = Int(sender.value)
            UserDefaultsServices.shared.saveNextScanDelay(value: Float(roundValue))
            self.sliderValueLabel.text = "\((roundValue))"
            self.sliderMeasureTitleLabel.text = (roundValue > 1 ? Message.Seconds : Message.Second)
            sender.setValue(Float(roundValue), animated: false)
        }
    }
    
    @IBAction func toolTipAction(_ sender: UIButton) {
        if let data = self.data, let tips = data.tips {
            let preference = ToolTipPreferences()
            preference.drawing.bubble.gradientColors = [.lightBlueBackground, .blueBackground]
            preference.drawing.bubble.spacing = 3
            preference.drawing.bubble.cornerRadius = 8
            preference.drawing.bubble.border.width = 0
            preference.drawing.arrow.tipCornerRadius = 2
            preference.drawing.message.color = .whiteLabel
            if Utilities.shared.isPadDevice() {
                preference.drawing.bubble.inset = 25
                preference.drawing.bubble.maxWidth = self.frame.width / 2
                preference.drawing.message.font = UIFont.systemFont(ofSize: 22, weight: .medium)
            } else {
                preference.drawing.bubble.inset = 15
                preference.drawing.bubble.maxWidth = self.frame.width - 100
                preference.drawing.message.font = UIFont.systemFont(ofSize: 13, weight: .medium)
            }
            sender.showToolTip(identifier: "", message: tips , arrowPosition: .top, preferences: preference)
        }
    }
    
}

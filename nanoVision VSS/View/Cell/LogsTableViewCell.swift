//
//  LogsTableViewCell.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 30/04/24.
//

import UIKit

class LogsTableViewCell: UITableViewCell {

    @IBOutlet weak var scanTypeView: UIView!
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var eventNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

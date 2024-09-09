//
//  NoDataTableViewCell.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 03/05/24.
//

import UIKit

class NoDataTableViewCell: UITableViewCell {

    @IBOutlet weak var noDataLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

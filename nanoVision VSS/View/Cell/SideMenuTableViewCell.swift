//
//  SideMenuTableViewCell.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 29/05/24.
//

import UIKit

class SideMenuTableViewCell: UITableViewCell {

    @IBOutlet weak var sideMenuImageView: UIImageView!
    @IBOutlet weak var sideMenuTitleLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

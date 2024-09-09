//
//  ListViewTableViewCell.swift
//  nanoVision
//
//  Created by Kaushik Gadhiya on 31/05/24.
//

import UIKit

class ListViewTableViewCell: UITableViewCell {

    @IBOutlet weak var shortNameView: UIView!
    @IBOutlet weak var shortNameLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.shortNameView.cornerRadiusV = self.shortNameView.frame.height / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

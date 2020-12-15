//
//  DefaultTableViewCell.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/13/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit

class DefaultTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var detail: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

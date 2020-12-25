//
//  MenuTableViewCell.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/23/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit


class MenuCell: TableViewCellBuilder {
    var label: String
    var icon: UIImage?
    
    var onTapped: (()->())?
    
    init(label: String, icon: UIImage? = nil, onTap: (()->())? = nil) {
        self.label = label
        self.icon = icon
        self.onTapped = onTap
    }
    
    func cell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell", for: indexPath) as! MenuTableViewCell
        cell.label.text = label
        cell.icon.image = icon
        return cell
    }
    
    func registerCell(in tableView: UITableView) {
        tableView.register(UINib(nibName: "MenuTableViewCell", bundle: nil), forCellReuseIdentifier: "menuCell")
    }
}

class MenuTableViewCell: UITableViewCell {

    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var onTapped: (()->())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if let onTapped = onTapped {
            onTapped()
        }
    }

}

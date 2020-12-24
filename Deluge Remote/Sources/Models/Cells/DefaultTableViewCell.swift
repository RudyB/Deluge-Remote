//
//  DefaultTableViewCell.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/13/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit

class DefaultCell: TableViewCellBuilder {
    var label: String?
    var detail: String?
    
    init(label: String?, detail: String?) {
        self.label = label
        self.detail = detail
    }
    
    func cell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath) as! DefaultTableViewCell
        cell.label.text = label
        cell.detail.text = detail
        return cell
    }
}

class DefaultTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var detail: SelectableActiveLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

//
//  ChevronTableViewCell.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/16/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit

class ChevronCell: TVCellBuilder {
    var label: String?
    var detail: String?
    var state: ChevronTableViewCell.State
    weak var cell: ChevronTableViewCell? = nil
    
    var buttonEnabled: Bool {
        didSet {
            if let cell = cell, !buttonEnabled {
                cell.state = .Default
            }
        }
    }
    
    private var onStateChange: ((ChevronTableViewCell.State) -> ())?
    
    init(label: String?, detail: String?, state: ChevronTableViewCell.State = .Default, buttonEnabled: Bool = true, onStateChange: ((ChevronTableViewCell.State) -> ())? = nil)
    {
        self.label = label
        self.detail = detail
        self.state = state
        self.buttonEnabled = buttonEnabled
        self.onStateChange = onStateChange
    }
    
    func stateChange(state: ChevronTableViewCell.State ) {
        if state == self.state { return };
        
        self.state = state
        if let onStateChange = onStateChange {
            onStateChange(state)
        }
    }
    
    func cell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chevronRow", for: indexPath) as! ChevronTableViewCell
        cell.label.text = label
        cell.detail.text = detail
        cell.state = state
        cell.onStateChange = { [weak self] state in
            self?.stateChange(state: state)
        }
        self.cell = cell
        return cell
    }
}

class ChevronTableViewCell: UITableViewCell {

    enum State {
        case Default
        case Expanded
        
        var image: UIImage {
            switch self {
                case .Default:
                    return UIImage(systemName: "chevron.right")!
                case .Expanded:
                     return UIImage(systemName: "chevron.down")!
            }
        }
        
        mutating func toggle() {
            switch self {
                case .Default:
                    self = .Expanded
                case .Expanded:
                    self = .Default
            }
        }
    }
    
    fileprivate var onStateChange: ((State)->())?
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var detail: UILabel!
    @IBOutlet weak var action: UIButton!
    
    var state: State = .Default {
        didSet {
            updateActionImage()
            if let onStateChange = onStateChange {
                onStateChange(state)
            }
        }
    }
    
    @IBAction func actionPressed(_ sender: Any) {
        state.toggle()
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateActionImage()
    }
    
    func updateActionImage() {
        if self.action.image(for: .normal) == state.image { return }
        UIView.transition( with: action, duration: 0.25, options: .transitionFlipFromRight) { [weak self] in
            self?.action.setImage(self?.state.image, for: .normal)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

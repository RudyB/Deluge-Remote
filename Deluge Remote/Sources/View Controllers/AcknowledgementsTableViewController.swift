//
//  AcknowledgementsTableViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/24/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit


class AcknowledgementsTableViewController: UITableViewController {
    
    let model = AcknowledgementsTableViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Acknowledgements"
        model.registerCells(in: tableView)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return model.sectionCount
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.rowCount(for: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return model.cell(for: tableView, at: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        model.didSelectRow(in: tableView, at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}

fileprivate class MainSection: TableViewSection {
    
    init() {
        super.init()
        
        cells = [
            MenuCell(label: "Alamofire", icon: UIImage(named: "menu/github"))
                { UIApplication.shared.open(URL(string: "https://github.com/Alamofire/Alamofire")!)},
            
            MenuCell(label: "ActiveLabel", icon: UIImage(named: "menu/github"))
                { UIApplication.shared.open(URL(string: "https://github.com/optonaut/ActiveLabel.swift")!)},
            
            MenuCell(label: "BarMagnet", icon: UIImage(named: "menu/github"))
                { UIApplication.shared.open(URL(string: "https://github.com/Qata/BarMagnet")!)},
            
            MenuCell(label: "Eureka", icon: UIImage(named: "menu/github"))
                { UIApplication.shared.open(URL(string: "https://github.com/xmartlabs/Eureka")!)},
            
            MenuCell(label: "ExpandableCollectionViewKit", icon: UIImage(named: "menu/github"))
                { UIApplication.shared.open(URL(string: "https://github.com/jVirus/expandable-collection-view-kit")!)},
            
            MenuCell(label: "Houston", icon: UIImage(named: "menu/github"))
                { UIApplication.shared.open(URL(string: "https://github.com/RudyB/Houston")!)},
            
            MenuCell(label: "IQKeyboardManager", icon: UIImage(named: "menu/github"))
                { UIApplication.shared.open(URL(string: "https://github.com/hackiftekhar/IQKeyboardManager")!)},
            
            MenuCell(label: "MBProgressHUD", icon: UIImage(named: "menu/github"))
                { UIApplication.shared.open(URL(string: "https://github.com/jdg/MBProgressHUD")!)},
            
            MenuCell(label: "NotificationBanner", icon: UIImage(named: "menu/github"))
                { UIApplication.shared.open(URL(string: "https://github.com/Daltron/NotificationBanner")!)},
            
            MenuCell(label: "PromiseKit", icon: UIImage(named: "menu/github"))
                { UIApplication.shared.open(URL(string: "https://github.com/mxcl/PromiseKit")!)},
            
            MenuCell(label: "SwipeableTabBarController", icon: UIImage(named: "menu/github"))
                { UIApplication.shared.open(URL(string: "https://github.com/marcosgriselli/SwipeableTabBarController")!)},
            
            MenuCell(label: "Valet", icon: UIImage(named: "menu/github"))
                { UIApplication.shared.open(URL(string: "https://github.com/square/Valet")!)}
            
        ].sorted {$0.label < $1.label}
    }
    
    override func didSelectRow(in tableView: UITableView, at indexPath: IndexPath) {
        if let builder = cells[indexPath.row] as? MenuCell,
           let onTappedAction = builder.onTapped {
            onTappedAction()
        }
    }
    
}

class AcknowledgementsTableViewModel: TableViewModel {

    override init() {
        super.init()
        sections = [MainSection()]
    }
    
}

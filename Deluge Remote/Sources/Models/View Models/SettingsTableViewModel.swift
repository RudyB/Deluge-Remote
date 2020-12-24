//
//  SettingsTableViewModel.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/23/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit
import Houston

class SettingsTableViewModel: TableViewModel {
    
    var sections: [TableViewSection] = [SettingsSection(),AboutSection()]
    
    weak var delegate: SettingsViewControllerDelegate? {
        didSet {
            sections.forEach {
                if let section = $0 as? SettingsTableViewSection {
                    section.delegate = delegate
                }
            }
        }
    }
    
    var sectionCount: Int {
        return sections.count
    }
    
    func updateModel() {}
    
    func rowCount(for section: Int) -> Int {
        if section > sectionCount {
            return 0
        } else {
            return sections[section].rowsCount()
        }
    }
    
    func sectionHeaderTitle(for section: Int) -> String? {
        if section > sectionCount {
            return nil
        } else {
            return sections[section].titleForHeader()
        }
    }
    
    func cell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        return sections[indexPath.section].cell(for: tableView, at: indexPath)
    }
    
    func didSelectRow(in tableView: UITableView, at indexPath: IndexPath) {
        sections[indexPath.section].didSelectRow(in: tableView, at: indexPath)
    }
}

class SettingsTableViewSection : TableViewSection {
    
    weak var delegate: SettingsViewControllerDelegate?
    
    override func didSelectRow(in tableView: UITableView, at indexPath: IndexPath) {
        if let builder = cells[indexPath.row] as? MenuCell,
           let onTappedAction = builder.onTapped {
            onTappedAction()
        }
    }
}

class SettingsSection : SettingsTableViewSection {
    
    override func titleForHeader() -> String? {
        return "Settings"
    }
    
    init() {
        super.init()
        
        let clients = MenuCell(label: "Deluge Clients", icon: UIImage(named: "menu/server")!) { [weak self] in
            self?.delegate?.showClientsView()
        }
        
        cells.append(clients)
    }
}

class AboutSection: SettingsTableViewSection {
    
    override func titleForHeader() -> String? {
        return "About"
    }
    
    init() {
        super.init()
        
        let twitter = MenuCell(label: "@RudyBermudez", icon: UIImage(named: "menu/twitter")!) {
            UIApplication.shared.open(URL(string: "https://twitter.com/RudyBermudez")!)
        }
        let github = MenuCell(label: "@RudyB", icon: UIImage(named: "menu/github")!) {
            UIApplication.shared.open(URL(string: "https://github.com/RudyB")!)
        }
        let donation = MenuCell(label: "Donate", icon: UIImage(named: "menu/donate")!) {
            UIApplication.shared.open(URL(string: "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=A4G2L5EHNCD24&currency_code=USD")!)
        }
        let acknowledgements = MenuCell(label: "Acknowledgements", icon: UIImage(named: "menu/acknowledgements")!) { [weak self] in
            self?.delegate?.showAcknowledgementsView()
        }
        let bugReports = MenuCell(label: "Bug Reports / Feature Requests", icon: UIImage(named: "menu/bug")!) {
            UIApplication.shared.open(URL(string: "https://github.com/RudyB/Deluge-Remote/issues/")!)
        }
        let logs = MenuCell(label: "Logs", icon: UIImage(named: "menu/logs")!) { [weak self] in
            self?.delegate?.exportLogs()
        }
        
        cells.append(twitter)
        cells.append(github)
        cells.append(donation)
        cells.append(acknowledgements)
        cells.append(bugReports)
        cells.append(logs)
    
    }
    
}


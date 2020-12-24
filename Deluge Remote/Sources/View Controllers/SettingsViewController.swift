//
//  SettingsViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/23/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit

protocol SettingsViewControllerDelegate: AnyObject {
    func showClientsView()
    func showAcknowledgementsView()
    func exportLogs()
}

class SettingsViewController: UIViewController, Storyboarded {

    @IBOutlet weak var AppName: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    let model = SettingsTableViewModel()
    weak var delegate: SettingsViewControllerDelegate? {
        didSet {
            model.delegate = delegate
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        AppName.text = "Deluge Remote \(Bundle.main.releaseVersionNumberPretty)"
    }

}

// MARK: - Table view data source
extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    

    func numberOfSections(in tableView: UITableView) -> Int {
        return model.sectionCount
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.rowCount(for: section)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return model.sectionHeaderTitle(for: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return model.cell(for: tableView, at: indexPath)
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        model.didSelectRow(in: tableView, at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

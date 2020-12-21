//
//  TorrentInfoTabTableViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/13/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit

class TorrentInfoTableViewController: UITableViewController, Storyboarded {

    // MARK: - Properties
    let hapticEngine = UINotificationFeedbackGenerator()
    
    let model = TorrentInfoModel()
    
    var torrentData: TorrentMetadata? {
        didSet {
            model.torrent = torrentData
            tableView.reloadData()
        }
    }
    
    // MARK: UIViewController Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.onRowsAdded = { [weak self] indexPaths in
            self?.tableView.beginUpdates()
            self?.tableView.insertRows(at: indexPaths, with: .automatic)
            self?.tableView.endUpdates()
        }
        
        model.onRowsRemoved = { [weak self] indexPaths in
            self?.tableView.beginUpdates()
            self?.tableView.deleteRows(at: indexPaths, with: .automatic)
            self?.tableView.endUpdates()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return model.sectionCount
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.rowCount(for: section)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return model.sectionHeaderTitle(for: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return model.cell(for: tableView, at: indexPath)
    }
    
}

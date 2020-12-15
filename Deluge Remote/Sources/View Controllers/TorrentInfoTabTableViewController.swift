//
//  TorrentInfoTabTableViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/13/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit

class TorrentInfoTabTableViewController: UITableViewController, Storyboarded {

    // MARK: - Properties
    let hapticEngine = UINotificationFeedbackGenerator()
    var model = TorrentInfoModel()
    var torrentData: TorrentMetadata? {
        didSet {
            model.torrent = torrentData
            tableView.reloadData()
        }
    }
    
    
    
    // MARK: UIViewController Methods
    override func viewDidLoad() {
        super.viewDidLoad()

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

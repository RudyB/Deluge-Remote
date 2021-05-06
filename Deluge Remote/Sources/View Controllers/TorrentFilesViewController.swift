//
//  TorrentFilesViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/21/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit
import ExpandableCollectionViewKit

class TorrentFilesViewController: UIViewController, Storyboarded {

    // MARK: - Properties
    var torrentFileStructure: TorrentFileStructure? {
        didSet {
            displayTorrentFiles()
        }
    }
    var filesLoaded = false;
    var expVCManager: ExpandableCollectionViewManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func displayTorrentFiles() {
        guard let subFiles = torrentFileStructure?.files else { return }
        if !filesLoaded {
            expVCManager = ExpandableCollectionViewManager(parentViewController: self) { subFiles.toExpandableItems() }
            filesLoaded = true
        }
        
    }

}

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
    var torrentFileStructure: TorrentFileStructure?
    lazy var expVCManager: ExpandableCollectionViewManager = {
        return ExpandableCollectionViewManager(parentViewController: self)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for file in torrentFileStructure?.files {
            
        }
        
    }

}

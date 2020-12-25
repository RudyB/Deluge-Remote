//
//  TorrentDetailViewTabController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/13/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit
import Houston

protocol TorrentDetailViewDelegate: AnyObject
{
    func removeTorrent(with hash: String, removeData: Bool, onCompletion: ((_ onServerComplete: APIResult<Void>, _ onClientComplete: @escaping ()->())->())?)
}

class TorrentDetailViewTabController: UITabBarController, Storyboarded {
    
    // MARK: - Lazy Computed Properties
    lazy fileprivate var infoVC: TorrentInfoTableViewController = {
        let vc = TorrentInfoTableViewController.instantiate()
        vc.tabBarItem = UITabBarItem(
            title: "Info",
            image: UIImage(systemName: "doc.plaintext"),
            selectedImage: UIImage(systemName: "doc.plaintext.filled"))
        return vc
    }()
    
    lazy fileprivate var filesVC: TorrentFilesViewController = {
        let vc = TorrentFilesViewController.instantiate()
        vc.tabBarItem = UITabBarItem(
            title: "Files",
            image: UIImage(systemName: "folder"),
            selectedImage: UIImage(systemName: "folder.filled"))
        
        return vc
    }()
    
    lazy fileprivate var optionsVC: TorrentOptionsViewController = {
        let vc = TorrentOptionsViewController()
        vc.delegate = dataDelegate
        vc.tabBarItem = UITabBarItem(
            title: "Options",
            image: UIImage(systemName: "gearshape.2"),
            selectedImage: UIImage(systemName: "gearshape.2.filled"))
        return vc
    }()
    
    // MARK: - Properties
    var torrentData: TorrentMetadata? {
        didSet {
            infoVC.torrentData = torrentData
            optionsVC.torrentData = torrentData
        }
    }
    
    var torrentFileStructure: TorrentFileStructure? {
        didSet {
            filesVC.torrentFileStructure = torrentFileStructure
        }
    }
    var torrentHash: String?
    weak var dataDelegate: TorrentDetailViewDelegate?
    var dataPollingQueue: DispatchQueue?
    var dataPollingTimer: RepeatingTimer?
    
    
    // MARK: - UIViewController Methods
    deinit {
        filesVC.expVCManager = nil
        Logger.debug("Destroyed")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        
        dataPollingQueue =  DispatchQueue(label: "io.rudybermudez.Deluge-Remote.DetailDataView.PollingQueue", qos: .userInteractive)
        dataPollingTimer = RepeatingTimer(timeInterval: .seconds(3), leeway: .seconds(1), queue: dataPollingQueue)
        dataPollingTimer?.eventHandler = dataPollingEvent
        
        dataPollingQueue?.async { [weak self] in self?.dataPollingEvent() }
        dataPollingTimer?.resume()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        viewControllers = [infoVC, filesVC, optionsVC]
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        dataPollingTimer?.suspend()
        dataPollingTimer = nil
    }
    
    // MARK: - Data Updating Methods
    
    func dataPollingEvent() {
        guard let torrentHash = torrentHash else { return }
        getTorrentData(withHash: torrentHash)
        
        if torrentFileStructure == nil {
            getTorrentFiles(withHash: torrentHash)
        }
        
    }
    
    func getTorrentData(withHash hash: String) {
        ClientManager.shared.activeClient?.getTorrentDetails(withHash: hash)
            .done { [weak self] torrent in
                Logger.verbose("New Data")
                self?.torrentData = torrent
                self?.title = torrent.name
            }.catch { [weak self] error in
                Logger.error(error)
                if let self = self, let error = error as? ClientError {
                    showAlert(target: self, title: "Error", message: error.domain(),
                              style: .alert)
                }
            }
    }
        
    func getTorrentFiles(withHash hash: String) {
        ClientManager.shared.activeClient?.getTorrentFiles(withHash: hash)
            .done { [weak self] fileStructure in
                self?.torrentFileStructure = fileStructure
                self?.filesVC.tabBarItem.isEnabled = true
            }.catch { [weak self] error in
                Logger.error(error)
                guard
                    let self = self,
                    let error = error as? ClientError
                else { return }
                if case .torrentHasNoFiles = error {
                    self.filesVC.tabBarItem.isEnabled = false
                } else {
                    showAlert(target: self, title: "Error", message: error.domain(),
                              style: .alert)
                }
            }
    }
    
}

// MARK: - UITabBarControllerDelegate
extension TorrentDetailViewTabController: UITabBarControllerDelegate {
    
}

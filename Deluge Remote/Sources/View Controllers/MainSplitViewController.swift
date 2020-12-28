//
//  MainSplitViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/11/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit
import MessageUI

// MARK: MainSplitViewController
class MainSplitViewController: UISplitViewController {
    
    // MARK: Properties
    var master: UINavigationController!
    var detail: UINavigationController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        self.preferredDisplayMode = .allVisible
        
        let mainView = MainTableViewController.instantiate()
        mainView.delegate = self
        
        master = UINavigationController(rootViewController: mainView)
        master.setToolbarHidden(false, animated: false)
        
        detail = UINavigationController(rootViewController: PlaceholderViewController.instantiate())
 
        self.viewControllers = [master,detail]
    }
    
    func showTorrentDetailView(_ torrentHash: String? = nil)
    {
        if let detailViewController = detail.viewControllers.first as? TorrentDetailViewTabController {
            // If the detail View controller is already being shown with the desired hash
            if detailViewController.torrentHash == torrentHash { return }
        }
        
        let vc = TorrentDetailViewTabController.instantiate()
        vc.dataDelegate = self
        vc.torrentHash = torrentHash
        vc.hidesBottomBarWhenPushed = true
        vc.navigationItem.leftBarButtonItem = displayModeButtonItem
        vc.navigationItem.leftItemsSupplementBackButton = true
        showDetailViewController(vc, sender: nil)
    }
    
    
}

// MARK: - MainTableViewControllerDelegate
extension MainSplitViewController: MainTableViewControllerDelegate
{
    func removeTorrent(with hash: String, removeData: Bool, onCompletion: ((Result<Void, Error>, @escaping () -> ()) -> ())?) {
        suspendDetailViewDataPolling()
        ClientManager.shared.activeClient?.removeTorrent(withHash: hash, removeData: removeData)
            .done { [weak self] _ in 
                if let onCompletion = onCompletion {
                    onCompletion(.success(())) { [weak self] in
                        self?.updateDetailViewAfterDeletion()
                    }
                }
            }.catch() { [weak self] error in
                self?.resumeDetailViewDataPolling()
                if let onCompletion = onCompletion {
                    onCompletion(.failure(error)) { [weak self] in
                        self?.updateDetailViewAfterDeletion()
                    }
                }
            }
    }

    func torrentSelected(torrentHash: String) {
        showTorrentDetailView(torrentHash)
    }
    
    func showAddTorrentView()
    {
        let vc = AddTorrentViewController.instantiate()
        vc.delegate = self
        master.pushViewController(vc, animated: true)
    }
    
    func showSettingsView() {
        let vc = SettingsViewController.instantiate()
        vc.delegate = self
        master.pushViewController(vc, animated: true)
    }
}

// MARK: - DetailedTorrentViewDelegate
extension MainSplitViewController: TorrentDetailViewDelegate
{
    func updateDetailViewAfterDeletion()
    {
        if isCollapsed {
            if master.topViewController is TorrentDetailViewTabController {
                master.popViewController(animated: true)
            }
        } else {
            showDetailViewController(PlaceholderViewController.instantiate(), sender: nil)
        }
    }
    
    func suspendDetailViewDataPolling() {
        if isCollapsed {
            if let detailVC = master.topViewController as? TorrentDetailViewTabController {
                detailVC.dataPollingTimer?.suspend()
            }
        } else {
            if let detailVC = detail.topViewController as? TorrentDetailViewTabController {
                detailVC.dataPollingTimer?.suspend()
            }
        }
    }
    
    func resumeDetailViewDataPolling() {
        if isCollapsed {
            if let detailVC = master.topViewController as? TorrentDetailViewTabController {
                detailVC.dataPollingTimer?.resume()
            }
        } else {
            if let detailVC = detail.topViewController as? TorrentDetailViewTabController {
                detailVC.dataPollingTimer?.resume()
            }
        }
    }
}

// MARK: - AddTorrentViewControllerDelegate
extension MainSplitViewController: AddTorrentViewControllerDelegate
{
    func torrentAdded(_ torrentHash: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Pop Add Torrent View Controller from the navigation stack
//            if self.master.viewControllers.first is AddTorrentViewController {
//                self.master.popViewController(animated: true)
//            }
//
//            if self.master.viewControllers.first is TorrentDetailViewTabController {
//                self.master.popViewController(animated: true)
//            }
            self.master.popToRootViewController(animated: true)
            
            // Now tell the MainTableaViewController to animated to the newly selected hash
            if let mainViewController = self.master.viewControllers.first as? MainTableViewController {
                mainViewController.selectedHash = torrentHash
                mainViewController.animateToSelectedHash = true
            }

            // Finally, show the Detail View
            self.showTorrentDetailView(torrentHash)
        }
    }
}

// MARK: - ClientsTableViewControllerDelegate
extension MainSplitViewController: ClientsTableViewControllerDelegate
{
    func showAddClientVC(with config: ClientConfig?, onConfigAdded: @escaping (ClientConfig) -> ()) {
        let vc = AddClientViewController.instantiate()
        vc.config = config
        vc.onConfigAdded = onConfigAdded
        master.pushViewController(vc, animated: true)
    }
    
}

extension MainSplitViewController: SettingsViewControllerDelegate {
    
    func exportLogs() {
        guard
            let settingsVC = master.topViewController as? SettingsViewController
        else { return }
        
        var actions: [UIAlertAction] = []
        
        if MFMailComposeViewController.canSendMail() {
            let emailAction = UIAlertAction(title: "Email", style: .default) { [weak self] _ in
                
                let mail = MFMailComposeViewController()
                mail.setToRecipients(["hello@rudybermudez.io"])
                mail.setSubject("[Deluge Remote \(Bundle.main.releaseVersionNumberPretty) Logs]")
                mail.setMessageBody("Please describe the issue you're having (why your're sending these logs)", isHTML: true)
                mail.mailComposeDelegate = self
                //add attachment
                let url = getLogFile()
                if let data = try? Data(contentsOf: url){
                    mail.addAttachmentData(data as Data, mimeType: "text/plain" , fileName: url.lastPathComponent)
                }
                self?.present(mail, animated: true)
            }
            actions.append(emailAction)
        }

        let shareAction = UIAlertAction(title: "Share", style: .default) { [weak self] _ in
            let activity = UIActivityViewController(
                activityItems: ["You can send to the email address hello@rudybermudez.io Please make sure you include details about the issue and why you're sending the logs", getLogFile()],
                applicationActivities: nil
              )
            self?.present(activity, animated: true, completion: nil)
        }
        actions.append(shareAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        actions.append(cancelAction)
        
        showAlert(target: settingsVC, title: "Deluge Remote Logs", style: .actionSheet, actionList: actions)
    }
    
    
    func showAcknowledgementsView() {
        let vc = AcknowledgementsTableViewController()
        master.pushViewController(vc, animated: true)
    }
    
    func showClientsView()
    {
        let vc = ClientsTableViewController.instantiate()
        vc.delegate = self
        master.pushViewController(vc, animated: true)
    }
}

// MARK: - MFMailComposeViewControllerDelegate
extension MainSplitViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        if let _ = error {
              self.dismiss(animated: true, completion: nil)
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - TorrentHandler
extension MainSplitViewController: TorrentHandler
{
    func addTorrent(from data: TorrentData) {
        let vc = AddTorrentViewController.instantiate()
        vc.delegate = self
        vc.torrentData = data
        vc.torrentType = data.type
        master.pushViewController(vc, animated: true)
    }
    
}

// MARK: - UISplitViewControllerDelegate
extension MainSplitViewController: UISplitViewControllerDelegate
{
    func splitViewController(_ svc: UISplitViewController, willShow vc: UIViewController, invalidating barButtonItem: UIBarButtonItem) {
        if let detailView = svc.viewControllers.first as? UINavigationController {
            svc.navigationItem.backBarButtonItem = nil
            detailView.topViewController?.navigationItem.leftBarButtonItem = nil
        }
    }

    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        
        guard
            let masterNavigationController = primaryViewController as? UINavigationController,
            let detailNavigationController = secondaryViewController as? UINavigationController,
            let detailViewController = detailNavigationController.viewControllers.first as? TorrentDetailViewTabController
        else {
            return true
        }
        
        if detailViewController.torrentHash == nil
        {
            // detail view is blank. We do not need to push this onto the master
            return true
        }
        
        var newMasterViewControllers = masterNavigationController.viewControllers
        newMasterViewControllers.append(contentsOf: detailNavigationController.viewControllers)
        masterNavigationController.setViewControllers(newMasterViewControllers, animated: false)
        return true
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        
        let masterNavigationViewController = primaryViewController as? UINavigationController

        var newMasterViewControllers = [UIViewController]()
        var newDetailViewControllers = [UIViewController]()

        for vc in masterNavigationViewController?.viewControllers ?? [] {
            if vc is TorrentDetailViewTabController {
                newDetailViewControllers.append(vc)
            } else {
                newMasterViewControllers.append(vc)
            }
        }

        if newDetailViewControllers.isEmpty {
            newDetailViewControllers.append(PlaceholderViewController.instantiate())
        }

        master.setViewControllers(newMasterViewControllers, animated: false)
        detail.setViewControllers(newDetailViewControllers, animated: false)
        return detail
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        if isCollapsed {
            master.pushViewController(vc, animated: true)
        } else {
            detail.setViewControllers([vc], animated: true)
        }
        return true
    }
    
    
}

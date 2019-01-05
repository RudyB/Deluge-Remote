//
//  DetailedTorrentViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 11/12/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import Eureka
import UIKit

class DetailedTorrentViewController: FormViewController {

    @IBOutlet weak var deleteItem: UIBarButtonItem!
    @IBOutlet weak var playPauseItem: UIBarButtonItem!

    @IBAction func deleteAction(_ sender: UIBarButtonItem) {

        let deleteTorrent = UIAlertAction(title: "Delete Torrent", style: .destructive) { [weak self] _ in
            self?.invalidateTimer()
            guard let self = self, let torrentHash = self.torrentHash else { return }
            ClientManager.shared.activeClient?.removeTorrent(withHash: torrentHash, removeData: false).then {_ in
                self.navigationController?.popViewController(animated: true)
                }.catch { error in
                    if let error = error as? ClientError {
                        showAlert(target: self, title: "Error", message: error.domain())
                    } else {
                        showAlert(target: self, title: "Error", message: error.localizedDescription)
                    }
            }
        }

        let deleteTorrentWithData = UIAlertAction(title: "Delete Torrent with Data", style: .destructive) { [weak self] _ in
            self?.invalidateTimer()
            guard let self = self, let torrentHash = self.torrentHash else { return }
            ClientManager.shared.activeClient?.removeTorrent(withHash: torrentHash, removeData: true).then {_ in
                self.navigationController?.popViewController(animated: true)
                }.catch { error in
                    if let error = error as? ClientError {
                        showAlert(target: self, title: "Error", message: error.domain())
                    } else {
                        showAlert(target: self, title: "Error", message: error.localizedDescription)
                    }
            }
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel)

        showAlert(target: self, title: "Remove the torrent?", style: .actionSheet,
                  actionList: [deleteTorrent, deleteTorrentWithData, cancel])
    }

    @IBAction func playPauseAction(_ sender: UIBarButtonItem) {
        guard let torrentData = torrentData else { return }

        if torrentData.paused {
            ClientManager.shared.activeClient?.resumeTorrent(withHash: torrentData.hash) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        UIView.animate(withDuration: 1.0) {
                            self.playPauseItem.image = #imageLiteral(resourceName: "icons8-pause")
                        }

                    case .failure:
                        showAlert(target: self, title: "Failed To Resume Torrent")
                    }
                }

            }
        } else {
            ClientManager.shared.activeClient?.pauseTorrent(withHash: torrentData.hash) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        UIView.animate(withDuration: 1.0) {
                            self.playPauseItem.image = #imageLiteral(resourceName: "play_filled")
                        }

                    case .failure:
                        showAlert(target: self, title: "Failed to Pause Torrent")
                    }
                }
            }
        }

    }

    var torrentData: TorrentMetadata?
    var torrentHash: String?

    var refreshTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Details"
        // Do any additional setup after loading the view.

        if let torrentHash = torrentHash {
            getTorrentData(withHash: torrentHash)
        }
        // Begin Data Download
        createNewTimer()

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44.0
        // Create Form
        createBasicInfoSection()
        createAdditionalInfoSection()
        createTorrentOptionsSection()
    }

    override func viewWillDisappear(_ animated: Bool) {
        invalidateTimer()
    }

    func computeCellHeight(for cell: LabelCell)  -> () -> CGFloat {
        if cell.detailTextLabel!.bounds.height <= 44 {
            return { return CGFloat(44) }
        } else {
            return { cell.detailTextLabel!.bounds.height + 25 }
        }
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func createBasicInfoSection() {
        form +++ Section("Basic Info")
            <<< LabelRow {
                $0.title = "State"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.value = torrentData.state
                }
                }.cellUpdate { [weak self] cell, row in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.state
                        cell.height = self?.computeCellHeight(for: cell)
                        row.section?.header?.title = torrentData.name
                        print("Reloaded TableView")
                        if let etaRow = self?.form.rowBy(tag: "ETA") as? LabelRow {
                            etaRow.hidden = Condition(booleanLiteral: torrentData.eta == 0)
                            if etaRow.isHidden != (torrentData.eta == 0) {
                                etaRow.evaluateHidden()
                                self?.tableView.reloadData()
                            }
                        }
                    }
            }
            <<< LabelRow {
                $0.title = "ETA"
                $0.tag = "ETA"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = torrentData.eta.timeRemainingString()
                    $0.cell.detailTextLabel?.numberOfLines = 0
                    $0.hidden = Condition(booleanLiteral: torrentData.eta == 0)
                } else {
                    $0.hidden = Condition(booleanLiteral: true)
                }

                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.eta.timeRemainingString()
                        cell.height = self?.computeCellHeight(for: cell)
                    }

            }
            <<< LabelRow {
                $0.title = "Completed"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = String(format: "%.1f%%", torrentData.progress)
                }

                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = String(format: "%.1f%%", torrentData.progress)
                        cell.height = self?.computeCellHeight(for: cell)
                    }

            }
            <<< LabelRow {
                $0.title = "Size"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = torrentData.total_size.sizeString()
                }
                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.total_size.sizeString()
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }
            <<< LabelRow {
                $0.title = "Downloaded"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = torrentData.all_time_download.sizeString()
                }

                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.all_time_download.sizeString()
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }
            <<< LabelRow {
                $0.title = "Uploaded"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = torrentData.total_uploaded.sizeString()
                }

                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.total_uploaded.sizeString()
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }
            <<< LabelRow {
                $0.title = "Ratio"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = String(format: "%.3f", torrentData.ratio)
                }

                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = String(format: "%.3f", torrentData.ratio)
                        cell.height = self?.computeCellHeight(for: cell)
                    }
        }

    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func createAdditionalInfoSection() {
        form +++ Section("Additional Info") {
            $0.tag = "AdditionalInfo"
            }

            <<< LabelRow {
                $0.title = "Status"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = torrentData.message
                }

                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.message
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }
            <<< LabelRow {
                $0.title = "Down Speed"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = torrentData.download_payload_rate.transferRateString()
                }

                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.download_payload_rate.transferRateString()
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }
            <<< LabelRow {
                $0.title = "Up Speed"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = torrentData.upload_payload_rate.transferRateString()
                }

                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.upload_payload_rate.transferRateString()
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }
            <<< LabelRow {
                $0.title = "Seeds Connected"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = "\(torrentData.num_seeds) (\(torrentData.total_seeds))"
                }
                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = "\(torrentData.num_seeds) (\(torrentData.total_seeds))"
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }
            <<< LabelRow {
                $0.title = "Peers Connected"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = "\(torrentData.num_peers) (\(torrentData.total_peers))"
                }
                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = "\(torrentData.num_peers) (\(torrentData.total_peers))"
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }
            <<< LabelRow {
                $0.title = "Path"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = torrentData.save_path
                }
                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.save_path
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }
            <<< LabelRow {
                $0.title = "Tracker"
                $0.cell.detailTextLabel?.numberOfLines = 0

                if let torrentData = self.torrentData {
                    if let tracker = URL(string: torrentData.tracker) {
                        $0.cell.detailTextLabel?.text = tracker.host
                    } else {
                        if let url = torrentData.trackers.first?.url,
                            let tracker = URL(string: url) {
                            $0.cell.detailTextLabel?.text = tracker.host
                        } else {
                            $0.cell.detailTextLabel?.text = ""
                        }
                    }
                }
                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        if let tracker = URL(string: torrentData.tracker) {
                            cell.detailTextLabel?.text = tracker.host
                        } else {
                            if let url = torrentData.trackers.first?.url,
                                let tracker = URL(string: url) {
                                cell.detailTextLabel?.text = tracker.host
                            } else {
                                cell.detailTextLabel?.text = ""
                            }
                        }
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }
            <<< LabelRow {
                $0.title = "Active Time"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    let formatter = DateComponentsFormatter()
                    formatter.allowedUnits = [.month, .day, .hour, .minute]
                    formatter.unitsStyle = .abbreviated
                    $0.cell.detailTextLabel?.text = formatter.string(from: TimeInterval(torrentData.active_time))
                }
                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        let formatter = DateComponentsFormatter()
                        formatter.allowedUnits = [.month, .day, .hour, .minute]
                        formatter.unitsStyle = .abbreviated
                        cell.detailTextLabel?.text = formatter.string(from: TimeInterval(torrentData.active_time))
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }

            <<< LabelRow {
                $0.title = "Date Added"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM/dd/yyyy h:mm a"
                    $0.cell.detailTextLabel?.text =
                        formatter.string(from: Date(timeIntervalSince1970: torrentData.time_added))
                }
                }.cellUpdate { [weak self] cell, _ in

                    if let torrentData = self?.torrentData {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MM/dd/yyyy h:mm a"
                        cell.detailTextLabel?.text =
                            formatter.string(from: Date(timeIntervalSince1970: torrentData.time_added))
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }
            <<< LabelRow {
                $0.title = "Comments"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = torrentData.comment
                }
                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.comment
                        cell.height = self?.computeCellHeight(for: cell)
                        }
                }

    }

    func createTorrentOptionsSection() {
        form +++ Section("Torrent Options") {
            $0.header?.height = {return CGFloat(20.0)}
        }
            <<< IntRow {
                $0.title = "Max Download Speed"
                $0.cell.textField.text = "\(Int(torrentData?.max_download_speed ?? -1))"
                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        if !cell.row.wasChanged {
                            cell.textField.text = "\(Int(torrentData.max_download_speed))"
                        }
                    }

                }
            <<< IntRow {
                $0.title  = "Max Upload Speed"
                $0.cell.textField.text = "\(Int(torrentData?.max_upload_speed ?? -1))"
                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        if !cell.row.wasChanged {
                            cell.textField.text = "\(Int(torrentData.max_download_speed))"
                        }
                    }
        }
            <<< IntRow {
                $0.title  = "Max Connections"
                $0.value = torrentData?.max_connections
                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        if !cell.row.wasChanged {
                            cell.textField.text = "\(torrentData.max_connections)"
                        }
                    }
        }

            <<< IntRow {
                $0.title  = "Max Upload Slots"
                $0.value = torrentData?.max_upload_slots
                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        if !cell.row.wasChanged {
                            cell.textField.text = "\(torrentData.max_upload_slots)"
                        }
                    }
        }

    }

    func createNewTimer() {
        print("Created New Timer in DetailTorrentVC")
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) {[weak self] _ in
            guard let torrentHash = self?.torrentHash else { return }
            self?.getTorrentData(withHash: torrentHash)
        }
    }

    func invalidateTimer() {
        refreshTimer?.invalidate()
        print("Invalidated Timer in DetailTorrentVC")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getTorrentData(withHash hash: String) {
        ClientManager.shared.activeClient?.getTorrentDetails(withHash: hash).then { torrent -> Void in
            DispatchQueue.main.async {
                print("New Detail VC Data")
                self.torrentData = torrent
                self.playPauseItem.image = torrent.paused ?  #imageLiteral(resourceName: "play_filled") : #imageLiteral(resourceName: "icons8-pause")
                //self.form.allSections.forEach { $0.reload() }
                self.tableView.reloadData()
                //self.form.sectionBy(tag: "BasicInfo")?.reload()
                //self.form.sectionBy(tag: "AdditionalInfo")?.reload()

            }
            }.catch { error in
                if let error = error as? ClientError {
                    let okButton = UIAlertAction(title: "Bummer", style: .default) { _ in
                        self.navigationController?.popViewController(animated: true)
                    }
                    showAlert(target: self, title: "Error", message: error.domain(),
                              style: .alert, actionList: [okButton])

                }
        }
    }

}

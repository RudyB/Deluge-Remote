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

        let deleteTorrent = UIAlertAction(title: "Delete Torrent", style: .destructive) { _ in
            self.invalidateTimer()
            ClientManager.shared.activeClient?.removeTorrent(withHash: self.torrentHash!, removeData: false).then {_ in
                self.navigationController?.popViewController(animated: true)
                }.catch { error in
                    if let error = error as? ClientError {
                        showAlert(target: self, title: "Error", message: error.domain())
                    } else {
                        showAlert(target: self, title: "Error", message: error.localizedDescription)
                    }
            }
        }

        let deleteTorrentWithData = UIAlertAction(title: "Delete Torrent with Data", style: .destructive) { _ in
            self.invalidateTimer()
            ClientManager.shared.activeClient?.removeTorrent(withHash: self.torrentHash!, removeData: true).then {_ in
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

        // Create Form
        createForm()

    }

    override func viewWillDisappear(_ animated: Bool) {
        invalidateTimer()
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func createForm() {
        form +++ Section("Basic Info")
            <<< LabelRow {
                $0.title = "State"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.value = torrentData.state
                }

                }.cellUpdate { cell, row in
                    if let torrentData = self.torrentData {
                        cell.detailTextLabel?.text = torrentData.state
                        row.section?.header?.title = torrentData.name
                        print("Reloaded TableView")
                        if let etaRow = self.form.rowBy(tag: "ETA") as? LabelRow {
                            etaRow.hidden = Condition(booleanLiteral: torrentData.eta == 0)
                            if etaRow.isHidden != (torrentData.eta == 0) {
                                etaRow.evaluateHidden()
                                self.tableView.reloadData()
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

                }.cellUpdate { cell, _ in
                    if let torrentData = self.torrentData {
                        cell.detailTextLabel?.text = torrentData.eta.timeRemainingString()
                    }

            }
            <<< LabelRow {
                $0.title = "Completed"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = String(format: "%.1f%%", torrentData.progress)
                }

                }.cellUpdate { cell, _ in
                    if let torrentData = self.torrentData {
                        cell.detailTextLabel?.text = String(format: "%.1f%%", torrentData.progress)
                    }

            }
            <<< LabelRow {
                $0.title = "Size"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = torrentData.total_size.sizeString()
                }
                }.cellUpdate { cell, _ in
                    if let torrentData = self.torrentData {
                        cell.detailTextLabel?.text = torrentData.total_size.sizeString()
                    }
            }
            <<< LabelRow {
                $0.title = "Downloaded"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = torrentData.all_time_download.sizeString()
                }

                }.cellUpdate { cell, _ in
                    if let torrentData = self.torrentData {
                        cell.detailTextLabel?.text = torrentData.all_time_download.sizeString()
                    }
            }
            <<< LabelRow {
                $0.title = "Uploaded"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = torrentData.total_uploaded.sizeString()
                }

                }.cellUpdate { cell, _ in
                    if let torrentData = self.torrentData {
                        cell.detailTextLabel?.text = torrentData.total_uploaded.sizeString()
                    }
            }
            <<< LabelRow {
                $0.title = "Ratio"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = String(format: "%.3f", torrentData.ratio)
                }

                }.cellUpdate { cell, _ in
                    if let torrentData = self.torrentData {
                        cell.detailTextLabel?.text = String(format: "%.3f", torrentData.ratio)
                    }
        }
        form +++ Section("Additional Info") {
            $0.tag = "AdditionalInfo"
            }

            <<< LabelRow {
                $0.title = "Status"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = torrentData.message
                }

                }.cellUpdate { cell, _ in
                    if let torrentData = self.torrentData {
                        cell.detailTextLabel?.text = torrentData.message
                    }
            }
            <<< LabelRow {
                $0.title = "Down Speed"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = torrentData.download_payload_rate.transferRateString()
                }

                }.cellUpdate { cell, _ in
                    if let torrentData = self.torrentData {
                        cell.detailTextLabel?.text = torrentData.download_payload_rate.transferRateString()
                    }
            }
            <<< LabelRow {
                $0.title = "Up Speed"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = torrentData.upload_payload_rate.transferRateString()
                }

                }.cellUpdate { cell, _ in
                    if let torrentData = self.torrentData {
                        cell.detailTextLabel?.text = torrentData.upload_payload_rate.transferRateString()
                    }
            }
            <<< LabelRow {
                $0.title = "Seeds Connected"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = "\(torrentData.num_seeds) (\(torrentData.total_seeds))"
                }
                }.cellUpdate { cell, _ in
                    if let torrentData = self.torrentData {
                        cell.detailTextLabel?.text = "\(torrentData.num_seeds) (\(torrentData.total_seeds))"
                    }
            }
            <<< LabelRow {
                $0.title = "Peers Connected"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = "\(torrentData.num_peers) (\(torrentData.total_peers))"
                }
                }.cellUpdate { cell, _ in
                    if let torrentData = self.torrentData {
                        cell.detailTextLabel?.text = "\(torrentData.num_peers) (\(torrentData.total_peers))"
                    }
            }
            <<< LabelRow {
                $0.title = "Path"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = torrentData.save_path
                }
                }.cellUpdate { cell, _ in
                    if let torrentData = self.torrentData {
                        cell.detailTextLabel?.text = torrentData.save_path
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
                }.cellUpdate { cell, _ in
                    if let torrentData = self.torrentData {
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
                }.cellUpdate { cell, _ in
                    if let torrentData = self.torrentData {
                        let formatter = DateComponentsFormatter()
                        formatter.allowedUnits = [.month, .day, .hour, .minute]
                        formatter.unitsStyle = .abbreviated
                        cell.detailTextLabel?.text = formatter.string(from: TimeInterval(torrentData.active_time))
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
                }.cellUpdate { cell, _ in
                    if let torrentData = self.torrentData {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "MM/dd/yyyy h:mm a"
                        cell.detailTextLabel?.text =
                            formatter.string(from: Date(timeIntervalSince1970: torrentData.time_added))
                    }
            }
            <<< LabelRow {
                $0.title = "Comments"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let torrentData = self.torrentData {
                    $0.cell.detailTextLabel?.text = torrentData.comment
                }
                }.cellUpdate { cell, _ in
                    if let torrentData = self.torrentData {
                        cell.detailTextLabel?.text = torrentData.comment
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

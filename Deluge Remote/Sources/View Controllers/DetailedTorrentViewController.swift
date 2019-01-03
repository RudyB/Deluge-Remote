//
//  DetailedTorrentViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 11/12/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import UIKit

class DetailedTorrentViewController: UITableViewController {

    @IBOutlet weak var deleteItem: UIBarButtonItem!
    @IBOutlet weak var playPauseItem: UIBarButtonItem!

    @IBAction func deleteAction(_ sender: UIBarButtonItem) {

        let deleteTorrent = UIAlertAction(title: "Delete Torrent", style: .destructive) { _ in
            ClientManager.shared.activeClient?.removeTorrent(withHash: self.torrentHash!, removeData: false).then {_ in
                self.navigationController?.popViewController(animated: true)
                }.catch { _ in
                    showAlert(target: self, title: "Failed to Delete Torrent")
            }
        }

        let deleteTorrentWithData = UIAlertAction(title: "Delete Torrent with Data", style: .destructive) { _ in
            ClientManager.shared.activeClient?.removeTorrent(withHash: self.torrentHash!, removeData: true).then {_ in
                self.navigationController?.popViewController(animated: true)
                }.catch { _ in
                    showAlert(target: self, title: "Failed to Delete Torrent")
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

    enum Sections: Int, CaseIterable {
        case Basic
        case Detailed
    }

    var torrentData: TorrentMetadata?
    var torrentHash: String?

    var refreshTimer: Timer!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Details"
        // Do any additional setup after loading the view.

        if let torrentHash = torrentHash {
            getTorrentData(withHash: torrentHash)
        }

        // Begin Data Download
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) {_ in
            guard let torrentHash = self.torrentHash else { return }
            self.getTorrentData(withHash: torrentHash)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        refreshTimer.invalidate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getTorrentData(withHash hash: String) {
        ClientManager.shared.activeClient?.getTorrentDetails(withHash: hash).then { torrent -> Void in
            DispatchQueue.main.async {
                self.torrentData = torrent
                self.playPauseItem.image = torrent.paused ?  #imageLiteral(resourceName: "play_filled") : #imageLiteral(resourceName: "icons8-pause")
                self.tableView.reloadData()
                print("Updated Detail VC Data")
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.allCases.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return [torrentData?.name, "Additional Info"][section]
    }
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 { return torrentData?.hash }
        return nil
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let torrentData = torrentData else { return 0 }
        switch Sections(rawValue: section)! {
        case .Basic:
            return torrentData.is_finished ? 6 : 7
        case .Detailed:
            return 10
        }
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TorrentDetailCell", for: indexPath)
        guard let torrentData = torrentData else {
            return tableView.dequeueReusableCell(withIdentifier: "RegularCell", for: indexPath)
        }

        switch Sections(rawValue: indexPath.section)! {
        case .Basic:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "State"
                cell.detailTextLabel?.text = torrentData.state

            case 1:
                cell.textLabel?.text = "Completed"
                cell.detailTextLabel?.text = String(format: "%.1f%%", torrentData.progress)
            case 2:
                cell.textLabel?.text = "Size"
                cell.detailTextLabel?.text = torrentData.total_size.sizeString()
            case 3:
                cell.textLabel?.text = "Downloaded"
                cell.detailTextLabel?.text = torrentData.all_time_download.sizeString()
            case 4:
                cell.textLabel?.text = "Uploaded"
                cell.detailTextLabel?.text = torrentData.total_uploaded.sizeString()
            case 5:
                cell.textLabel?.text = "Ratio"
                cell.detailTextLabel?.text = String(format: "%.3f", torrentData.ratio)
            case 6:
                cell.textLabel?.text = "ETA"
                cell.detailTextLabel?.text = "Computing"
                if torrentData.eta > 0 {
                    let formatter = DateComponentsFormatter()
                    formatter.allowedUnits = [.year, .day, .hour, .minute]
                    formatter.unitsStyle = .full
                    cell.detailTextLabel?.text = formatter.string(from: TimeInterval(torrentData.eta))
                }
            default: return tableView.dequeueReusableCell(withIdentifier: "RegularCell", for: indexPath)
            }
        case .Detailed:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Status"
                cell.detailTextLabel?.text = torrentData.message
            case 1:
                cell.textLabel?.text = "Down Speed"
                cell.detailTextLabel?.text = torrentData.download_payload_rate.transferRateString()
            case 2:
                cell.textLabel?.text = "Up Speed"
                cell.detailTextLabel?.text = torrentData.upload_payload_rate.transferRateString()
            case 3:
                cell.textLabel?.text = "Seeds Connected"
                cell.detailTextLabel?.text = "\(torrentData.num_seeds) (\(torrentData.total_seeds))"
            case 4:
                cell.textLabel?.text = "Peers Connected"
                cell.detailTextLabel?.text = "\(torrentData.num_peers) (\(torrentData.total_peers))"
            case 5:
                cell.textLabel?.text = "Path"
                cell.detailTextLabel?.text = torrentData.save_path
            case 6:
                cell.textLabel?.text = "Tracker"
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

            case 7:
                cell.textLabel?.text = "Active Time"
                let formatter = DateComponentsFormatter()
                formatter.allowedUnits = [.month, .day, .hour, .minute]
                formatter.unitsStyle = .abbreviated
                cell.detailTextLabel?.text = formatter.string(from: TimeInterval(torrentData.active_time))
            case 8:
                cell.textLabel?.text = "Date Added"
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yyyy h:mm a"
                cell.detailTextLabel?.text = formatter.string(from: Date(timeIntervalSince1970: torrentData.time_added))
            case 9:
                cell.textLabel?.text = "Comments"
                cell.detailTextLabel?.text = torrentData.comment
            default: return tableView.dequeueReusableCell(withIdentifier: "RegularCell", for: indexPath)
            }
        }
        return cell
    }
}

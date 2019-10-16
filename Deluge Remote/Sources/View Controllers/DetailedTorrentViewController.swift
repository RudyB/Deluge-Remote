//
//  DetailedTorrentViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 11/12/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import Eureka
import Houston
import UIKit

// swiftlint:disable:next type_body_length
class DetailedTorrentViewController: FormViewController {

    enum TorrentOptionsCodingKeys: String {
        case maxDownloadSpeed = "max_download_speed"
        case maxUploadSpeed = "max_upload_speed"
        case maxConnections = "max_connections"
        case maxUploadSlots = "max_upload_slots"

        case autoManaged = "auto_managed"
        case stopSeedAtRatio = "stop_at_ratio"
        case stopRatio = "stop_ratio"
        case remoteAtRatio = "remove_at_ratio"
        case moveCompleted = "move_completed"
        case moveCompletedPath = "move_completed_path"
        case prioritizeFirstLastPieces = "prioritize_first_last_pieces"
        case downloadLocation = "download_location"
    }

    // MARK: - IBOutlets
    @IBOutlet weak var deleteItem: UIBarButtonItem!
    @IBOutlet weak var playPauseItem: UIBarButtonItem!

    @IBAction func deleteAction(_ sender: UIBarButtonItem) {

        let deleteTorrent = UIAlertAction(title: "Delete Torrent", style: .destructive) { [weak self] _ in
            self?.invalidateTimer()
            guard let self = self, let torrentHash = self.torrentHash else { return }
            var haptic: UINotificationFeedbackGenerator? = UINotificationFeedbackGenerator()
            haptic?.prepare()
            ClientManager.shared.activeClient?.removeTorrent(withHash: torrentHash, removeData: false).then {_ -> Void in
                DispatchQueue.main.async {
                     haptic?.notificationOccurred(.success)
                }
                self.view.showHUD(title: "Torrent Successfully Deleted") {
                    self.navigationController?.popViewController(animated: true)
                }
                }.catch { error in
                    haptic?.notificationOccurred(.error)
                    if let error = error as? ClientError {
                        showAlert(target: self, title: "Error", message: error.domain())
                    } else {
                        showAlert(target: self, title: "Error", message: error.localizedDescription)
                    }
                }.always {
                    haptic = nil
            }

        }

        let deleteTorrentWithData = UIAlertAction(title: "Delete Torrent with Data", style: .destructive) { [weak self] _ in
            self?.invalidateTimer()
            guard let self = self, let torrentHash = self.torrentHash else { return }
            var haptic: UINotificationFeedbackGenerator? = UINotificationFeedbackGenerator()
            haptic?.prepare()
            ClientManager.shared.activeClient?.removeTorrent(withHash: torrentHash, removeData: true).then {_ -> Void in

                DispatchQueue.main.async {
                    haptic?.notificationOccurred(.success)
                }
                self.view.showHUD(title: "Torrent Successfully Deleted") {
                    self.navigationController?.popViewController(animated: true)
                }
                }.catch { error in
                    haptic?.notificationOccurred(.error)
                    if let error = error as? ClientError {
                        showAlert(target: self, title: "Error", message: error.domain())
                    } else {
                        showAlert(target: self, title: "Error", message: error.localizedDescription)
                    }
                }.always {
                    haptic = nil
                }

        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel)

        showAlert(target: self, title: "Remove the torrent?", style: .actionSheet,
                  actionList: [deleteTorrent, deleteTorrentWithData, cancel])
    }

    @IBAction func playPauseAction(_ sender: UIBarButtonItem) {
        guard let torrentData = torrentData else { return }

        var haptic: UINotificationFeedbackGenerator? = UINotificationFeedbackGenerator()
        haptic?.prepare()
        if torrentData.paused {
            ClientManager.shared.activeClient?.resumeTorrent(withHash: torrentData.hash) { [weak self] result in

                guard let self = self else {return}
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        DispatchQueue.main.async {
                            haptic?.notificationOccurred(.success)
                            self.view.showHUD(title: "Successfully Resumed Torrent")
                        }
                        UIView.animate(withDuration: 1.0) {
                            self.playPauseItem.image = #imageLiteral(resourceName: "icons8-pause")
                        }

                    case .failure:
                        DispatchQueue.main.async {
                            haptic?.notificationOccurred(.error)
                            self.view.showHUD(title: "Failed To Resume Torrent", type: .failure)
                        }
                    }
                }

            }
        } else {
            ClientManager.shared.activeClient?.pauseTorrent(withHash: torrentData.hash) { [weak self] result in
                guard let self = self else {return}
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        DispatchQueue.main.async {
                            haptic?.notificationOccurred(.success)
                            self.view.showHUD(title: "Successfully Paused Torrent")
                        }
                        UIView.animate(withDuration: 1.0) {
                            self.playPauseItem.image = #imageLiteral(resourceName: "play_filled")
                        }

                    case .failure:
                        DispatchQueue.main.async {
                            haptic?.notificationOccurred(.error)
                            self.view.showHUD(title: "Failed to Pause Torrent", type: .failure)
                        }
                    }
                }
            }
        }

    }

    // MARK: - Properties
    var torrentData: TorrentMetadata?
    var torrentHash: String?

    var refreshTimer: Timer?

    deinit {
        Logger.debug("Destroyed")
    }

    // MARK: - View Related Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Details"
        // Do any additional setup after loading the view.

        if let torrentHash = torrentHash {
            getTorrentData(withHash: torrentHash)
        }
        // Begin Data Download
        createNewTimer()

        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 44.0

        // Create Form
        animateScroll = true // Enables smooth scrolling on navigation to off-screen rows
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

    // swiftlint:disable:next function_body_length
    func createBasicInfoSection() {
        form +++ Section("Basic Info")
            <<< LabelRow {
                $0.title = "State"
                $0.cell.detailTextLabel?.numberOfLines = 0
                $0.value = torrentData?.state
                }.cellUpdate { [weak self] cell, row in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.state
                        cell.height = self?.computeCellHeight(for: cell)
                        if row.section?.header?.title != torrentData.name {
                            row.section?.header?.title = torrentData.name
                            row.section?.reload()
                        }

                    }
            }

            <<< LabelRow {
                $0.title = "ETA"
                $0.tag = "ETA"
                $0.cell.detailTextLabel?.numberOfLines = 0

                $0.cell.detailTextLabel?.text = torrentData?.eta.timeRemainingString()
                $0.cell.detailTextLabel?.numberOfLines = 0
                $0.hidden = Condition(booleanLiteral: torrentData?.eta ?? 0 == 0)
                }.cellUpdate { [weak self] cell, _ in
                    cell.row.hidden = Condition(booleanLiteral: self?.torrentData?.eta ?? 0 == 0)
                    cell.row.evaluateHidden()
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.eta.timeRemainingString()
                        cell.height = self?.computeCellHeight(for: cell)
                    }

            }
            <<< LabelRow {
                $0.title = "Completed"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let progress = torrentData?.progress {
                    $0.cell.detailTextLabel?.text = String(format: "%.1f%%", progress)
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
                $0.cell.detailTextLabel?.text = torrentData?.total_size.sizeString()
                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.total_size.sizeString()
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }
            <<< LabelRow {
                $0.title = "Downloaded"
                $0.cell.detailTextLabel?.numberOfLines = 0
                $0.cell.detailTextLabel?.text = torrentData?.all_time_download.sizeString()

                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.all_time_download.sizeString()
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }
            <<< LabelRow {
                $0.title = "Uploaded"
                $0.cell.detailTextLabel?.numberOfLines = 0
                $0.cell.detailTextLabel?.text = torrentData?.total_uploaded.sizeString()

                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.total_uploaded.sizeString()
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }
            <<< LabelRow {
                $0.title = "Ratio"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let ratio = torrentData?.ratio {
                    $0.cell.detailTextLabel?.text = String(format: "%.3f", ratio)
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
                $0.cell.detailTextLabel?.text = torrentData?.message

                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.message
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }
            <<< LabelRow {
                $0.title = "Down Speed"
                $0.cell.detailTextLabel?.numberOfLines = 0
                $0.cell.detailTextLabel?.text = torrentData?.download_payload_rate.transferRateString()

                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.download_payload_rate.transferRateString()
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }
            <<< LabelRow {
                $0.title = "Up Speed"
                $0.cell.detailTextLabel?.numberOfLines = 0
                $0.cell.detailTextLabel?.text = torrentData?.upload_payload_rate.transferRateString()

                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.upload_payload_rate.transferRateString()
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }
            <<< LabelRow {
                $0.title = "Seeds Connected"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let data = torrentData {
                    $0.cell.detailTextLabel?.text = "\(data.num_seeds) (\(data.total_seeds))"
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
                if let data = torrentData {
                    $0.cell.detailTextLabel?.text = "\(data.num_peers) (\(data.total_peers))"
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
                $0.cell.detailTextLabel?.text = torrentData?.save_path
                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        cell.detailTextLabel?.text = torrentData.save_path
                        cell.height = self?.computeCellHeight(for: cell)
                    }
            }
            <<< LabelRow {
                $0.title = "Tracker"
                $0.cell.detailTextLabel?.numberOfLines = 0
                if let data = torrentData {
                    if let tracker = URL(string: data.tracker) {
                        $0.cell.detailTextLabel?.text = tracker.host
                    } else {
                        if let url = data.trackers.first?.url,
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
                if let activeTime = torrentData?.active_time {
                    let formatter = DateComponentsFormatter()
                    formatter.allowedUnits = [.month, .day, .hour, .minute]
                    formatter.unitsStyle = .abbreviated
                    $0.cell.detailTextLabel?.text = formatter.string(from: TimeInterval(activeTime))
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
                if let timeAdded = torrentData?.time_added {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MM/dd/yyyy h:mm a"
                    $0.cell.detailTextLabel?.text =
                        formatter.string(from: Date(timeIntervalSince1970: timeAdded))
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
                $0.cell.row.hidden = Condition(booleanLiteral: torrentData?.comment
                    .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
                }.cellUpdate {[weak self] cell, row in
                    DispatchQueue.main.async {
                        guard let torrentData = self?.torrentData else { return }

                        row.hidden = Condition(booleanLiteral: torrentData.comment
                            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        row.evaluateHidden()

                        row.value = torrentData.comment
                        cell.height = self?.computeCellHeight(for: cell)

                        cell.detailTextLabel?.text = torrentData.comment
                    }
                    row.reload()
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func createTorrentOptionsSection() {

        form +++ Section {
            $0.header = {
                var header = HeaderFooterView<UIView>(.callback({
                    let headerView = UIView(frame: CGRect(x: 15, y: 5, width: 250, height: 40))
                    let label = UILabel(frame: headerView.frame)
                    label.text = "Torrent Options"
                    label.font = UIFont.boldSystemFont(ofSize: 30.0)
                    headerView.addSubview(label)
                    return headerView
                }))
                header.height = { 45 }
                return header
            }()
        }
        form +++ Section("Bandwidth")
            <<< IntRow {
                $0.title = "Max Download Speed (KiB/s)"
                $0.tag = TorrentOptionsCodingKeys.maxDownloadSpeed.rawValue
                $0.value = Int(torrentData?.max_download_speed ?? -1)
                $0.cell.textField.text = "\(Int(torrentData?.max_download_speed ?? -1))"
                $0.cell.textField.keyboardType = .numbersAndPunctuation
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                }.cellUpdate { [weak self] cell, _ in
                    cell.titleLabel?.textColor = cell.row.isValid ? .black : .red

                    if let torrentData = self?.torrentData {
                        if !cell.row.wasChanged {
                            cell.textField.text = "\(Int(torrentData.max_download_speed))"
                            cell.row.value = Int(torrentData.max_download_speed)
                        }
                    }

                }

            <<< IntRow {
                $0.title  = "Max Upload Speed (KiB/s)"
                $0.tag = TorrentOptionsCodingKeys.maxUploadSpeed.rawValue
                $0.cell.textField.text = "\(Int(torrentData?.max_upload_speed ?? -1))"
                $0.value = Int(torrentData?.max_upload_speed ?? -1)
                $0.cell.textField.keyboardType = .numbersAndPunctuation
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                }.cellUpdate { [weak self] cell, _ in
                    cell.titleLabel?.textColor = cell.row.isValid ? .black : .red
                    if let torrentData = self?.torrentData {
                        if !cell.row.wasChanged {
                            cell.textField.text = "\(Int(torrentData.max_upload_speed))"
                            cell.row.value = Int(torrentData.max_upload_speed)
                        }
                    }
                }

            <<< IntRow {
                $0.title  = "Max Connections"
                $0.tag = TorrentOptionsCodingKeys.maxConnections.rawValue
                $0.value = torrentData?.max_connections
                $0.cell.textField.text = "\(torrentData?.max_connections ?? -1)"
                $0.cell.textField.keyboardType = .numbersAndPunctuation
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                }.cellUpdate { [weak self] cell, _ in
                    cell.titleLabel?.textColor = cell.row.isValid ? .black : .red
                    if let torrentData = self?.torrentData {
                        if !cell.row.wasChanged {
                            cell.textField.text = "\(torrentData.max_connections)"
                            cell.row.value = torrentData.max_connections
                        }
                    }
                }

            <<< IntRow {
                $0.title  = "Max Upload Slots"
                $0.tag = TorrentOptionsCodingKeys.maxUploadSlots.rawValue
                $0.value = torrentData?.max_upload_slots
                $0.cell.textField.text = "\(torrentData?.max_upload_slots ?? -1)"
                $0.cell.textField.keyboardType = .numbersAndPunctuation
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                }.cellUpdate { [weak self] cell, _ in
                    cell.titleLabel?.textColor = cell.row.isValid ? .black : .red
                    if let torrentData = self?.torrentData {
                        if !cell.row.wasChanged {
                            cell.textField.text = "\(torrentData.max_upload_slots)"
                            cell.row.value = torrentData.max_upload_slots
                        }
                    }
                }

        form +++ Section("Queue")
            <<< SwitchRow {
                $0.title = "Auto Managed"
                $0.value = torrentData?.is_auto_managed
                $0.tag = TorrentOptionsCodingKeys.autoManaged.rawValue
                }
                .cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        if !cell.row.wasChanged {
                            cell.switchControl.setOn(torrentData.is_auto_managed, animated: true)
                            cell.row.value = torrentData.is_auto_managed
                        }
                    }
            }

            <<< SwitchRow {
                $0.title = "Stop Seed at Ratio"
                $0.tag = TorrentOptionsCodingKeys.stopSeedAtRatio.rawValue
                $0.value = torrentData?.stop_at_ratio.value
                }.cellUpdate { [weak self] cell, _ in

                    if let torrentData = self?.torrentData {
                        if !cell.row.wasChanged {
                            DispatchQueue.main.async {
                                cell.row.value = torrentData.stop_at_ratio.value
                                cell.switchControl.setOn(torrentData.stop_at_ratio.value, animated: true)
                            }
                        }

                    }
                }

            <<< DecimalRow {
                $0.title  = "\tStop Ratio"
                $0.tag = TorrentOptionsCodingKeys.stopRatio.rawValue
                $0.value = torrentData?.stop_ratio
                $0.hidden = Condition.function([TorrentOptionsCodingKeys.stopSeedAtRatio.rawValue]) { form -> Bool in
                    return !((form.rowBy(tag: TorrentOptionsCodingKeys.stopSeedAtRatio.rawValue) as? SwitchRow)?.value ?? false)
                }
                $0.cell.textField.keyboardType = .numbersAndPunctuation
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                }.cellUpdate { [weak self] cell, _ in
                    cell.titleLabel?.textColor = cell.row.isValid ? .black : .red
                    if let torrentData = self?.torrentData {
                        if !cell.row.wasChanged {
                            cell.textField.text = "\(torrentData.stop_ratio)"
                            cell.row.value = torrentData.stop_ratio
                        }
                    }
                }

            <<< SwitchRow {
                $0.title = "\tRemove at Ratio"
                $0.tag = TorrentOptionsCodingKeys.remoteAtRatio.rawValue
                $0.value = torrentData?.remove_at_ratio
                $0.hidden = Condition.function([TorrentOptionsCodingKeys.stopSeedAtRatio.rawValue]) { form -> Bool in
                    return !((form.rowBy(tag: TorrentOptionsCodingKeys.stopSeedAtRatio.rawValue) as? SwitchRow)?.value ?? false)
                }
                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        if !cell.row.wasChanged {
                            cell.switchControl.setOn(torrentData.remove_at_ratio, animated: true)
                            cell.row.value = torrentData.remove_at_ratio
                        }
                    }
            }

            <<< SwitchRow {
                $0.title = "Move Completed"
                $0.tag = TorrentOptionsCodingKeys.moveCompleted.rawValue
                $0.value = torrentData?.move_completed.value
                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        if !cell.row.wasChanged {
                            DispatchQueue.main.async {
                                cell.row.value = torrentData.move_completed.value
                                cell.switchControl.setOn(torrentData.move_completed.value, animated: true)
                            }
                        }
                    }
            }

            <<< TextRow {
                $0.title = "\tPath"
                $0.tag = TorrentOptionsCodingKeys.moveCompletedPath.rawValue
                $0.value = torrentData?.move_completed_path
                $0.hidden = Condition.function([TorrentOptionsCodingKeys.moveCompleted.rawValue]) { form -> Bool in
                    return !((form.rowBy(tag: TorrentOptionsCodingKeys.moveCompleted.rawValue) as? SwitchRow)?.value ?? false)
                }
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange

                }.cellUpdate { [weak self] cell, _ in
                    cell.titleLabel?.textColor = cell.row.isValid ? .black : .red
                    if let torrentData = self?.torrentData {
                        if !cell.row.wasChanged {
                            cell.row.value = torrentData.move_completed_path
                            cell.textField.text = torrentData.move_completed_path
                        }
                    }
                }

            <<< SwitchRow {
                $0.title = "Prioritize First/Last Pieces"
                $0.tag = TorrentOptionsCodingKeys.prioritizeFirstLastPieces.rawValue
                $0.value = torrentData?.prioritize_first_last
                }.cellUpdate { [weak self] cell, _ in
                    if let torrentData = self?.torrentData {
                        if !cell.row.wasChanged {
                            cell.row.value = torrentData.prioritize_first_last
                            cell.switchControl.setOn(torrentData.prioritize_first_last, animated: true)
                        }
                    }
        }

        form +++ Section()
            <<< ButtonRow {
                $0.title = "Move Storage"
                }.onCellSelection { [weak self] _, _ in
                    self?.moveStorage()
        }

        form +++ Section()
            <<< ButtonRow {
                $0.title = "Apply Settings"
                }.onCellSelection { [weak self] _, _ in
                    self?.applyChanges()
                }

    }

    func createNewTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) {[weak self] _ in
            guard let torrentHash = self?.torrentHash else { return }
            self?.getTorrentData(withHash: torrentHash)
        }
        Logger.info("Create New Data Timer")
    }

    func applyChanges() {

        if (form.allRows.map { $0.isValid }).contains(false) {
            showAlert(target: self, title: "Validation Error", message: "All fields are mandatory")
        }

        let formData = form.values(includeHidden: true)
        guard
            let torrentHash = torrentHash,
            let maxDownloadSpeed = formData[TorrentOptionsCodingKeys.maxDownloadSpeed.rawValue] as? Int,
            let maxUploadSpeed = formData[TorrentOptionsCodingKeys.maxUploadSpeed.rawValue] as? Int,
            let maxConnections = formData[TorrentOptionsCodingKeys.maxConnections.rawValue] as? Int,
            let maxUploadSlots = formData[TorrentOptionsCodingKeys.maxUploadSlots.rawValue] as? Int,
            let isAutoManaged = formData[TorrentOptionsCodingKeys.autoManaged.rawValue] as? Bool,
            let stopSeedAtRatio = formData[TorrentOptionsCodingKeys.stopSeedAtRatio.rawValue] as? Bool,
            let stopRatio = formData[TorrentOptionsCodingKeys.stopRatio.rawValue] as? Double,
            let removeAtRatio = formData[TorrentOptionsCodingKeys.remoteAtRatio.rawValue] as? Bool,
            let moveCompleted = formData[TorrentOptionsCodingKeys.moveCompleted.rawValue] as? Bool,
            let moveCompletedPath = formData[TorrentOptionsCodingKeys.moveCompletedPath.rawValue] as? String,
            let prioritizeFL = formData[TorrentOptionsCodingKeys.prioritizeFirstLastPieces.rawValue] as? Bool
        else { return }

        let params: [String: Any] = [
            TorrentOptionsCodingKeys.maxDownloadSpeed.rawValue: maxDownloadSpeed,
            TorrentOptionsCodingKeys.maxUploadSpeed.rawValue: maxUploadSpeed,
            TorrentOptionsCodingKeys.maxConnections.rawValue: maxConnections,
            TorrentOptionsCodingKeys.maxUploadSlots.rawValue: maxUploadSlots,

            TorrentOptionsCodingKeys.autoManaged.rawValue: isAutoManaged,
            TorrentOptionsCodingKeys.stopSeedAtRatio.rawValue: stopSeedAtRatio,
            TorrentOptionsCodingKeys.stopRatio.rawValue: stopRatio,
            TorrentOptionsCodingKeys.remoteAtRatio.rawValue: removeAtRatio,
            TorrentOptionsCodingKeys.moveCompleted.rawValue: moveCompleted,
            TorrentOptionsCodingKeys.moveCompletedPath.rawValue: moveCompletedPath,
            TorrentOptionsCodingKeys.prioritizeFirstLastPieces.rawValue: prioritizeFL
        ]

        ClientManager.shared.activeClient?.setTorrentOptions(hash: torrentHash, options: params)
            .then { [weak self] _ -> Void in
                self?.view.showHUD(title: "Updated Torrent Options")
            }
            .catch { [weak self] error -> Void in
                self?.view.showHUD(title: "Failed to Update Torrent Options", type: .failure)
                Logger.error(error)
            }
    }

    func moveStorage() {
        let alert = UIAlertController(title: "Move Torrent", message: "Please enter a new directory",
                                      preferredStyle: .alert)
        alert.addTextField {  [weak self] textField in
            textField.text = self?.torrentData?.save_path
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let moveAction = UIAlertAction(title: "Move", style: .destructive) { [weak self] _ in
            guard
                let textfield = alert.textFields?.first,
                let filepath = textfield.text,
                let torrentHash = self?.torrentHash
            else { return }
            ClientManager.shared.activeClient?.moveTorrent(hash: torrentHash, filepath: filepath)
                .then { [weak self] _ -> Void in
                    DispatchQueue.main.async {
                        self?.view.showHUD(title: "Moved Torrent", type: .success)
                    }

                }
                .catch { [weak self] error -> Void in
                    DispatchQueue.main.async {
                        self?.view.showHUD(title: "Failed to Move Torrent", type: .failure)
                    }
                Logger.error(error)
            }
        }

        alert.addAction(moveAction)
        alert.addAction(cancelAction)

        self.present(alert, animated: true, completion: nil)
    }

    func invalidateTimer() {
        refreshTimer?.invalidate()
        Logger.info("Invalidated Data Timer")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getTorrentData(withHash hash: String) {
        ClientManager.shared.activeClient?.getTorrentDetails(withHash: hash).then { [weak self] torrent -> Void in
            Logger.verbose("New Detail VC Data")

            self?.torrentData = torrent
            self?.playPauseItem.image = torrent.paused ?  #imageLiteral(resourceName: "play_filled") : #imageLiteral(resourceName: "icons8-pause")

            self?.form.allRows.forEach { row in
                DispatchQueue.main.async {
                    row.updateCell()
                }
            }

            }.catch { [weak self] error in
                if let self = self, let error = error as? ClientError {
                    let okButton = UIAlertAction(title: "Bummer", style: .default) { _ in
                        self.navigationController?.popViewController(animated: true)
                    }
                    showAlert(target: self, title: "Error", message: error.domain(),
                              style: .alert, actionList: [okButton])

                }
        }
    }

} // swiftlint:disable:this file_length

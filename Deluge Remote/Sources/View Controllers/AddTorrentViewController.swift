//
//  AddTorrentViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 1/1/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import Eureka
import Houston
import MBProgressHUD
import PromiseKit
import UIKit

protocol AddTorrentViewControllerDelegate: AnyObject {
    func torrentAdded(_ torrentHash: String)
}

// swiftlint:disable:next type_body_length
class AddTorrentViewController: FormViewController, Storyboarded {
    
    var defaultConfig: TorrentConfig?
    weak var delegate: AddTorrentViewControllerDelegate?

    var torrentName: String?
    var torrentHash: String?
    var torrentType: TorrentType?
    var torrentData: TorrentData?
    
    let pasteboard = UIPasteboard.general

    enum CodingKeys: String {
        case selectionSection
        case torrentType
        case magnetURL
        // Torrent Config
        case bandwidthConfig
        case queueConfig
        case addPaused
        case maxDownloadSpeed
        case maxUploadSpeed
        case maxConnections
        case maxUploadSlots
        case prioritizeFirstLastPieces
        case moveCompleted
        case moveCompletedPath
        case downloadLocation
        case compactAllocation

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Add Torrent"

        // Get the Torrent Config
        getTorrentConfig()

        // Populate Form
        guard
            let torrentData = torrentData
        else
        {
            populateTorrentTypeSelection()
            checkPasteboardForMagnetLink()
            NotificationCenter.default.addObserver(self, selector: #selector(self.checkPasteboardForMagnetLink),
                                                   name: UIPasteboard.changedNotification, object: pasteboard)
            return;
        }
        torrentType = torrentData.type
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        switch torrentData {
        case .file(let data):
            handleFormConfigurationFor(torrent: data)
        case .magnet(let url):
            handleFormConfigurationFor(magnetURL: url)
        }
    }

    deinit {
        Logger.debug("Destroyed")
        
        NotificationCenter.default.removeObserver(self, name: UIPasteboard.changedNotification, object: pasteboard)
    }

    
    @objc func checkPasteboardForMagnetLink()
    {
        guard
            let url = pasteboard.url,
            url.absoluteString.hasPrefix("magnet:?"),
            let urlRow = form.rowBy(tag: CodingKeys.magnetURL.rawValue) as? URLRow,
            let buttonRow = form.rowBy(tag: CodingKeys.torrentType.rawValue) as? SegmentedRow<String>
        else { return }
        
        
        if torrentData == nil || torrentType == TorrentType.magnet {
            torrentType = .magnet // TODO: RudyB 6/14 - Make this click select the magnet option
            urlRow.value = url
            buttonRow.value = "Magnet Link"
            buttonRow.reload()
            urlRow.evaluateHidden()
        }
    }
    
    func handleFormConfigurationFor(torrent: Data) {
        ClientManager.shared.activeClient?.getTorrentInfo(torrent: torrent)
            .ensure { [weak self] in
                if let self = self {
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view, animated: true)
                    }
                }
            }
            .done { [weak self] torrentInfo in
                DispatchQueue.main.async {
                    self?.showTorrentConfig(name: torrentInfo.name, hash: torrentInfo.hash)
                }
                torrentInfo.files.prettyPrint()
            }.catch { [weak self] error in
                guard let self = self else { return }
                if let error = error as? ClientError {
                    showAlert(target: self, title: "Connection failure", message: error.domain())
                } else {
                    showAlert(target: self, title: "Connection failure", message: error.localizedDescription)
                }
                if self.torrentType != nil {
                    self.populateTorrentTypeSelection()
                }
        }
    }

    func handleFormConfigurationFor(magnetURL: URL) {
        ClientManager.shared.activeClient?.getMagnetInfo(url: magnetURL)
            .ensure { [weak self] in
                if let self = self {
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view, animated: true)
                    }
                }
            }
            .done { [weak self] output in
                DispatchQueue.main.async {
                    self?.torrentData = TorrentData.magnet(magnetURL)
                    self?.showTorrentConfig(name: output.name, hash: output.hash)
                }
            }.catch { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.async {

                    showAlert(target: self, title: "Failure to load magnet URL",
                              message: "An error occurred while attempting to load the magnet URL")

                }
        }
    }

    // swiftlint:disable:next function_body_length
    func populateTorrentTypeSelection() {
        form +++ Eureka.Section {
            $0.tag = CodingKeys.selectionSection.rawValue
            $0.header?.title = "Select Torrent Source"
            }

            <<< SegmentedRow<String> {
                $0.tag = CodingKeys.torrentType.rawValue
                $0.options = ["Magnet Link", "Torrent File"]
                }.onChange { [weak self] row in
                    if let value = row.value, let type = TorrentType(rawValue: value) {
                        self?.torrentType = type
                        if(type == TorrentType.magnet) {
                            self?.checkPasteboardForMagnetLink()
                        }
                    }
            }

            <<< URLRow {
                $0.title = "URL:"
                $0.tag = CodingKeys.magnetURL.rawValue
                $0.validationOptions = .validatesOnBlur
                $0.hidden = Condition.function([CodingKeys.torrentType.rawValue]) { form in
                    let selection = (form.rowBy(tag: CodingKeys.torrentType.rawValue)
                        as? SegmentedRow<String>)?.value ?? ""
                    return selection != "Magnet Link"
                }
                }.cellUpdate { cell, _ in
                    cell.textLabel?.textColor = ColorCompatibility.label
                }.onRowValidationChanged { cell, row in
                    if !row.isValid {
                        cell.titleLabel?.textColor = .red
                    }
            }
            <<< ButtonRow {
                $0.title = "Select a file"
                $0.hidden = Condition.function([CodingKeys.torrentType.rawValue]) { form in

                    let selection = (form.rowBy(tag: CodingKeys.torrentType.rawValue)
                        as? SegmentedRow<String>)?.value ?? ""
                    return selection != "Torrent File"
                }
                }.onCellSelection { [weak self] _, _ in
                    let vc = UIDocumentPickerViewController(
                        documentTypes: ["io.rudybermudez.deluge.torrent"], in: UIDocumentPickerMode.import
                    )
                    vc.delegate = self
                    self?.present(vc, animated: true, completion: nil)
            }

            <<< ButtonRow {
                $0.title = "Parse Magnet Link"
                $0.disabled = Condition.function([CodingKeys.magnetURL.rawValue]) { form in
                    return (form.rowBy(tag: CodingKeys.magnetURL.rawValue) as? ButtonRow)?.isValid ?? false
                }
                $0.hidden = Condition.function([CodingKeys.torrentType.rawValue]) { form in
                    let selection = (form.rowBy(tag: CodingKeys.torrentType.rawValue)
                        as? SegmentedRow<String>)?.value ?? ""
                    return selection != "Magnet Link"
                }
                }.onCellSelection { [weak self] _, _ in
                    guard
                        let url = self?.form.values()[CodingKeys.magnetURL.rawValue] as? URL
                        else { return }
                    DispatchQueue.main.async {
                        if let view = self?.view {
                            MBProgressHUD.showAdded(to: view, animated: true)
                        }
                    }
                    self?.handleFormConfigurationFor(magnetURL: url)
        }
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func showTorrentConfig(name: String, hash: String) {
        self.torrentName = name
        self.torrentHash = hash

        form.sectionBy(tag: CodingKeys.selectionSection.rawValue)?.hidden = true
        form.sectionBy(tag: CodingKeys.selectionSection.rawValue)?.evaluateHidden()

        let title = "Upload Torrent to \(ClientManager.shared.activeClient?.clientConfig.nickname ?? "Server")"
        let done = UIBarButtonItem(title: title, style: .done, target: self, action: #selector(uploadToServer))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        self.setToolbarItems([spacer, done, spacer], animated: true)

        form +++ Eureka.Section("Torrent Info")
            <<< LabelRow {
                $0.title = name
                $0.cell.textLabel?.numberOfLines = 0
                $0.cell.textLabel?.lineBreakMode = .byCharWrapping
            }
            <<< LabelRow {
                $0.title = hash
                $0.cell.textLabel?.adjustsFontSizeToFitWidth = true
        }

        form +++ Eureka.Section("Bandwidth Config") {
            $0.tag = CodingKeys.bandwidthConfig.rawValue
            }

            <<< IntRow {
                $0.title = "Max Download Speed (KiB/s)"
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                $0.value = defaultConfig?.maxDownloadSpeed
                $0.cell.textField.keyboardType = .numbersAndPunctuation
                }.onChange { [weak self] row in
                    if let value = row.value {
                        self?.defaultConfig?.maxDownloadSpeed = value
                    }
                }.cellUpdate { [weak self] cell, row in
                    cell.titleLabel?.textColor = cell.row.isValid ? ColorCompatibility.label : .red

                    if !row.wasChanged {
                        if let speed = self?.defaultConfig?.maxDownloadSpeed {
                            row.cell.textField?.text = "\(speed)"
                            row.value = self?.defaultConfig?.maxDownloadSpeed
                        }
                    }
            }

            <<< IntRow {
                $0.title = "Max Upload Speed (KiB/s)"
                $0.value = defaultConfig?.maxUploadSpeed
                $0.cell.textField.keyboardType = .numbersAndPunctuation
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                }.onChange { [weak self] row in
                    if let value = row.value {
                        self?.defaultConfig?.maxUploadSpeed = value
                    }
                }.cellUpdate { [weak self] cell, row in
                    cell.titleLabel?.textColor = cell.row.isValid ? ColorCompatibility.label : .red
                    if !row.wasChanged {
                        if let speed = self?.defaultConfig?.maxUploadSpeed {
                            row.cell.textField?.text = "\(speed)"
                            row.value = self?.defaultConfig?.maxUploadSpeed
                        }
                    }

            }

            <<< IntRow {
                $0.title = "Max Connections"
                $0.add(rule: RuleRequired())
                $0.value = defaultConfig?.maxConnections
                $0.validationOptions = .validatesOnChange
                $0.cell.textField.keyboardType = .numbersAndPunctuation
                }.onChange { [weak self] row in
                    if let value = row.value {
                        self?.defaultConfig?.maxConnections = value
                    }
                }.cellUpdate { [weak self] cell, row in
                    cell.titleLabel?.textColor = cell.row.isValid ? ColorCompatibility.label : .red
                    if !row.wasChanged {
                        if let connections = self?.defaultConfig?.maxConnections {
                            row.cell.textField?.text = "\(connections)"
                            row.value = self?.defaultConfig?.maxConnections
                        }
                    }

            }

            <<< IntRow {
                $0.title = "Max Upload Slots"
                $0.add(rule: RuleRequired())
                $0.value = defaultConfig?.maxUploadSlots
                $0.validationOptions = .validatesOnChange
                $0.cell.textField.keyboardType = .numbersAndPunctuation
                }.onChange { [weak self] row in
                    if let value = row.value {
                        self?.defaultConfig?.maxUploadSlots = value
                    }
                }.cellUpdate { [weak self] cell, row in
                    cell.titleLabel?.textColor = cell.row.isValid ? ColorCompatibility.label : .red
                    if !row.wasChanged {
                        if let slots = self?.defaultConfig?.maxUploadSlots {
                            row.cell.textField?.text = "\(slots)"
                            row.value = self?.defaultConfig?.maxUploadSlots
                        }
                    }

        }

        form +++ Eureka.Section("Queue Configuration") {
            $0.tag = CodingKeys.queueConfig.rawValue
            }
            <<< TextRow {
                $0.title = "Download Location"
                $0.tag = CodingKeys.downloadLocation.rawValue
                $0.value = defaultConfig?.downloadLocation
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                }.onChange { [weak self] row in
                    if let value = row.value {
                        self?.defaultConfig?.downloadLocation = value
                    }
                }.cellUpdate { [weak self] cell, row in
                    cell.titleLabel?.textColor = cell.row.isValid ? ColorCompatibility.label : .red
                    if !row.wasChanged {
                        row.value = self?.defaultConfig?.downloadLocation
                        row.cell.textField?.text = self?.defaultConfig?.downloadLocation
                    }

            }
            <<< SwitchRow {
                $0.title = "Move Completed"
                $0.tag = CodingKeys.moveCompleted.rawValue
                $0.value = defaultConfig?.moveCompleted
                }.onChange { [weak self] row in
                    if let value = row.value {
                        self?.defaultConfig?.moveCompleted = value
                    }
                }.cellUpdate { [weak self] _, row in
                    row.value = self?.defaultConfig?.moveCompleted
                    if let moveComplete = self?.defaultConfig?.moveCompleted {
                        row.cell.switchControl.setOn(moveComplete, animated: true)
                    }
            }

            <<< TextRow {
                $0.title = "\tPath"
                $0.tag = defaultConfig?.moveCompletedPath
                $0.value = defaultConfig?.moveCompletedPath
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                $0.hidden = Condition.function([CodingKeys.moveCompleted.rawValue]) { form in
                    return !((form.rowBy(tag: CodingKeys.moveCompleted.rawValue) as? SwitchRow)?.value ?? false)
                }
                }.onChange { [weak self] row in
                    if let value = row.value {
                        self?.defaultConfig?.moveCompletedPath = value
                    }
                }.cellUpdate { [weak self] cell, row in
                    cell.titleLabel?.textColor = cell.row.isValid ? ColorCompatibility.label : .red
                    if !row.wasChanged {
                        row.value = self?.defaultConfig?.moveCompletedPath
                        row.cell.textField?.text = self?.defaultConfig?.moveCompletedPath
                    }

            }

            <<< SwitchRow {
                $0.title = "Add Paused"
                $0.add(rule: RuleRequired())
                $0.value = defaultConfig?.addPaused
                }.onChange { [weak self] row in
                    if let value = row.value {
                        self?.defaultConfig?.addPaused = value
                    }
                }.cellUpdate { [weak self] _, row in

                    if !row.wasChanged {
                        if let paused = self?.defaultConfig?.addPaused {
                            row.cell.switchControl.setOn(paused, animated: true)
                            row.value = self?.defaultConfig?.addPaused
                        }
                    }
            }

            <<< SwitchRow {
                $0.title = "Compact Allocation"
                $0.value = defaultConfig?.compactAllocation
                }.onChange { [weak self] row in
                    if let value = row.value {
                        self?.defaultConfig?.compactAllocation = value
                    }
                }.cellUpdate { [weak self] _, row in

                    if !row.wasChanged {
                        if let compactAllocation = self?.defaultConfig?.compactAllocation {
                            row.cell.switchControl.setOn(compactAllocation, animated: true)
                            row.value = self?.defaultConfig?.compactAllocation
                        }
                    }
            }

            <<< SwitchRow {
                $0.title = "Prioritize First/Last Pieces"
                $0.value = defaultConfig?.prioritizeFirstLastPieces
                }.onChange { [weak self] row in
                    if let value = row.value {
                        self?.defaultConfig?.prioritizeFirstLastPieces = value
                    }
                }.cellUpdate { [weak self] _, row in

                    if !row.wasChanged {
                        if let val = self?.defaultConfig?.prioritizeFirstLastPieces {
                            row.cell.switchControl.setOn(val, animated: true)
                            row.value = self?.defaultConfig?.prioritizeFirstLastPieces
                        }
                    }
        }

    }

    @objc func uploadToServer() {

        if (form.allRows.map { $0.isValid }).contains(false) {
            showAlert(target: self, title: "Validation Error", message: "All fields are mandatory")
            return
        }

        guard
            let torrentName = self.torrentName,
            let torrentHash = self.torrentHash,
            let torrentData = self.torrentData,
            let defaultConfig = self.defaultConfig
            else { return }

        DispatchQueue.main.async {
            MBProgressHUD.showAdded(to: self.view, animated: true)
        }
        switch torrentData {
        case .magnet(let url): addMagnetLink(url: url, hash: torrentHash, config: defaultConfig)
        case .file(let data): addTorrentFile(fileName: torrentName, hash: torrentHash, data: data, config: defaultConfig)
        }
    }

    func addTorrentFile(fileName: String, hash: String, data: Data, config: TorrentConfig) {
        ClientManager.shared.activeClient?.addTorrentFile(fileName: fileName, torrent: data, with: config)
            .ensure { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view, animated: true)
                }
            }
            .done { [weak self] _ in
                guard let self = self else { return }
                self.view.showHUD(title: "Torrent Successfully Added") {
                    if let delegate = self.delegate {
                        delegate.torrentAdded(hash)
                    }
                }
            }.catch { [weak self] _ in
                guard let self = self else { return }
                self.view.showHUD(title: "Failed to Add Torrent", type: .failure)
        }
    }

    func addMagnetLink(url: URL, hash: String, config: TorrentConfig) {
        ClientManager.shared.activeClient?.addTorrentMagnet(url: url, with: config)
            .ensure { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view, animated: true)
                }
            }
            .done { [weak self] _ in
                guard let self = self else { return }
                self.view.showHUD(title: "Torrent Successfully Added") {
                    if let delegate = self.delegate {
                        delegate.torrentAdded(hash)
                    }
                }
            }.catch { [weak self] _ in
                guard let self = self else { return }
                self.view.showHUD(title: "Failed to Add Torrent", type: .failure)
        }
    }

    func getTorrentConfig() {
        guard let client = ClientManager.shared.activeClient else { return }

        attempt { client.authenticateAndConnect() }
        .then { client.getAddTorrentConfig() }
        .done { [weak self] config in
            self?.defaultConfig = config
            self?.form.sectionBy(tag: CodingKeys.bandwidthConfig.rawValue)?.allRows.forEach { $0.updateCell() }
            self?.form.sectionBy(tag: CodingKeys.queueConfig.rawValue)?.allRows.forEach { $0.updateCell() }
        }.catch { [weak self] _ in
                let dismiss = UIAlertAction(title: "Ok", style: .default) { _ in
                    self?.navigationController?.popViewController(animated: true)
                }
                guard let self = self else { return }
                showAlert(target: self, title: "Failure to load config",
                          message: "An error occurred while attempting to load in the default torrent configuration", actionList: [dismiss])
                // swiftlint:disable:previous line_length
        }
    }

}

// MARK: - UIDocumentPickerDelegate
extension AddTorrentViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            DispatchQueue.main.async {
                showAlert(target: self, title: "Error", message: "Unable to open torrent file")
            }
            return
        }
        DispatchQueue.main.async {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            // FIXME: Above Main Thread Checker: UI API called on a background thread
        }
        
        guard
            let torrent = try? Data(contentsOf: url)
        else {
            Logger.error("Failed to create base64 encoded torrent")
            return
        }
        
        torrentData = TorrentData.file(torrent)
        handleFormConfigurationFor(torrent: torrent)
    }
} // swiftlint:disable:this file_length

//
//  TorrentOptionsViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/22/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit
import Eureka
import Houston

class TorrentOptionsViewController: FormViewController, Storyboarded {
    
    // MARK: - Properties
    let hapticEngine = UINotificationFeedbackGenerator()
    weak var delegate: TorrentDetailViewDelegate?
    var torrentData: TorrentMetadata? {
        didSet {
            form.allRows.forEach { row in
                row.updateCell()
                if row.isDisabled {
                    row.evaluateDisabled()
                }
            }
        }
    }

    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - ViewController Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        createEurekaForm()
    }
    
    // MARK: - Action Handler Methods
    func applyChanges() {
        
        if (form.allRows.map { $0.isValid }).contains(false) {
            hapticEngine.notificationOccurred(.warning)
            showAlert(target: self, title: "Validation Error", message: "All fields are mandatory")
        }
        
        let formData = form.values(includeHidden: true)
        guard
            let torrentHash = torrentData?.hash,
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
            .done { [weak self] _ -> Void in
                self?.hapticEngine.notificationOccurred(.success)
                self?.view.showHUD(title: "Updated Torrent Options")
            }
            .catch { [weak self] error -> Void in
                self?.hapticEngine.notificationOccurred(.error)
                self?.view.showHUD(title: "Failed to Update Torrent Options", type: .failure)
                Logger.error(error)
            }
    }
    
    func deleteTorrent() {
        let deleteTorrent = UIAlertAction(title: "Delete Torrent", style: .destructive) { [weak self] _ in
            guard let self = self, let torrentHash = self.torrentData?.hash else { return }
            self.delegate?.removeTorrent(with: torrentHash, removeData: false, onCompletion: self.deleteTorrentCallback(result:onGuiUpdatesComplete:))
        }
        
        let deleteTorrentWithData = UIAlertAction( title: "Delete Torrent with Data", style: .destructive) { [weak self] _ in
            guard let self = self, let torrentHash = self.torrentData?.hash else { return }
            self.delegate?.removeTorrent(with: torrentHash, removeData: true, onCompletion: self.deleteTorrentCallback(result:onGuiUpdatesComplete:))
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        showAlert(target: self, title: "Remove the torrent?", style: .actionSheet,
                  actionList: [deleteTorrent, deleteTorrentWithData, cancel] )
    }
    
    fileprivate func deleteTorrentCallback(result: APIResult<Void>, onGuiUpdatesComplete: @escaping ()->())
        {
            switch result {
            case .success():
                hapticEngine.notificationOccurred(.success)
                
                view.showHUD(title: "Torrent Successfully Deleted") {
                    onGuiUpdatesComplete()
                }

            case .failure(let error):
                self.hapticEngine.notificationOccurred(.error)
                if let error = error as? ClientError {
                    showAlert(target: self, title: "Error", message: error.domain())
                } else {
                    showAlert(target: self, title: "Error", message: error.localizedDescription)
                }
                onGuiUpdatesComplete()
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
                let torrentHash = self?.torrentData?.hash
            else { return }
            self?.hapticEngine.prepare()
            ClientManager.shared.activeClient?.moveTorrent(hash: torrentHash, filepath: filepath)
                .done { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.hapticEngine.notificationOccurred(.success)
                        self?.view.showHUD(title: "Moved Torrent", type: .success)
                    }
                    
                }
                .catch { [weak self] error -> Void in
                    DispatchQueue.main.async {
                        self?.hapticEngine.notificationOccurred(.error)
                        self?.view.showHUD(title: "Failed to Move Torrent", type: .failure)
                    }
                    Logger.error(error)
                }
        }
        
        alert.addAction(moveAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func playPauseTorrent() {
        guard let torrentData = torrentData else { return }
                
        hapticEngine.prepare()
        if torrentData.paused {
            ClientManager.shared.activeClient?.resumeTorrent(withHash: torrentData.hash) { [weak self] result in
                DispatchQueue.main.async {
                    self?.playPauseActionHandler(for: torrentData, with: result)
                }
            }
        } else {
            ClientManager.shared.activeClient?.pauseTorrent(withHash: torrentData.hash) { [weak self] result in
                DispatchQueue.main.async {
                    self?.playPauseActionHandler(for: torrentData, with: result)
                }
            }
        }
    }
    
    fileprivate func playPauseActionHandler(for torrent: TorrentMetadata, with result: APIResult<Void>) {
        
        let row = self.form.rowBy(tag: "PlayPauseBtn") as! ButtonRow
        switch result {
           case .success:
               hapticEngine.notificationOccurred(.success)
               
               if torrent.paused {
                    view.showHUD(title: "Successfully Resumed Torrent")
                    row.cell.textLabel?.text = "Pause Torrent"
                    row.title = "Pause Torrent"
               } else {
                    view.showHUD(title: "Successfully Paused Torrent")
                    row.cell.textLabel?.text = "Resume Torrent"
                    row.title = "Resume Torrent"
               }

           case .failure:
               hapticEngine.notificationOccurred(.error)
               
               if torrent.paused {
                   view.showHUD(title: "Failed To Resume Torrent", type: .failure)
               } else {
                   view.showHUD(title: "Failed to Pause Torrent", type: .failure)
               }
           }
       }
}

extension TorrentOptionsViewController {
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
    
    func createEurekaForm() {
        form +++ Section("Controls")
            <<< ButtonRow {
                $0.title =  (torrentData?.paused ?? false) ? "Resume Torrent" : "Pause Torrent"
                $0.tag = "PlayPauseBtn"
                $0.disabled = Condition(booleanLiteral: torrentData == nil)
            }.onCellSelection { [weak self] _, _ in
                self?.playPauseTorrent()
            }
            <<< ButtonRow {
                $0.title = "Move Storage"
                $0.tag = "MoveBtn"
                $0.disabled = Condition(booleanLiteral: torrentData == nil)
            }.onCellSelection { [weak self] _, _ in
                self?.moveStorage()
            }
            <<< ButtonRow {
                $0.title = "Delete Torrent"
                $0.tag = "DeleteBtn"
                $0.baseCell.tintColor = .systemRed
                $0.disabled = Condition(booleanLiteral: torrentData == nil)
            }.onCellSelection { [weak self] _, _ in
                self?.deleteTorrent()
            }
        
        form +++ Section("Bandwidth")
            <<< IntRow {
                $0.title = "Max Download Speed (KiB/s)"
                $0.tag = TorrentOptionsCodingKeys.maxDownloadSpeed.rawValue
                $0.disabled = true
                $0.value = Int(torrentData?.max_download_speed ?? -1)
                $0.cell.textField.text = "\(Int(torrentData?.max_download_speed ?? -1))"
                $0.cell.textField.keyboardType = .numbersAndPunctuation
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }.cellUpdate { [weak self] cell, _ in
                cell.titleLabel?.textColor = cell.row.isValid ? ColorCompatibility.label : .red
                if let torrentData = self?.torrentData {
                    cell.row.disabled = false
                    if !cell.row.wasChanged {
                        cell.textField.text = "\(Int(torrentData.max_download_speed))"
                        cell.row.value = Int(torrentData.max_download_speed)
                    }
                }
                
            }
            
            <<< IntRow {
                $0.title  = "Max Upload Speed (KiB/s)"
                $0.tag = TorrentOptionsCodingKeys.maxUploadSpeed.rawValue
                $0.disabled = true
                $0.cell.textField.text = "\(Int(torrentData?.max_upload_speed ?? -1))"
                $0.value = Int(torrentData?.max_upload_speed ?? -1)
                $0.cell.textField.keyboardType = .numbersAndPunctuation
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }.cellUpdate { [weak self] cell, _ in
                cell.titleLabel?.textColor = cell.row.isValid ? ColorCompatibility.label : .red
                if let torrentData = self?.torrentData {
                    cell.row.disabled = false
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
                $0.disabled = true
                $0.cell.textField.text = "\(torrentData?.max_connections ?? -1)"
                $0.cell.textField.keyboardType = .numbersAndPunctuation
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }.cellUpdate { [weak self] cell, _ in
                cell.titleLabel?.textColor = cell.row.isValid ? ColorCompatibility.label : .red
                if let torrentData = self?.torrentData {
                    cell.row.disabled = false
                    if !cell.row.wasChanged {
                        cell.textField.text = "\(torrentData.max_connections)"
                        cell.row.value = torrentData.max_connections
                    }
                }
            }
            
            <<< IntRow {
                $0.title  = "Max Upload Slots"
                $0.tag = TorrentOptionsCodingKeys.maxUploadSlots.rawValue
                $0.disabled = true
                $0.value = torrentData?.max_upload_slots
                $0.cell.textField.text = "\(torrentData?.max_upload_slots ?? -1)"
                $0.cell.textField.keyboardType = .numbersAndPunctuation
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }.cellUpdate { [weak self] cell, _ in
                cell.titleLabel?.textColor = cell.row.isValid ? ColorCompatibility.label : .red
                if let torrentData = self?.torrentData {
                    cell.row.disabled = false
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
                $0.disabled = true
                $0.tag = TorrentOptionsCodingKeys.autoManaged.rawValue
            }
            .cellUpdate { [weak self] cell, _ in
                cell.textLabel?.textColor = ColorCompatibility.label
                if let torrentData = self?.torrentData {
                    cell.row.disabled = false
                    if !cell.row.wasChanged {
                        cell.switchControl.setOn(torrentData.is_auto_managed, animated: true)
                        cell.row.value = torrentData.is_auto_managed
                    }
                }
            }
            
            <<< SwitchRow {
                $0.title = "Stop Seed at Ratio"
                $0.disabled = true
                $0.tag = TorrentOptionsCodingKeys.stopSeedAtRatio.rawValue
                $0.value = torrentData?.stop_at_ratio.value
            }.cellUpdate { [weak self] cell, _ in
                cell.textLabel?.textColor = ColorCompatibility.label
                if let torrentData = self?.torrentData {
                    cell.row.disabled = false
                    if !cell.row.wasChanged {
                        cell.row.value = torrentData.stop_at_ratio.value
                        cell.switchControl.setOn(torrentData.stop_at_ratio.value, animated: true)
                    }
                }
            }
            
            <<< DecimalRow {
                $0.title  = "\tStop Ratio"
                $0.tag = TorrentOptionsCodingKeys.stopRatio.rawValue
                $0.value = torrentData?.stop_ratio
                $0.disabled = true
                $0.hidden = Condition.function([TorrentOptionsCodingKeys.stopSeedAtRatio.rawValue]) { form -> Bool in
                    return !((form.rowBy(tag:
                                            TorrentOptionsCodingKeys.stopSeedAtRatio.rawValue)
                                as? SwitchRow)?.value ?? false)
                }
                $0.cell.textField.keyboardType = .numbersAndPunctuation
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
            }.cellUpdate { [weak self] cell, _ in
                cell.titleLabel?.textColor = cell.row.isValid ? ColorCompatibility.label : .red
                if let torrentData = self?.torrentData {
                    cell.row.disabled = false
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
                $0.disabled = true
                $0.hidden = Condition.function([TorrentOptionsCodingKeys.stopSeedAtRatio.rawValue]) { form -> Bool in
                    return !((form.rowBy(tag:
                                            TorrentOptionsCodingKeys.stopSeedAtRatio.rawValue)
                                as? SwitchRow)?.value ?? false)
                }
            }.cellUpdate { [weak self] cell, _ in
                cell.textLabel?.textColor = ColorCompatibility.label
                if let torrentData = self?.torrentData {
                    cell.row.disabled = false
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
                $0.disabled = true
            }.cellUpdate { [weak self] cell, _ in
                cell.textLabel?.textColor = ColorCompatibility.label
                if let torrentData = self?.torrentData {
                    cell.row.disabled = false
                    if !cell.row.wasChanged {
                        cell.row.value = torrentData.move_completed.value
                        cell.switchControl.setOn(torrentData.move_completed.value, animated: true)
                    }
                }
            }
            
            <<< TextRow {
                $0.title = "\tPath"
                $0.tag = TorrentOptionsCodingKeys.moveCompletedPath.rawValue
                $0.disabled = true
                $0.value = torrentData?.move_completed_path
                $0.hidden = Condition.function([TorrentOptionsCodingKeys.moveCompleted.rawValue]) { form -> Bool in
                    return !((form.rowBy(tag:
                                            TorrentOptionsCodingKeys.moveCompleted.rawValue) as? SwitchRow)?
                                .value ?? false)
                }
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                
            }.cellUpdate { [weak self] cell, _ in
                cell.titleLabel?.textColor = cell.row.isValid ? ColorCompatibility.label : .red
                if let torrentData = self?.torrentData {
                    cell.row.disabled = false
                    if !cell.row.wasChanged {
                        cell.row.value = torrentData.move_completed_path
                        cell.textField.text = torrentData.move_completed_path
                    }
                }
            }
            
            <<< SwitchRow {
                $0.title = "Prioritize First/Last Pieces"
                $0.tag = TorrentOptionsCodingKeys.prioritizeFirstLastPieces.rawValue
                $0.disabled = true
                $0.value = torrentData?.prioritize_first_last
            }.cellUpdate { [weak self] cell, _ in
                cell.textLabel?.textColor = ColorCompatibility.label
                
                if let torrentData = self?.torrentData {
                    cell.row.disabled = false
                    if !cell.row.wasChanged {
                        cell.row.value = torrentData.prioritize_first_last
                        cell.switchControl.setOn(torrentData.prioritize_first_last, animated: true)
                    }
                }
            }
        
        
        form +++ Section()
            <<< ButtonRow {
                $0.title = "Apply Settings"
                $0.disabled = Condition(booleanLiteral: torrentData == nil)
                $0.tag = "ApplyBtn"
            }.onCellSelection { [weak self] _, _ in
                self?.applyChanges()
            }
    }
}

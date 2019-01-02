//
//  AddTorrentViewController.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 1/1/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import Eureka
import UIKit

class AddTorrentViewController: FormViewController {

    var defaultConfig: TorrentConfig?

    enum CodingKeys: String {
        case selectionSection
        case torrentType
        case magnetURL
        // Torrent Config
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
        populateTorrentTypeSelection()
    }

    // swiftlint:disable:next function_body_length
    func populateTorrentTypeSelection() {
        form +++ Section {
            $0.tag = CodingKeys.selectionSection.rawValue
            $0.header?.title = "Select Torrent Source"
            }

            <<< SegmentedRow<String> {
                $0.tag = CodingKeys.torrentType.rawValue
                $0.options = ["Magnet Link", "Torrent File"]
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
                    ClientManager.shared.activeClient?.getMagnetInfo(url: url).then { output -> Void in
                        DispatchQueue.main.async {
                            self?.showTorrentConfig(name: output.name, hash: output.hash)
                        }
                        }.catch { _ in
                            let dismiss = UIAlertAction(title: "Ok", style: .default) { _ in
                                self?.navigationController?.popViewController(animated: true)
                            }
                            if let self = self {
                                showAlert(target: self, title: "Failure to load magnet URL",
                                          message: "An error occurred while attempting to load the magnet URL", actionList: [dismiss])
                                // swiftlint:disable:previous line_length
                            }

                    }
        }
    }

    // swiftlint:disable:next function_body_length
    func showTorrentConfig(name: String, hash: String) {
        form.sectionBy(tag: CodingKeys.selectionSection.rawValue)?.hidden = true
        form.sectionBy(tag: CodingKeys.selectionSection.rawValue)?.evaluateHidden()

        form +++ Section("Torrent Info")
            <<< LabelRow {
                $0.title = name
            }
            <<< LabelRow {
                $0.title = hash
        }

        form +++ Section("Torrent Configuration")
            <<< TextRow {
                $0.title = "Download Location:"
                $0.tag = CodingKeys.downloadLocation.rawValue
                $0.add(rule: RuleRequired())
                $0.value = defaultConfig?.downloadLocation
            }
            <<< SwitchRow {
                $0.title = "Move Completed:"
                $0.tag = CodingKeys.moveCompleted.rawValue
                $0.value = defaultConfig?.moveCompleted ?? false
            }
            <<< TextRow {
                $0.title = "Move Completed Path:"
                $0.tag = defaultConfig?.moveCompletedPath
                $0.value = defaultConfig?.moveCompletedPath
                $0.hidden = Condition.function([CodingKeys.moveCompleted.rawValue]) { form in
                    return !((form.rowBy(tag: CodingKeys.moveCompleted.rawValue) as? SwitchRow)?.value ?? false)
                }
            }

            <<< IntRow {
                $0.title = "Max Upload Speed:"
                $0.value = defaultConfig?.maxUploadSpeed ?? -1
                $0.add(rule: RuleRequired())
            }
            <<< IntRow {
                $0.title = "Max Download Speed:"
                $0.value = defaultConfig?.maxDownloadSpeed ?? -1
                $0.add(rule: RuleRequired())
            }
            <<< IntRow {
                $0.title = "Max Connections:"
                $0.value = defaultConfig?.maxConnections ?? -1
                $0.add(rule: RuleRequired())
            }
            <<< IntRow {
                $0.title = "Max Upload Slots:"
                $0.value = defaultConfig?.maxUploadSlots ?? -1
                $0.add(rule: RuleRequired())
            }

            <<< SwitchRow {
                $0.title = "Add Paused:"
                $0.value = defaultConfig?.addPaused ?? false
                $0.add(rule: RuleRequired())
            }
            <<< SwitchRow {
                $0.title = "Compact Allocation:"
                $0.value = defaultConfig?.compactAllocation ?? false
                $0.add(rule: RuleRequired())
            }
            <<< SwitchRow {
                $0.title = "Prioritize First/Last Pieces:"
                $0.value = defaultConfig?.prioritizeFirstLastPieces ?? false
                $0.add(rule: RuleRequired())
        }

        form +++ Section()
            <<< ButtonRow {
                $0.title = "Add Torrent"
            }.onCellSelection { [weak self] _, _ in
                print("Should Add Torrent")
                guard
                    let url = self?.form.values()[CodingKeys.magnetURL.rawValue] as? URL,
                    let type = self?.form.values()[CodingKeys.torrentType.rawValue] as? String
                else { return }

                // TODO: Get the form values and convert to Torrent Config

                if type == "Magnet Link" {

                    // ClientManager.shared.activeClient?.addTorrentMagnet(url: url, with: <#T##TorrentConfig#>)
                }
            }
    }

    func getTorrentConfig() {
        ClientManager.shared.activeClient?.getAddTorrentConfig().then { config in
            self.defaultConfig = config
            }.catch { _ in
                let dismiss = UIAlertAction(title: "Ok", style: .default) { _ in
                    self.navigationController?.popViewController(animated: true)
                }
                showAlert(target: self, title: "Failure to load config",
                          message: "An error occurred while attempting to load in the default torrent configuration", actionList: [dismiss])
                // swiftlint:disable:previous line_length
        }
    }

}

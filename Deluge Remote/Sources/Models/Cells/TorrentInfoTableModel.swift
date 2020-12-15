//
//  TorrentInfoTableModel.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/15/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit

struct DefaultCellData {
    var label: String?
    var detail: String?
}

class TorrentInfoSection {
    var data: [DefaultCellData]  = []
    
    var torrent: TorrentMetadata? {
        didSet {
            buildData()
        }
    }
    
    func rowsCount() -> Int {
        return data.count
    }
    
    func titleForHeader() -> String? {
        return nil
    }
    
    func buildData() {}
    
    func cell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath) as! DefaultTableViewCell
        cell.label.text = data[indexPath.row].label
        cell.detail.text = data[indexPath.row].detail
        return cell
    }
    
}

class TorrentInfoBasicSection: TorrentInfoSection {
    
    override func titleForHeader() -> String? {
        return "Basic Information"
    }
    
    override func buildData() {
        guard let torrent = torrent else { return }
        data.removeAll()
        data.append(DefaultCellData(label: "Name", detail: torrent.name))
        data.append(DefaultCellData(label: "State", detail: torrent.state))
        if torrent.eta != 0, let eta = torrent.eta.timeRemainingString() {
            data.append(DefaultCellData(label: "ETA", detail: eta))
        }
        data.append(DefaultCellData(label: "Completed", detail: "\(torrent.progress.description)%"))
        data.append(DefaultCellData(label: "Size", detail: torrent.total_size.sizeString()))
        data.append(DefaultCellData(label: "Ratio", detail: String(format: "%.3f", torrent.ratio.roundTo(places: 3))))
        data.append(DefaultCellData(label: "Status", detail: torrent.message))
    }
}

class TorrentInfoDownloadSection: TorrentInfoSection {
    
    
    override func titleForHeader() -> String? {
        return "Download Information"
    }
    
    override func buildData() {
        guard let torrent = torrent else { return }
        data.removeAll()
        data.append(DefaultCellData(label: "Downloaded", detail: torrent.all_time_download?.sizeString()))
        data.append(DefaultCellData(label: "Uploaded", detail: torrent.total_uploaded.sizeString()))
        data.append(DefaultCellData(label: "Download Speed", detail: torrent.download_payload_rate.transferRateString()))
        data.append(DefaultCellData(label: "Upload Speed", detail: torrent.upload_payload_rate.transferRateString()))
    }
    
}

class TorrentInfoTrackerSection: TorrentInfoSection {
    override func titleForHeader() -> String? {
        return "Tracker Info"
    }
    
    override func buildData() {
        guard let torrent = torrent else { return }
        data.removeAll()
        
        data.append(DefaultCellData(label: "Tracker", detail: torrent.tracker_host))
        data.append(DefaultCellData(label: "Tracker Status", detail: torrent.tracker_status))
        data.append(DefaultCellData(label: "Next Announce", detail: torrent.next_announce.timeRemainingString(unitStyle: .abbreviated)!))
        data.append(DefaultCellData(label: "Seeds Connected", detail: "\(torrent.num_seeds) (\(torrent.total_seeds))"))
        
        // TODO: Implement the equivalent of a disclosure group here
    }
}

class TorrentInfoAdditionalSection: TorrentInfoSection {
    override func titleForHeader() -> String? {
        return "Additional Information"
    }
    
    override func buildData() {
        guard let torrent = torrent else { return }
        data.removeAll()
        if let activeTime = torrent.active_time?.toTimeString() {
            data.append(DefaultCellData(label: "Active Time", detail:  activeTime))
        }
        if let seedTime = torrent.seeding_time.toTimeString()
        {
            data.append(DefaultCellData(label: "Seeding Time", detail: seedTime))
        }
        
        data.append(DefaultCellData(label: "Auto Managed", detail: torrent.is_auto_managed ? "True" : "False"))
        data.append(DefaultCellData(label: "Pieces", detail: "\(torrent.num_pieces) (\(Int(torrent.piece_length).sizeString()))"))
        data.append(DefaultCellData(label: "Hash", detail: torrent.hash))
        if !torrent.comment.isEmpty
        {
            data.append(DefaultCellData(label: "Comments", detail: torrent.comment))
        }
    }
}

// MARK: - TorrentInfoModel
class TorrentInfoModel {
    
    // MARK: - Properties
    private var sections: [TorrentInfoSection] =
        [TorrentInfoBasicSection(), TorrentInfoDownloadSection(), TorrentInfoTrackerSection(), TorrentInfoAdditionalSection()]
    
    public var sectionCount: Int {
        return sections.count
    }
    
    public var torrent: TorrentMetadata? {
        didSet {
            updateModel()
        }
    }
    
    private func updateModel() {
        guard let torrent = torrent else { return }
        
        for section in sections {
            section.torrent = torrent
        }
    }
    
    // MARK: - Public UITableViewDataSource functions
    
    /// Returns the row count for a given section in the model
    public func rowCount(for section: Int) -> Int {
        if section > sectionCount {
            return 0
        } else {
            return sections[section].rowsCount()
        }
    }
    
    public func sectionHeaderTitle(for section: Int) -> String? {
        if section > sectionCount {
            return nil
        } else {
            return sections[section].titleForHeader()
        }
    }
    
    /// Returns the cell for a given indexpath
    func cell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        sections[indexPath.section].cell(for: tableView, at: indexPath)
    }
    
}


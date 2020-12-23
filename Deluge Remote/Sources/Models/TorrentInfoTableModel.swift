//
//  TorrentInfoTableModel.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/15/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit

protocol TVCellBuilder: AnyObject {
    func cell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell
}


class TorrentInfoSection {
    
    // Properties
    fileprivate var cells: [TVCellBuilder]  = []
    
    public var torrent: TorrentMetadata? {
        didSet {
            updateData()
        }
    }
    
    public var onRowsAdded: ((_ rows: [Int]) -> ())?
    public var onRowsRemoved: ((_ rows: [Int]) -> ())?
    
    fileprivate var sectionUpdate: (()->())?
    
    init(onSectionUpdate: (()->())? = nil) {
        self.sectionUpdate = onSectionUpdate
    }
    
    func rowsCount() -> Int {
        return cells.count
    }
    
    func titleForHeader() -> String? {
        return nil
    }
    
    func updateData() {}
    
    func cell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        return cells[indexPath.row].cell(for: tableView, at: indexPath)
    }
    
}

class TorrentInfoBasicSection: TorrentInfoSection {
    
    override func titleForHeader() -> String? {
        return "Basic Information"
    }
    
    override func updateData() {
        guard let torrent = torrent else { return }
        cells.removeAll()
        cells.append(DefaultCell(label: "Name", detail: torrent.name))
        cells.append(DefaultCell(label: "State", detail: torrent.state))
        if torrent.eta != 0, let eta = torrent.eta.timeRemainingString() {
            cells.append(DefaultCell(label: "ETA", detail: eta))
        }
        cells.append(DefaultCell(label: "Completed", detail: "\(torrent.progress.description)%"))
        cells.append(DefaultCell(label: "Size", detail: torrent.total_size.sizeString()))
        cells.append(DefaultCell(label: "Ratio", detail: String(format: "%.3f", torrent.ratio.roundTo(places: 3))))
        cells.append(DefaultCell(label: "Status", detail: torrent.message))
    }
}

class TorrentInfoDownloadSection: TorrentInfoSection {
    
    
    override func titleForHeader() -> String? {
        return "Download Information"
    }
    
    override func updateData() {
        guard let torrent = torrent else { return }
        cells.removeAll()
        cells.append(DefaultCell(label: "Downloaded", detail: torrent.all_time_download?.sizeString()))
        cells.append(DefaultCell(label: "Uploaded", detail: torrent.total_uploaded.sizeString()))
        cells.append(DefaultCell(label: "Download Speed", detail: torrent.download_payload_rate.transferRateString()))
        cells.append(DefaultCell(label: "Upload Speed", detail: torrent.upload_payload_rate.transferRateString()))
    }
    
}

class TorrentInfoTrackerSection: TorrentInfoSection {
    
    private let tracker = DefaultCell(label: "Peers Connected", detail: nil)
    private let trackerStatus = DefaultCell(label: "Tracker Status", detail: nil)
    private let announce = DefaultCell(label: "Next Announce", detail: nil)
    private let seeds = DefaultCell(label: "Seeds Connected", detail: nil)
    private lazy var peers: ChevronCell = {
        return ChevronCell(label: "Peers Connected", detail: nil) { [weak self] state in
            self?.peerRowStateChange(state: state)
        }
    }()
    
    var peerSubSection: [TVCellBuilder] = []
    var coreCells: [TVCellBuilder] = []
    
    override func titleForHeader() -> String? {
        return "Tracker Info"
    }
    
    override func updateData() {
        guard let torrent = torrent else { return }
        
        tracker.detail = torrent.tracker_host
        trackerStatus.detail = torrent.tracker_status
        announce.detail = torrent.next_announce.timeRemainingString(unitStyle: .abbreviated)!
        seeds.detail = "\(torrent.num_seeds) (\(torrent.total_seeds))"
        peers.detail = "\(torrent.num_peers) (\(torrent.total_peers))"
        
        if coreCells.isEmpty {
            coreCells.append(tracker)
            coreCells.append(trackerStatus)
            coreCells.append(announce)
            coreCells.append(seeds)
            coreCells.append(peers)
        }
        if cells.isEmpty {
            cells.append(contentsOf: coreCells)
        }
        
        peerSubSection.removeAll()
        for peer in torrent.peers {
            let cell = TorrentPeerTableViewCellData(peer: peer)
            peerSubSection.append(cell)
        }
        
        if peers.state == .Expanded {
            let oldSize = cells.count
            let newSize = coreCells.count + peerSubSection.count
            
            if oldSize < newSize {
                print("Rows Added old:\(oldSize) new:\(newSize)")
                
                cells.removeLast(oldSize - coreCells.count)
                cells.append(contentsOf: peerSubSection)
                if let onRowsAdded = onRowsAdded {
                    onRowsAdded(Array(oldSize...newSize-1))
                }
            } else if (oldSize > newSize) {
                // Rows were removed
                print("Rows Removed old:\(oldSize) new:\(newSize)")
                
                cells.removeLast(oldSize - coreCells.count)
                cells.append(contentsOf: peerSubSection)
                if let onRowsRemoved = onRowsRemoved {
                    onRowsRemoved(Array(newSize...oldSize-1))
                }
            } else {
                // Row size is the same so just replace the data
                if oldSize > coreCells.count {
                    cells.removeLast(cells.count-coreCells.count)
                    cells.append(contentsOf: peerSubSection)
                }
            }
            
        }
       
    }
    
    func peerRowStateChange(state: ChevronTableViewCell.State) {
        if state == .Default {
            let end = cells.count
            if end > 5 {
                cells.removeSubrange(5...end-1)
                if let onRowsRemoved = onRowsRemoved {
                    onRowsRemoved(Array(5...end-1))
                }
            }
            
        } else {
            if !peerSubSection.isEmpty {
                cells.append(contentsOf: peerSubSection)
                if let onRowsAdded = onRowsAdded {
                    onRowsAdded(Array(5...cells.count-1))
                }
            }
        }
    }
}

class TorrentInfoAdditionalSection: TorrentInfoSection {
    override func titleForHeader() -> String? {
        return "Additional Information"
    }
    
    override func updateData() {
        guard let torrent = torrent else { return }
        cells.removeAll()
        if let activeTime = torrent.active_time?.toTimeString() {
            cells.append(DefaultCell(label: "Active Time", detail:  activeTime))
        }
        if let seedTime = torrent.seeding_time.toTimeString()
        {
            cells.append(DefaultCell(label: "Seeding Time", detail: seedTime))
        }
        
        cells.append(DefaultCell(label: "Auto Managed", detail: torrent.is_auto_managed ? "True" : "False"))
        cells.append(DefaultCell(label: "Pieces", detail: "\(torrent.num_pieces) (\(Int(torrent.piece_length).sizeString()))"))
        cells.append(DefaultCell(label: "Hash", detail: torrent.hash))
        if !torrent.comment.isEmpty
        {
            cells.append(DefaultCell(label: "Comments", detail: torrent.comment))
        }
    }
}

// MARK: - TorrentInfoModel
class TorrentInfoModel {
    
    // MARK: - Properties
    private let sections: [TorrentInfoSection] = [TorrentInfoBasicSection(), TorrentInfoDownloadSection(), TorrentInfoTrackerSection(), TorrentInfoAdditionalSection()]
    
    /// Closure will be called when a section adds rows
    public var onRowsAdded: ((_ indexPaths: [IndexPath]) -> ())? {
        didSet {
            for (sectionIndex, section) in sections.enumerated() {
                section.onRowsAdded = { [weak self] rows in
                    if let onRowsAdded = self?.onRowsAdded {
                        let indexPaths = rows.map{ IndexPath(row: $0, section: sectionIndex) }
                        onRowsAdded(indexPaths)
                    }
                }
            }
        }
    }
    
    /// Closure will be called when a section remvoes rows
    public var onRowsRemoved: ((_ indexPaths: [IndexPath]) -> ())? {
        didSet {
            for (sectionIndex, section) in sections.enumerated() {
                section.onRowsRemoved = { [weak self] rows in
                    if let onRowsRemoved = self?.onRowsRemoved {
                        let indexPaths = rows.map{ IndexPath(row: $0, section: sectionIndex) }
                        onRowsRemoved(indexPaths)
                    }
                }
            }
        }
    }
    
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


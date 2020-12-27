//
//  TorrentInfoTableModel.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/15/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit
import Houston

class TorrentInfoSection: TableViewSection {
    
    public var torrent: TorrentMetadata? {
        didSet {
            updateData()
        }
    }
}

class TorrentInfoBasicSection: TorrentInfoSection {
    
    override func titleForHeader() -> String? {
        return "Basic Info"
    }
    
    private let nameCell = DefaultCell(label: "Name", detail: nil)
    private let stateCell = DefaultCell(label: "State", detail: nil)
    private let etaCell = DefaultCell(label: "ETA", detail: nil)
    private let completedCell = DefaultCell(label: "Completed", detail: nil)
    private let sizeCell = DefaultCell(label: "Size", detail: nil)
    private let statusCell = DefaultCell(label: "Status", detail: nil)
    
    override func updateData() {
        guard let torrent = torrent else { return }
        
        nameCell.detail = torrent.name
        stateCell.detail = torrent.state
        etaCell.detail = torrent.eta.timeRemainingString()
        completedCell.detail = String(format: "%.1f%%", torrent.progress)
        sizeCell.detail = torrent.total_size.sizeString()
        statusCell.detail = torrent.message
        
        if cells.isEmpty {
            cells.append(nameCell)
            cells.append(stateCell)
            cells.append(sizeCell)
            if torrent.eta != 0 {
                cells.append(etaCell)
            }
            if torrent.progress < 100 {
                cells.append(completedCell)
            }
            cells.append(statusCell)
        }
        
        var defaultCells = cells.compactMap { $0 as? DefaultCell }
        var containsETA = defaultCells.enumerated().first { $0.element.label == etaCell.label }
        var containsProgress = defaultCells.enumerated().first { $0.element.label == completedCell.label }
        
        var indexAdded: [Int] = []
        var indexRemoved: [Int] = []
        
        if torrent.eta != 0 {
            if containsETA == nil {
                cells.insert(etaCell, at: 3)
                indexAdded.append(3)
            }
        } else {
            if let eta = containsETA {
                cells.remove(at: eta.offset)
                indexRemoved.append(eta.offset)
            }
        }
        
        defaultCells = cells.compactMap { $0 as? DefaultCell }
        containsETA = defaultCells.enumerated().first { $0.element.label == etaCell.label }
        containsProgress = defaultCells.enumerated().first { $0.element.label == completedCell.label }
        
        if torrent.progress < 100 {
            if containsProgress == nil {
                var index = 3
                if let eta = containsETA {
                    index = eta.offset + 1
                }
                cells.insert(completedCell, at: index)
                indexAdded.append(index)
            }
        } else {
            if let progress = containsProgress {
                cells.remove(at: progress.offset)
                indexRemoved.append(progress.offset)
            }
        }
        
        if !indexAdded.isEmpty {
            if let onRowsAdded = onRowsAdded {
                onRowsAdded(indexAdded)
            }
        }
        
        if !indexRemoved.isEmpty {
            if let onRowsRemoved = onRowsRemoved {
                onRowsRemoved(indexRemoved)
            }
        }

    }
}

class TorrentInfoDownloadSection: TorrentInfoSection {
    
    
    override func titleForHeader() -> String? {
        return "Download Info"
    }
    
    override func updateData() {
        guard let torrent = torrent else { return }
        cells.removeAll()
        cells.append(DefaultCell(label: "Downloaded", detail: torrent.all_time_download?.sizeString()))
        cells.append(DefaultCell(label: "Uploaded", detail: torrent.total_uploaded.sizeString()))
        cells.append(DefaultCell(label: "Ratio", detail: String(format: "%.3f", torrent.ratio.roundTo(places: 3))))
        cells.append(DefaultCell(label: "Download Speed", detail: torrent.download_payload_rate.transferRateString()))
        cells.append(DefaultCell(label: "Upload Speed", detail: torrent.upload_payload_rate.transferRateString()))
    }
    
}

class TorrentInfoTrackerSection: TorrentInfoSection {
    
    private let tracker = DefaultCell(label: "Tracker", detail: nil)
    private let trackerStatus = DefaultCell(label: "Tracker Status", detail: nil)
    private let announce = DefaultCell(label: "Next Announce", detail: nil)
    private let seeds = DefaultCell(label: "Seeds Connected", detail: nil)
    private lazy var peers: ChevronCell = {
        return ChevronCell(label: "Peers Connected", detail: nil) { [weak self] state in
            self?.peerRowStateChange(state: state)
        }
    }()
    
    var peerSubSection: [TableViewCellBuilder] = []
    var coreCells: [TableViewCellBuilder] = []
    
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
                Logger.debug("Rows Added old:\(oldSize) new:\(newSize)")
                
                cells.removeLast(oldSize - coreCells.count)
                cells.append(contentsOf: peerSubSection)
                if let onRowsAdded = onRowsAdded {
                    Logger.debug(Array(oldSize...newSize-1))
                    onRowsAdded(Array(oldSize...newSize-1))
                }
            } else if (oldSize > newSize) {
                // Rows were removed
                Logger.debug("Rows Removed old:\(oldSize) new:\(newSize)")
                
                cells.removeLast(oldSize - coreCells.count)
                cells.append(contentsOf: peerSubSection)
                if let onRowsRemoved = onRowsRemoved {
                    Logger.debug(Array(newSize...oldSize-1))
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
        return "Additional Info"
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
        
        cells.append(DefaultCell(label: "Path", detail: torrent.save_path))
        cells.append(DefaultCell(label: "Pieces", detail: "\(torrent.num_pieces) (\(Int(torrent.piece_length).sizeString()))"))
        cells.append(DefaultCell(label: "Hash", detail: torrent.hash))
        if !torrent.comment.isEmpty
        {
            cells.append(DefaultCell(label: "Comments", detail: torrent.comment))
        }
    }
}

// MARK: - TorrentInfoModel
class TorrentInfoModel: TableViewModel {
    
    /// Closure will be called when a section adds rows
    public var onRowsAdded: ((_ indexPaths: [IndexPath]) -> ())? {
        didSet {
            for (sectionIndex, section) in sections.enumerated() {
                section.onRowsAdded = { [weak self] rows in
                    if let onRowsAdded = self?.onRowsAdded {
                        let indexPaths = rows.map{ IndexPath(row: $0, section: sectionIndex) }
                        Logger.debug("Asking to add \(indexPaths.count) rows")
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
                        Logger.debug("Asking to remove \(indexPaths.count) rows")
                        onRowsRemoved(indexPaths)
                    }
                }
            }
        }
    }
    
    public var torrent: TorrentMetadata? {
        didSet {
            updateModel()
        }
    }
    
    override init() {
        super.init()
        sections = [TorrentInfoBasicSection(), TorrentInfoDownloadSection(), TorrentInfoTrackerSection(), TorrentInfoAdditionalSection()]
    }
    
    override func updateModel() {
        guard let torrent = torrent else { return }
        
        for section in sections {
            if let section = section as? TorrentInfoSection {
                section.torrent = torrent
            }
        }
    }
}


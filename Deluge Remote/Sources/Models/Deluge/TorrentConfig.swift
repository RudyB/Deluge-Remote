//
//  TorrentConfig.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 1/1/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import Foundation

struct TorrentConfig: Decodable {
    var addPaused: Bool
    var maxDownloadSpeed: Int
    var prioritizeFirstLastPieces: Bool
    var maxUploadSpeed: Int
    var maxConnections: Int
    var moveCompletedPath: String
    var downloadLocation: String
    var compactAllocation: Bool?
    var moveCompleted: Bool
    var maxUploadSlots: Int

    enum CodingKeys: String, CodingKey {
        case addPaused = "add_paused"
        case maxDownloadSpeed = "max_download_speed_per_torrent"
        case prioritizeFirstLastPieces = "prioritize_first_last_pieces"
        case maxUploadSpeed = "max_upload_speed_per_torrent"
        case maxConnections = "max_connections_per_torrent"
        case moveCompletedPath = "move_completed_path"
        case downloadLocation = "download_location"
        case compactAllocation = "compact_allocation"
        case moveCompleted = "move_completed"
        case maxUploadSlots = "max_upload_slots_per_torrent"
    }

    func toParams() -> JSON {
        var params: JSON = [
            "file_priorities": [],
            "add_paused": addPaused,
            "move_completed": moveCompleted,
            "download_location": downloadLocation,
            "move_completed_path": moveCompletedPath,
            "max_connections": maxConnections,
            "max_download_speed": maxDownloadSpeed,
            "max_upload_slots": maxUploadSlots,
            "max_upload_speed": maxUploadSpeed,
            "prioritize_first_last_pieces": prioritizeFirstLastPieces
        ]
        if let compactAllocation = compactAllocation {
            params["compact_allocation"] = compactAllocation
        }
        return params
    }
}

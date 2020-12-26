//
//  Torrent.swift
//
//
//  Created by Rudy Bermudez on 7/16/16.
//
//

import Foundation

struct TorrentMetadata: Decodable {
    let active_time: Double?
    let all_time_download: Int?
    let compact: Bool?
    let distributed_copies: Double?
    let download_payload_rate: Int
    let file_priorities: [Double]
    let hash: String
    let is_auto_managed: Bool
    let is_finished: Bool
    let max_connections: Int
    let max_download_speed: Double
    let max_upload_slots: Int
    let max_upload_speed: Double
    let message: String
    let move_on_completed_path: String
    let move_on_completed: DelugeBool
    let move_completed_path: String
    let move_completed: DelugeBool
    let next_announce: Double
    let num_peers: Int
    let num_seeds: Int
    let paused: Bool
    let label: String?
    let prioritize_first_last: Bool
    let progress: Double
    let remove_at_ratio: Bool
    let save_path: String
    let seeding_time: Double
    let seeds_peers_ratio: Double
    let seed_rank: Int
    /// Torrent state e.g. Paused, Downloading, etc.
    let state: String // Turn this into enum
    let stop_at_ratio: DelugeBool
    let stop_ratio: Double
    let time_added: Double
    let total_done: Int
    let total_payload_download: Double
    let total_payload_upload: Double
    let total_peers: Int
    let total_seeds: Int
    let total_uploaded: Int
    let total_wanted: Double
    let tracker: String
    let trackers: [TrackerMetadata]
    let tracker_status: String
    let upload_payload_rate: Int
    let comment: String
    let eta: Double
    let file_progress: DelugeFileProgress
    let files: [FileMetadata]
    let is_seed: Bool
    let name: String
    let num_files: Int
    let num_pieces: Int
    let peers: [PeerMetadata]
    let piece_length: Double
    let `private`: Bool
    let queue: Int // Usually -1
    let ratio: Double
    let total_size: Int
    let tracker_host: String
}

struct FileMetadata: Decodable {
    let index: Int
    let path: String
    let offset: Int
    let size: Int
}

struct PeerMetadata: Decodable {
    let down_speed: Int
    let ip: String
    let up_speed: Int
    let client: String
    let country: String
    let progress: Double
    let seed: Int
}

struct TrackerMetadata: Decodable {
    let send_stats: Bool?
    let fails: Int?
    let verified: Bool
    let scrape_incomplete: Int?
    let min_announce: Int?
    let scrape_downloaded: Int?
    let url: String
    let last_error: ErrorMetadata?
    let fail_limit: Int
    let next_announce: Int?
    let complete_sent: Bool
    let source: Int
    let trackerid: String?
    let start_sent: Bool
    let tier: Int
    let scrape_complete: Int?
    let message: String?
    let updating: Bool
}

 struct ErrorMetadata: Decodable {
    let category: String
    let value: Int
}

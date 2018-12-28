//
//  SessionStatus.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/27/18.
//  Copyright © 2018 Rudy Bermudez. All rights reserved.
//

import Foundation

struct SessionStatus: Decodable {
    let total_tracker_download, num_unchoked, unchoke_counter, total_payload_upload: Int
    let upload_rate, payload_upload_rate, num_peers, tracker_download_rate: Int
    let tracker_upload_rate, up_bandwidth_bytes_queue, ip_overhead_upload_rate, dht_download_rate: Int
    let total_ip_overhead_download, total_dht_download, total_ip_overhead_upload, dht_total_allocations: Int
    let dht_node_cache, dht_upload_rate, download_rate, total_tracker_upload: Int
    let down_bandwidth_queue, dht_nodes, dht_torrents, total_redundant_bytes: Int
    let up_bandwidth_queue, allowed_upload_slots, payload_download_rate, total_download: Int
    let down_bandwidth_bytes_queue: Int
    let has_incoming_connections: Bool
    let ip_overhead_download_rate, total_payload_download, total_dht_upload, total_upload: Int
    let total_failed_bytes, optimistic_unchoke_counter: Int
}

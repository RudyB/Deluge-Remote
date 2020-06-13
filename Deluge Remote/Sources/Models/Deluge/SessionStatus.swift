//
//  SessionStatus.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/27/18.
//  Copyright © 2018 Rudy Bermudez. All rights reserved.
//

import Foundation

/// Models session wide-statistics and status data points.
/// - Note: Data Points can be seen at: [Page](http://www.rasterbar.com/products/libtorrent/manual.html#status)
struct SessionStatus: Decodable {

    let total_tracker_download: Int

    /// num_unchoked is the current number of unchoked peers.
    let num_unchoked: Int

    /// unchoke_counter tells the number of seconds until the next optimistic unchoke change
    /// and the start of the next unchoke interval.
    /// These numbers may be reset prematurely if a peer that is unchoked disconnects or becomes notinterested.
    let unchoke_counter: Int?

    /// total_payload_upload is the total transfers of payload only.
    /// The payload does not include the bittorrent protocol overhead,
    /// but only parts of the actual files to be downloaded.
    let total_payload_upload: Int

    let upload_rate: Double

    /// payload_upload_rate is the rate of the payload down- and upload only.
    let payload_upload_rate: Int

    /// num_peers is the total number of peer connections this session has.
    /// This includes incoming connections that still hasn't sent their handshake or
    /// outgoing connections that still hasn't completed the TCP connection.
    let num_peers: Int

    let tracker_download_rate: Double

    let tracker_upload_rate: Double

    /// up_bandwidth_bytes_queue count the number of bytes the connections are waiting for to be able to send.
    let up_bandwidth_bytes_queue: Int

    let ip_overhead_upload_rate: Int

    let dht_download_rate: Double

    let total_ip_overhead_download: Double

    let total_dht_download: Double

    let total_ip_overhead_upload: Int

    /// dht_total_allocations is the number of nodes allocated dynamically for a particular DHT lookup.
    /// This represents roughly the amount of memory used by the DHT.
    let dht_total_allocations: Int?

    /// The dht_node_cache is set to the number of nodes in the node cache.
    /// These nodes are used to replace the regular nodes in the routing table in case any of them becomes unresponsive.
    let dht_node_cache: Int

    let dht_upload_rate: Double

    let download_rate: Double

    let total_tracker_upload: Int

    let down_bandwidth_queue: Int

    /// When the DHT is running, dht_nodes is set to the number of nodes in the routing table.
    /// This number only includes active nodes, not cache nodes.
    let dht_nodes: Int

    /// dht_torrents are the number of torrents tracked by the DHT at the moment.
    let dht_torrents: Int

    /// total_redundant_bytes is the number of bytes that has been received more than once.
    /// This can happen if a request from a peer times out and is requested from a different peer,
    /// and then received again from the first one.
    /// To make this lower, increase the request_timeout and the piece_timeout in the session settings.
    let total_redundant_bytes: Int

    let up_bandwidth_queue: Int

    /// allowed_upload_slots is the current allowed number of unchoked peers.
    let allowed_upload_slots: Int

    /// payload_download_rate is the rate of the payload down- and upload only.
    let payload_download_rate: Int

    let total_download: Int

    /// down_bandwidth_bytes_queue count the number of bytes the connections are waiting for to be able to receive.
    let down_bandwidth_bytes_queue: Int

    let has_incoming_connections: DelugeBool?

    let ip_overhead_download_rate: Int

    /// total_payload_download is the total transfers of payload only.
    /// The payload does not include the bittorrent protocol overhead,
    /// but only parts of the actual files to be downloaded.
    let total_payload_download: Int

    let total_dht_upload: Int

    let total_upload: Int

    /// total_failed_bytes is the number of bytes that was downloaded which later failed the hash-check.
    let total_failed_bytes: Int

    /// optimistic_unchoke_counter tells the number of seconds until the next optimistic unchoke change
    /// and the start of the next unchoke interval.
    /// These numbers may be reset prematurely if a peer that is unchoked disconnects or becomes notinterested.
    let optimistic_unchoke_counter: Int?
}

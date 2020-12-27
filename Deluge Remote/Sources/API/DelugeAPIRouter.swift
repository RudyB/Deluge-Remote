//
//  DelugeAPIRouter.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/25/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import Foundation
import Alamofire

enum DelugeRouter: URLRequestConvertible {
    
    /// Authenticate to the Deluge API
    case login(ClientConfig)
    
    case checkAuth(ClientConfig)
    
    case isConnected(ClientConfig)
    
    /// Get `TorrentMetadata`
    case getMetadata(ClientConfig,hash: String)
    
    /// Get `TorrentFileStructure`
    case getFiles(ClientConfig, hash: String)
    
    /// Get `TorrentOverview`
    case getOverview(ClientConfig)
    
    /// Pause all torrents on the server
    case pauseAllTorrents(ClientConfig)
    
    /// Pause an individual torrent
    case pause(ClientConfig, hash: String)
    
    /// Resume all torrents on the server
    case resumeAllTorrents(ClientConfig)
    
    /// Resume an individual torrent
    case resume(ClientConfig, hash: String)
    
    /// Remove a torrent from the server
    case removeTorrent(ClientConfig, hash: String, withData: Bool)
    
    /// Add a magnet URL to the server
    case addTorrentMagnet(ClientConfig, URL, config: TorrentConfig)
    
    /// Get metadata about a magnet link
    case getMagnetInfo(ClientConfig, URL)
    
    /// Add a torrent file to the server
    case addTorrentFile(ClientConfig, filename: String, data: Data, config: TorrentConfig)
    
    /// Upload a torrent to the server
    ///
    /// **Note**: This does not add the torrent to the client
    case uploadTorrentFile(ClientConfig, Data)
    
    /// Get metadata about a torrent that was uploaded to the server
    case getUploadedTorrentInfo(ClientConfig, filename: String)
    
    /// Get the default torrent configuration
    case getDefaultTorrentConfig(ClientConfig)
    
    /// Set the  options for a torrent
    case setTorrentOptions(ClientConfig, hash: String, JSON)
    
    /// Move a torrents filepath
    case moveTorrent(ClientConfig, hash: String, filePath: String)
    
    /// Get all the hosts on the server
    case getHosts(ClientConfig)
    
    /// Get the status of a host
    case getHostStatus(ClientConfig,Host)
    
    /// Connect to a server
    case connect(ClientConfig,Host)
    
    /// Get sessus status
    case getSessionStatus(ClientConfig)
    
    
    // MARK: - HTTPMethod
    private var method: HTTPMethod {
        /// Every method is a post method
        return .post
    }
    
    private func paramsFor(method: String, with params: Any) -> Parameters {
        return [
            "id": id,
            "method": method,
            "params": params
        ]
    }
    
    private var baseURL: URL {
        switch self {
            case .login(let config):
                return config.url
            case .checkAuth(let config):
                return config.url
            case .isConnected(let config):
                return config.url
            case .getMetadata(let config, hash: _):
                return config.url
            case .getFiles(let config, hash: _):
                return config.url
            case .getOverview(let config):
                return config.url
            case .pauseAllTorrents(let config):
                return config.url
            case .pause(let config, hash: _):
                return config.url
            case .resumeAllTorrents(let config):
                return config.url
            case .resume(let config, hash: _):
                return config.url
            case .removeTorrent(let config, hash: _, withData: _):
                return config.url
            case .addTorrentMagnet(let config, _, config: _):
                return config.url
            case .getMagnetInfo(let config, _):
                return config.url
            case .addTorrentFile(let config, filename: _, data: _, config: _):
                return config.url
            case .uploadTorrentFile(let config, _):
                return config.url
            case .getUploadedTorrentInfo(let config, filename: _):
                return config.url
            case .getDefaultTorrentConfig(let config):
                return config.url
            case .setTorrentOptions(let config, hash: _, _):
                return config.url
            case .moveTorrent(let config, hash: _, filePath: _):
                return config.url
            case .getHosts(let config):
                return config.url
            case .getHostStatus(let config, _):
                return config.url
            case .connect(let config, _):
                return config.url
            case .getSessionStatus(let config):
                return config.url
        }
    }
    
    // MARK: - Parameters
    private var parameters: Parameters? {
        
        switch self {
            case .login(let config):
                return paramsFor( method: "auth.login", with: [config.password])
            case .checkAuth(_):
                return paramsFor(method: "auth.check_session", with: [])
            case .isConnected(_):
                return paramsFor(method: "web.connected", with: [])
            case .getMetadata(_, hash: let hash):
                return paramsFor(method: "core.get_torrent_status", with: [hash, []])
            case .getFiles(_, hash: let hash):
                return paramsFor(method: "web.get_torrent_files", with: [hash])
            case .getOverview(_):
                return paramsFor(method: "core.get_torrents_status",
                                 with: [[], ["name", "hash", "upload_payload_rate",
                                             "download_payload_rate", "ratio",
                                             "progress", "total_wanted", "state",
                                             "tracker_host", "label", "eta",
                                             "total_size", "all_time_download",
                                             "total_uploaded", "time_added", "paused"]])
            case .pause(_, hash: let hash):
                return paramsFor(method: "core.pause_torrent", with: [[hash]])
            case .pauseAllTorrents(_):
                return paramsFor(method: "core.pause_all_torrents", with: [])
            case .resumeAllTorrents(_):
                return paramsFor(method: "core.resume_all_torrents", with: [])
            case .resume(_, hash: let hash):
                return paramsFor(method: "core.resume_torrent", with: [[hash]])
            case .removeTorrent(_, hash: let hash, withData: let withData):
                return paramsFor(method: "core.remove_torrent", with: [hash, withData])
            case .addTorrentMagnet(_, let url, config: let config):
                return paramsFor(method: "core.add_torrent_magnet", with: [url.absoluteString, config.toParams()])
            case .getMagnetInfo(_, let url):
                return paramsFor(method: "web.get_magnet_info", with: [url.absoluteString])
            case .addTorrentFile(_, filename: let filename, data: let data, config: let config):
                return paramsFor(method: "core.add_torrent_file", with: [filename, data.base64EncodedString(), config.toParams()])
            case .uploadTorrentFile(_,_):
                return nil
            case .getUploadedTorrentInfo(_, let filename):
                return paramsFor(method: "web.get_torrent_info", with: [filename])
            case .getDefaultTorrentConfig(_):
                return paramsFor(method: "core.get_config_values", with: [[
                    "add_paused",
                    "compact_allocation",
                    "download_location",
                    "max_connections_per_torrent",
                    "max_download_speed_per_torrent",
                    "move_completed",
                    "move_completed_path",
                    "max_upload_slots_per_torrent",
                    "max_upload_speed_per_torrent",
                    "prioritize_first_last_pieces"
                    ]])
            case .setTorrentOptions(_,hash: let hash, let options):
                return paramsFor(method: "core.set_torrent_options", with: [[hash], options])
            case .moveTorrent(_,hash: let hash, filePath: let filePath):
                return paramsFor(method: "core.move_storage", with: [[hash], filePath])
            case .getHosts(_):
                return paramsFor(method: "web.get_hosts", with: [])
            case .getHostStatus(_, let host):
                return paramsFor(method: "web.get_host_status", with: [host.id])
            case .connect(_, let host):
                return paramsFor(method: "web.connect", with: [host.id])
            case .getSessionStatus(_):
                return paramsFor(method: "core.get_session_status", with: [[
                    "has_incoming_connections",
                    "upload_rate",
                    "download_rate",
                    "total_download",
                    "total_upload",
                    "payload_upload_rate",
                    "payload_download_rate",
                    "total_payload_download",
                    "total_payload_upload",
                    "ip_overhead_upload_rate",
                    "ip_overhead_download_rate",
                    "total_ip_overhead_download",
                    "total_ip_overhead_upload",
                    "dht_upload_rate",
                    "dht_download_rate",
                    "total_dht_download",
                    "total_dht_upload",
                    "tracker_upload_rate",
                    "tracker_download_rate",
                    "total_tracker_download",
                    "total_tracker_upload",
                    "total_redundant_bytes",
                    "total_failed_bytes",
                    "num_peers",
                    "num_unchoked",
                    "allowed_upload_slots",
                    "up_bandwidth_queue",
                    "down_bandwidth_queue",
                    "up_bandwidth_bytes_queue",
                    "down_bandwidth_bytes_queue",
                    "optimistic_unchoke_counter",
                    "unchoke_counter",
                    "dht_nodes",
                    "dht_node_cache",
                    "dht_torrents",
                    "dht_total_allocations"
                ]])
        }
    }
    
    private var id: UInt32 {
        return arc4random()
    }
    
    func asURLRequest() throws -> URLRequest {
        let request = try URLRequest(url: baseURL, method: method)
        let encoding = Alamofire.JSONEncoding.default
        return try encoding.encode(request, with: parameters)
    }
}

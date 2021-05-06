//
//  DelugeAPIRouter.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/25/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import Foundation
import Alamofire


struct DelugeRouter: URLRequestConvertible {
    
    private var route: DelugeRoute
    private var config: ClientConfig
    
    init(_ route: DelugeRoute, _ config: ClientConfig) {
        self.route = route
        self.config =  config
    }
    
    func asURLRequest() throws -> URLRequest {
        let request = try URLRequest(url: config.url, method: route.method)
        let encoding = Alamofire.JSONEncoding.default
        return try encoding.encode(request, with: route.parameters)
    }
}

enum DelugeRoute {
    
    /// Authenticate to the Deluge API
    case login(_ password: String)
    
    case checkAuth
    
    case isConnected
    
    /// Get `TorrentMetadata`
    case getMetadata(_ hash: String)
    
    /// Get `TorrentFileStructure`
    case getFiles(_ hash: String)
    
    /// Get `TorrentOverview`
    case getOverview
    
    /// Pause all torrents on the server
    case pauseAllTorrents
    
    /// Pause an individual torrent
    case pause(_ hash: String)
    
    /// Resume all torrents on the server
    case resumeAllTorrents
    
    /// Resume an individual torrent
    case resume(_ hash: String)
    
    /// Remove a torrent from the server
    case removeTorrent(_ hash: String, _ withData: Bool)
    
    /// Add a magnet URL to the server
    case addTorrentMagnet(URL, TorrentConfig)
    
    /// Get metadata about a magnet link
    case getMagnetInfo(URL)
    
    /// Add a torrent file to the server
    case addTorrentFile(_ filename: String, Data, TorrentConfig)
    
    /// Adds a torrent to the server from a URL
    case addTorrentURL(URL, TorrentConfig)
    
    case downloadTorrent(URL)
    
    /// Upload a torrent to the server
    ///
    /// **Note**: This does not add the torrent to the client
    case uploadTorrentFile(Data)
    
    /// Get metadata about a torrent that was uploaded to the server
    case getUploadedTorrentInfo(_ filename: String)
    
    /// Get the default torrent configuration
    case getDefaultTorrentConfig
    
    /// Set the  options for a torrent
    case setTorrentOptions(_ hash: String, _ params: JSON)
    
    /// Move a torrents filepath
    case moveTorrent(_ hash: String, _ filePath: String)
    
    case forceRecheck(_ hash: String)
    
    /// Get all the hosts on the server
    case getHosts
    
    /// Get the status of a host
    case getHostStatus(Host)
    
    /// Connect to a server
    case connect(Host)
    
    /// Get sessus status
    case getSessionStatus
    
    
    // MARK:- Helpers
    fileprivate var method: HTTPMethod {
        // Every method is a post method
        switch self { default: return .post }
    }
    
    // MARK: - Parameters
    fileprivate var parameters: Parameters? {
        
        switch self {
            case .login(let password):      return params(for: "auth.login", with: [password])
            case .checkAuth:                return params(for: "auth.check_session", with: [])
            case .isConnected:              return params(for: "web.connected", with: [])
            case .getMetadata(let hash):    return params(for: "core.get_torrent_status", with: [hash, []])
            case .getFiles(let hash):       return params(for: "web.get_torrent_files", with: [hash])
            case .pause(let hash):          return params(for: "core.pause_torrent", with: [[hash]])
            case .pauseAllTorrents:         return params(for: "core.pause_all_torrents", with: [])
            case .resumeAllTorrents:        return params(for: "core.resume_all_torrents", with: [])
            case .resume(let hash):         return params(for: "core.resume_torrent", with: [[hash]])
            case .downloadTorrent(let url): return params(for: "web.download_torrent_from_url", with: [url.absoluteString, []])
            case .getMagnetInfo(let url):   return params(for: "web.get_magnet_info", with: [url.absoluteString])
            case .forceRecheck(let hash):   return params(for: "core.force_recheck", with: [[hash]]);
            case .getHosts:                 return params(for: "web.get_hosts", with: [])
            case .getHostStatus(let host):  return params(for:"web.get_host_status", with: [host.id])
            case .connect( let host):       return params(for: "web.connect", with: [host.id])
            case .uploadTorrentFile(_):     return nil
            case .setTorrentOptions(let hash, let options):
                return params(for: "core.set_torrent_options", with: [[hash], options])
            case .moveTorrent( let hash, let filePath):
                return params(for:"core.move_storage", with: [[hash], filePath])
            case .removeTorrent( let hash, let withData):
                return params(for: "core.remove_torrent", with: [hash, withData])
            case .addTorrentMagnet(let url, let config):
                return params(for: "core.add_torrent_magnet", with: [url.absoluteString, config.toParams()])
            case .addTorrentURL(let url, let config):
                return params(for: "core.add_torrent_url", with: [url.absoluteString, config.toParams()])
            case .addTorrentFile( let filename, let data, let config):
                return params(for: "core.add_torrent_file", with: [filename, data.base64EncodedString(), config.toParams()])
            case .getUploadedTorrentInfo(let filename):
                return params(for: "web.get_torrent_info", with: [filename])
            case .getDefaultTorrentConfig:
                return params(for: "core.get_config_values", with: [[
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
            case .getOverview:
                return params(for: "core.get_torrents_status",
                                 with: [[], ["name", "hash", "upload_payload_rate",
                                             "download_payload_rate", "ratio",
                                             "progress", "total_wanted", "state",
                                             "tracker_host", "label", "eta",
                                             "total_size", "all_time_download",
                                             "total_uploaded", "time_added", "paused"]])
            case .getSessionStatus:
                return params(for: "core.get_session_status", with: [[
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
    private func params(for method: String, with options: Any) -> Parameters {
        return [
            "id": id,
            "method": method,
            "params": options
        ]
    }
}

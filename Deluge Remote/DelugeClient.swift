//
//  Deluge Client.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 7/16/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

enum ClientError: Error {
    case incorrectPassword
    case unexpectedResponse
    case torrentCouldNotBeParsed
    case unexpectedError(String)
    case unableToPauseTorrent(Error)
    case unableToResumeTorrent(Error)
    case unableToParseTableViewTorrent
    case unableToDeleteTorrent
    case unableToAddTorrent

    func domain() -> String {
        switch self {
        case .incorrectPassword:
            return "Incorrect Password, Unable to Authenticate"
        case .torrentCouldNotBeParsed:
            return "Error Parsing Torrent Data Points"
        case .unexpectedResponse:
            return "Unexpected Response from Server"
        case .unexpectedError(let errorMessage):
            return errorMessage
        case .unableToPauseTorrent(let errorMessage):
            return "Unable to Pause Torrent. \(errorMessage.localizedDescription)"
        case .unableToResumeTorrent(let errorMessage):
            return "Unable to Resume Torrent. \(errorMessage.localizedDescription)"
        case .unableToParseTableViewTorrent:
            return "The Data for Table View Torrent was unable to be parsed"
        case .unableToDeleteTorrent:
            return "The Torrent could not be deleted"
        case .unableToAddTorrent:
            return "The Torrent could not be added"
        }
    }
}

enum NetworkSecurity {
    case https
    case http(port: String)

    func port() -> String {
        switch self {
        case .https:
            return "443"
        case .http(let port):
            return port
        }
    }

    func name() -> String {
        switch self {
        case .https:
            return "https://"
        default:
            return "http://"
        }
    }
}

enum APIResult <T> {
    case success(T)
    case failure(Error)
}

/**
 
 
 payload_download_rate and payload_upload_rate is the rate of the payload down- and upload only.
 
 total_payload_download and total_payload_upload is the total transfers of payload only. The payload does not include the bittorrent protocol overhead, but only parts of the actual files to be downloaded.
 
 ip_overhead_upload_rate, ip_overhead_download_rate, total_ip_overhead_download and total_ip_overhead_upload is the estimated TCP/IP overhead in each direction.
 
 dht_upload_rate, dht_download_rate, total_dht_download and total_dht_upload is the DHT bandwidth usage.
 
 total_redundant_bytes is the number of bytes that has been received more than once. This can happen if a request from a peer times out and is requested from a different peer, and then received again from the first one. To make this lower, increase the request_timeout and the piece_timeout in the session settings.
 
 total_failed_bytes is the number of bytes that was downloaded which later failed the hash-check.
 
 num_peers is the total number of peer connections this session has. This includes incoming connections that still hasn't sent their handshake or outgoing connections that still hasn't completed the TCP connection. This number may be slightly higher than the sum of all peers of all torrents because the incoming connections may not be assigned a torrent yet.
 
 num_unchoked is the current number of unchoked peers. allowed_upload_slots is the current allowed number of unchoked peers.
 
 up_bandwidth_queue and down_bandwidth_queue are the number of peers that are waiting for more bandwidth quota from the torrent rate limiter. up_bandwidth_bytes_queue and down_bandwidth_bytes_queue count the number of bytes the connections are waiting for to be able to send and receive.
 
 optimistic_unchoke_counter and unchoke_counter tells the number of seconds until the next optimistic unchoke change and the start of the next unchoke interval. These numbers may be reset prematurely if a peer that is unchoked disconnects or becomes notinterested.
 
 disk_write_queue and disk_read_queue are the number of peers currently waiting on a disk write or disk read to complete before it receives or sends any more data on the socket. It'a a metric of how disk bound you are.
 
 dht_nodes, dht_node_cache and dht_torrents are only available when built with DHT support. They are all set to 0 if the DHT isn't running. When the DHT is running, dht_nodes is set to the number of nodes in the routing table. This number only includes active nodes, not cache nodes. The dht_node_cache is set to the number of nodes in the node cache. These nodes are used to replace the regular nodes in the routing table in case any of them becomes unresponsive.
 
 dht_torrents are the number of torrents tracked by the DHT at the moment.
 
 dht_global_nodes is an estimation of the total number of nodes in the DHT network.
 
 active_requests is a vector of the currently running DHT lookups.
 
 dht_routing_table contains information about every bucket in the DHT routing table.
 
 dht_total_allocations is the number of nodes allocated dynamically for a particular DHT lookup. This represents roughly the amount of memory used by the DHT.
 
 utp_stats contains statistics on the uTP sockets.
 */

/// Models session wide-statistics and status data points.
/// - Note: Data Points can be seen at: [Page](http://www.rasterbar.com/products/libtorrent/manual.html#status)
struct sessionStatus {

    /** `has_incoming_connections` is false as long as no incoming connections have been established on the listening socket. Every time you change the listen port, this will be reset to false.
     */
    let has_incoming_connections: Bool

    /// The total upload rates accumulated from all torrents. This includes bittorrent protocol, DHT and an estimated TCP/IP protocol overhead.
    let upload_rate: Int

    /// The total download rates accumulated from all torrents. This includes bittorrent protocol, DHT and an estimated TCP/IP protocol overhead.
    let download_rate: Int

    /// The total number of bytes downloaded to and from all torrents. This also includes all the protocol overhead.
    let total_download: Int

    /// The total number of bytes uploaded to and from all torrents. This also includes all the protocol overhead.
    let total_upload: Int

    /// The rate of the payload upload only.
    let payload_upload_rate: Int

    ///The rate of the payload download only.
    let payload_download_rate: Int

    let total_payload_download: Int
    let total_payload_upload: Int

    let ip_overhead_upload_rate: Int
    let ip_overhead_download_rate: Int
    let total_ip_overhead_download: Int
    let total_ip_overhead_upload: Int

    let dht_upload_rate: Int
    let dht_download_rate: Int
    let total_dht_download: Int
    let total_dht_upload: Int

    let tracker_upload_rate: Int
    let tracker_download_rate: Int
    let total_tracker_download: Int
    let total_tracker_upload: Int

    let total_redundant_bytes: Int
    let total_failed_bytes: Int

    let num_peers: Int
    let num_unchoked: Int
    let allowed_upload_slots: Int

    let up_bandwidth_queue: Int
    let down_bandwidth_queue: Int

    let up_bandwidth_bytes_queue: Int
    let down_bandwidth_bytes_queue: Int

    let optimistic_unchoke_counter: Int
    let unchoke_counter: Int

    let dht_nodes: Int
    let dht_node_cache: Int
    let dht_torrents: Int
    let dht_global_nodes: Int
    let dht_total_allocations: Int

}

/**
 API to manage remote Deluge server. Allows user to view, add, pause, resume, and remove torrents
 
 - Important: Must Call `DelugeClient.authenticate()` before any other method or else methods will propagate errors and Promises will be rejected
 */
class DelugeClient {

    let config: ClientConfig

    /// Dispatch Queue used for JSON Serialization
    let utilityQueue: DispatchQueue

    init(config: ClientConfig) {
        self.config = config
        self.utilityQueue = DispatchQueue.global(qos: .utility)
    }

    /**
     Static Function to determine if credentials are valid for a given server
     
     - Returns: `Promise<Bool>`. returns `true` if connection was successful
     
     - A rejected Promise if the authenication fails
     - Possible Errors Propagated to Promise:
     - ClientError.unexpectedResponse if the json cannot be parsed
     - ClientError.incorrectPassword if the server responds the responce was false
     */
    static func validateCredentials(url: String, password: String) -> Promise<Bool> {
        return Promise { fulfill, reject in
            let parameters: Parameters = [
                "id": arc4random(),
                "method": "auth.login",
                "params": [password]
            ]
            let utilityQueue = DispatchQueue.global(qos: .utility)
            Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON(queue: utilityQueue) { (response) in
                switch response.result {
                case .success(let data):
                    let json = data as? JSON
                    guard let result = json?["result"] as? Bool else {
                        reject(ClientError.unexpectedResponse)
                        break
                    }
                    fulfill(result)

                case .failure(let error): reject(ClientError.unexpectedError(error.localizedDescription))
                }
            }
        }
    }

    /**
     Authenticates the user to Deluge Server.
     
     - Important: This function must be called before any other function.
     
     - Note: Uses `DelugeClient.validateCredentials`
     
     - Returns: `Promise<Bool>`. returns `true` if connection was successful
     
     - A rejected Promise if the authenication fails
     - Possible Errors Propagated to Promise:
     - ClientError.unexpectedResponse if the json cannot be parsed
     - ClientError.incorrectPassword if the server responds the responce was false
     
     */
    func authenticate() -> Promise<Bool> {
        return DelugeClient.validateCredentials(url: config.url, password: config.password)
    }

    /**
     Retrieves all data points for a torrent
     
     - precondition: `DelugeClient.authenticate()` must have been called or else `Promise` will be rejected with an error
     
     - Parameter hash: A `String` representation of a hash for a specific torrent the user would like query
     
     - Returns: A `Promise` embedded with an instance of `Torrent`
     */
    func getTorrentDetails(withHash hash: String) -> Promise<TorrentMetadata> {
        return Promise { fulfill, reject in
            let parameters: Parameters = [
                "id": arc4random(),
                "method": "core.get_torrent_status",
                "params": [hash, []]
            ]

            Alamofire.request(config.url, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseData(queue: utilityQueue) { (response) in

                switch response.result {
                case .success(let data):

                    do {
                        let torrent = try
                            JSONDecoder().decode(DelugeResponse<TorrentMetadata>.self, from: data )
                        fulfill(torrent.result)
                    } catch(let error) {
                        print(error)
                        reject(ClientError.torrentCouldNotBeParsed)
                    }

                case .failure(let error): reject(error)
                }
            }
        }
    }
    /**
     Retreives data for all torrents and creates an array of `TableViewTorrent`
     
     - precondition: `DelugeClient.authenticate()` must have been called or else `Promise` will be rejected with an error
     
     - Returns: A `Promise` embedded with a TableViewTorrent
     */
    func getAllTorrents() -> Promise<[TableViewTorrent]> {
        return Promise { fulfill, reject in

            let parameters: Parameters = [
                "id": arc4random(),
                "method": "core.get_torrents_status",
                "params": [[], ["name", "hash", "upload_payload_rate", "download_payload_rate", "ratio", "progress", "total_wanted", "state", "tracker_host", "label", "eta"]]
            ]
            Alamofire.request(config.url, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseData(queue: utilityQueue) { (response) in
                switch response.result {
                case .success(let data):

                    guard let response = try?
                        JSONDecoder().decode(DelugeResponse<[String:TableViewTorrent]>.self, from: data ) else {
                            reject(ClientError.unableToParseTableViewTorrent)
                            break
                    }

                    DispatchQueue.main.async {
                        fulfill(Array(response.result.values))
                    }

                case .failure(let error): reject(ClientError.unexpectedError(error.localizedDescription))
                }
            }
        }
    }
    /**
     Pause an individual torrent
     
     - precondition: `DelugeClient.authenticate()` must have been called or else `APIResult` will fail with an error
     
     - Parameter hash: the hash as a `String` of the torrent the user would like to pause
     - Parameter onCompletion: An escaping block that returns a `APIResult<T>` when the request is completed.
     This block returns a `APIResult<Bool>`
     */
    func pauseTorrent(withHash hash: String, onCompletion: @escaping (APIResult<Void>) -> Void) {
        let parameters: Parameters =  [
            "id": arc4random(),
            "method": "core.pause_torrent",
            "params": [[hash]]
        ]

        Alamofire.request(config.url, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { (response) in
            switch response.result {
            case .success: onCompletion(APIResult.success(()))
            case .failure(let error): onCompletion(APIResult.failure(ClientError.unableToPauseTorrent(error)))
            }
        }
    }

    /**
     Pause all torrents in deluge client
     
     - precondition: `DelugeClient.authenticate()` must have been called or else `APIResult` will fail with an error
     
     - Parameter onCompletion: An escaping block that returns a `APIResult<T>` when the request is completed. If the request is successful, this block returns a APIResult.success(_) with no data. If it fails, it will return APIResult.error(Error)
     
     
     deluge.pauseAllTorrents { (result) in
     switch result {
     case .success(_): print("All Torrents Paused")
     case .failure(let error): print(error)
     }
     }
     */
    func pauseAllTorrents(onCompletion: @escaping (APIResult<Any>) -> Void) {
        let parameters: Parameters = [
            "id": arc4random(),
            "method": "core.pause_all_torrents",
            "params": []
        ]

        Alamofire.request(config.url, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { (response) in
            switch response.result {
            case .success: onCompletion(.success(Any.self))
            case .failure(let error): onCompletion(.failure(ClientError.unableToPauseTorrent(error)))
            }
        }
    }

    /**
     Resume an individual torrent
     
     - precondition: `DelugeClient.authenticate()` must have been called or else `APIResult` will fail with an error
     
     - Parameters:
     - hash: the hash as a `String` of the torrent the user would like to resume
     - onCompletion: An escaping block that returns a `APIResult<T>` when the request is completed. This block returns a `APIResult<Bool>`
     */
    func resumeTorrent(withHash hash: String, onCompletion: @escaping (APIResult<Void>) -> Void) {
        let parameters: Parameters =  [
            "id": arc4random(),
            "method": "core.resume_torrent",
            "params": [[hash]]
        ]

        Alamofire.request(config.url, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { (response) in
            switch response.result {
            case .success: onCompletion(APIResult.success(()))
            case .failure(let error): onCompletion(APIResult.failure(ClientError.unableToResumeTorrent(error)))
            }
        }
    }

    /**
     Resume all torrents in deluge client
     
     - precondition: `DelugeClient.authenticate()` must have been called or else `APIResult` will fail with an error
     
     - Parameter onCompletion: An escaping block that returns a `APIResult<T>` when the request is completed. This block returns a `APIResult<Any>`
     */
    func resumeAllTorrents(onCompletion: @escaping (APIResult<Any>) -> Void) {
        let parameters: Parameters = [
            "id": arc4random(),
            "method": "core.resume_all_torrents",
            "params": []
        ]

        Alamofire.request(config.url, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { (response) in
            switch response.result {
            case .success: onCompletion(.success(Any.self))
            case .failure(let error): onCompletion(.failure(ClientError.unableToResumeTorrent(error)))
            }
        }
    }

    /**
     Removes a Torrent from the client with the option to remove the data
     
     - precondition: `DelugeClient.authenticate()` must have been called or else `Promise` will be rejected with an error
     
     - Parameters:
     - hash: The hash as a String of the torrent the user would like to delete
     - removeData: `true` if the user would like to remove torrent and torrent data. `false` if the user would like to delete the torrent but keep the torrent data
     
     - Returns:  `Promise<Bool>`. If successful, bool will always be true.
     */
    func removeTorrent(withHash hash: String, removeData: Bool) -> Promise <Bool> {
        return Promise { fulfill, reject in
            let parameters: Parameters = [
                "id": arc4random(),
                "method": "core.remove_torrent",
                "params": [hash, removeData]
            ]
            Alamofire.request(config.url, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { (response) in
                switch response.result {
                case .success(let data):
                    guard let json = data as? JSON, let result = json["result"] as? Bool else {
                        reject(ClientError.unexpectedResponse)
                        break
                    }
                    (result == true) ? fulfill(result) : reject(ClientError.unableToDeleteTorrent)
                case .failure(let error):
                    reject(ClientError.unexpectedError(error.localizedDescription))
                }
            }
        }
    }

    func addTorrentMagnet(url: URL) -> Promise<Void> {

        let options: [String: Any] = [
            "file_priorities": [],
            "add_paused": false,
            "compact_allocation": false,
            /*"download_location": "/home/yotam/Downloads",*/
            "move_completed": false,
            /*"move_completed_path": "/home/yotam/Downloads",*/
            "max_connections": -1,
            "max_download_speed": -1,
            "max_upload_slots": -1,
            "max_upload_speed": -1,
            "prioritize_first_last_pieces": false
        ]

        let parameters: Parameters = [
            "id": arc4random(),
            "method": "core.add_torrent_magnet",
            "params": [url.absoluteString, options]
        ]

        return Promise { fulfill, reject in
            Alamofire.request(config.url, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { (response) in
                switch response.result {
                case .success(let json):
                    guard let json = json as? [String: Any], let _ = json["result"] as? String else {
                        reject(ClientError.unableToAddTorrent)
                        return
                    }
                    fulfill(())
                case .failure:
                    reject(ClientError.unableToAddTorrent)
                }
            }
        }
    }

    func addTorrentFile(fileName: String, url: URL) -> Promise<Void> {
        let options: [String: Any] = [
            "file_priorities": [],
            "add_paused": false,
            "compact_allocation": false,
            /*"download_location": "/home/yotam/Downloads",*/
            "move_completed": false,
            /*"move_completed_path": "/home/yotam/Downloads",*/
            "max_connections": -1,
            "max_download_speed": -1,
            "max_upload_slots": -1,
            "max_upload_speed": -1,
            "prioritize_first_last_pieces": false
        ]

        let parameters: Parameters = [
            "id": arc4random(),
            "method": "core.add_torrent_file",
            "params": [fileName, url.absoluteString, options]
        ]

        return Promise { fulfill, reject in
            Alamofire.request(config.url, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseJSON { (response) in
                switch response.result {
                case .success(let json):
                    guard let json = json as? [String: Any], let _ = json["result"] as? String else {
                        reject(ClientError.unableToAddTorrent)
                        return
                    }
                    fulfill(())
                case .failure:
                    reject(ClientError.unableToAddTorrent)
                }
            }
        }
    }
    /**
     Gets the session status values `for keys`, these keys are taken
     from libtorrent's session status.
     
     - Parameter forKeys: List of keys. Keys are taken
     from libtorrent's session status. See: http://www.rasterbar.com/products/libtorrent/manual.html#status
     
     */
    func getSessionStatus() -> Promise<SessionStatus> {
        return Promise { fulfill, reject in
            let parameters: Parameters =
                [
                    "id": arc4random(),
                    "method": "core.get_session_status",
                    "params": [[
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
                        ]]]

            Alamofire.request(config.url, method: .post, parameters: parameters, encoding: JSONEncoding.default).validate().responseData(queue: utilityQueue) { (response) in

                switch response.result {
                case .success(let data):

                    do {
                        let torrent = try
                            JSONDecoder().decode(DelugeResponse<SessionStatus>.self, from: data )
                        fulfill(torrent.result)
                    } catch(let error) {
                        print(error)
                        reject(ClientError.torrentCouldNotBeParsed)
                    }

                case .failure(let error): reject(error)
                }
            }
        }
    }
}

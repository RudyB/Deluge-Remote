//
//  Deluge Client.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 7/16/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import Alamofire
import Foundation
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
 API to manage remote Deluge server. Allows user to view, add, pause, resume, and remove torrents
 
 - Important: Must Call `DelugeClient.authenticate()` before any other method
 or else methods will propagate errors and Promises will be rejected
 */
class DelugeClient {
    //  swiftlint:disable:previous type_body_length
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
            Alamofire.request(url, method: .post, parameters: parameters,
                              encoding: JSONEncoding.default).validate().responseJSON(queue: utilityQueue) { response in
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
     
     - precondition: `DelugeClient.authenticate()` must have been called or
     else `Promise` will be rejected with an error
     
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

            Alamofire.request(config.url, method: .post, parameters: parameters,
                              encoding: JSONEncoding.default)
                .validate().responseData(queue: utilityQueue) { response in

                switch response.result {
                case .success(let data):

                    do {
                        let torrent = try
                            JSONDecoder().decode(DelugeResponse<TorrentMetadata>.self, from: data )
                        fulfill(torrent.result)
                    } catch let error {
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
     
     - precondition: `DelugeClient.authenticate()` must have been called
     or else `Promise` will be rejected with an error
     
     - Returns: A `Promise` embedded with a TableViewTorrent
     */
    func getAllTorrents() -> Promise<[TableViewTorrent]> {
        return Promise { fulfill, reject in

            let parameters: Parameters = [
                "id": arc4random(),
                "method": "core.get_torrents_status",
                "params": [[], ["name", "hash", "upload_payload_rate", "download_payload_rate", "ratio",
                                "progress", "total_wanted", "state", "tracker_host", "label", "eta"]]
            ]
            Alamofire.request(config.url, method: .post, parameters: parameters,
                              encoding: JSONEncoding.default).validate().responseData(queue: utilityQueue) { response in
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

        Alamofire.request(config.url, method: .post, parameters: parameters,
                          encoding: JSONEncoding.default).validate().responseJSON(queue: utilityQueue) { response in
            switch response.result {
            case .success: onCompletion(APIResult.success(()))
            case .failure(let error): onCompletion(APIResult.failure(ClientError.unableToPauseTorrent(error)))
            }
        }
    }

    /**
     Pause all torrents in deluge client
     
     - precondition: `DelugeClient.authenticate()` must have been called or else `APIResult` will fail with an error
     
     - Parameter onCompletion: An escaping block that returns a `APIResult<T>` when the request is completed.
     If the request is successful, this block returns a APIResult.success(_) with no data.
     If it fails, it will return APIResult.error(Error)
     
     
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

        Alamofire.request(config.url, method: .post, parameters: parameters,
                          encoding: JSONEncoding.default).validate().responseJSON(queue: utilityQueue) { response in
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
     - onCompletion: An escaping block that returns a `APIResult<T>` when the request is completed.
     This block returns a `APIResult<Bool>`
     */
    func resumeTorrent(withHash hash: String, onCompletion: @escaping (APIResult<Void>) -> Void) {
        let parameters: Parameters =  [
            "id": arc4random(),
            "method": "core.resume_torrent",
            "params": [[hash]]
        ]

        Alamofire.request(config.url, method: .post, parameters: parameters,
                          encoding: JSONEncoding.default).validate().responseJSON(queue: utilityQueue) { response in
            switch response.result {
            case .success: onCompletion(APIResult.success(()))
            case .failure(let error): onCompletion(APIResult.failure(ClientError.unableToResumeTorrent(error)))
            }
        }
    }

    /**
     Resume all torrents in deluge client
     
     - precondition: `DelugeClient.authenticate()` must have been called or else `APIResult` will fail with an error
     
     - Parameter onCompletion: An escaping block that returns a `APIResult<T>` when the request is completed.
     This block returns a `APIResult<Any>`
     */
    func resumeAllTorrents(onCompletion: @escaping (APIResult<Any>) -> Void) {
        let parameters: Parameters = [
            "id": arc4random(),
            "method": "core.resume_all_torrents",
            "params": []
        ]

        Alamofire.request(config.url, method: .post, parameters: parameters,
                          encoding: JSONEncoding.default).validate().responseJSON(queue: utilityQueue) { response in
            switch response.result {
            case .success: onCompletion(.success(Any.self))
            case .failure(let error): onCompletion(.failure(ClientError.unableToResumeTorrent(error)))
            }
        }
    }

    /**
     Removes a Torrent from the client with the option to remove the data
     
     - precondition: `DelugeClient.authenticate()` must have been called
     or else `Promise` will be rejected with an error
     
     - Parameters:
     - hash: The hash as a String of the torrent the user would like to delete
     - removeData: `true` if the user would like to remove torrent and torrent data.
     `false` if the user would like to delete the torrent but keep the torrent data
     
     - Returns:  `Promise<Bool>`. If successful, bool will always be true.
     */
    func removeTorrent(withHash hash: String, removeData: Bool) -> Promise <Bool> {
        return Promise { fulfill, reject in
            let parameters: Parameters = [
                "id": arc4random(),
                "method": "core.remove_torrent",
                "params": [hash, removeData]
            ]
            Alamofire.request(config.url, method: .post, parameters: parameters,
                              encoding: JSONEncoding.default).validate().responseJSON(queue: utilityQueue) { response in
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
            Alamofire.request(config.url, method: .post, parameters: parameters,
                              encoding: JSONEncoding.default).validate().responseJSON { response in
                switch response.result {
                case .success(let json):
                    // swiftlint:disable:next unused_optional_binding
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
            Alamofire.request(config.url, method: .post, parameters: parameters,
                              encoding: JSONEncoding.default).validate().responseJSON(queue: utilityQueue) { response in
                switch response.result {
                case .success(let json):
                    // swiftlint:disable:next unused_optional_binding
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
    // swiftlint:disable:next function_body_length
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

            Alamofire.request(config.url, method: .post, parameters: parameters,
                              encoding: JSONEncoding.default).validate().responseData(queue: utilityQueue) { response in

                switch response.result {
                case .success(let data):

                    do {
                        let torrent = try
                            JSONDecoder().decode(DelugeResponse<SessionStatus>.self, from: data )
                        fulfill(torrent.result)
                    } catch let error {
                        print(error)
                        reject(ClientError.torrentCouldNotBeParsed)
                    }

                case .failure(let error): reject(error)
                }
            }
        }
    }
} // swiftlint:disable:this file_length

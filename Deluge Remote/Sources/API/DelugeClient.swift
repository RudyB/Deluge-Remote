//
//  Deluge Client.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 7/16/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import Foundation
import Alamofire
import Houston
import PromiseKit

typealias JSON = [String: Any]

enum ClientError: LocalizedError {
    case decoding
    case incorrectPassword
    case uploadFailed
    case hostNotOnline
    case noHostsExist
    case unexpectedResponse
    case unexpectedError
    case other(Error)
    case apiError(DelugeError)
    
    static func map(_ error: Error) -> ClientError {
        return (error as? ClientError) ?? .other(error)
    }

    var errorDescription: String? {
        switch self {
            case .decoding:
                return "Unable to decode data"
            case .incorrectPassword:
                return "Incorrect Password, Unable to Authenticate"
            case .uploadFailed:
                return "Unable to Upload Torrent"
            case .hostNotOnline:
                return "Unable to Connect to Host because Daemon is offline."
            case .noHostsExist:
                return "No Deluge Daemons are configured in the webUI."
            case .unexpectedResponse:
                return "Server returned an invalid response"
            case .other(let error):
                return error.localizedDescription
            case .apiError(let error):
                return "API Error: \(error.message)"
            case .unexpectedError:
                return "Unexpected Error"
        }
    }
}

enum NetworkSecurity: String {
    case https
    case http
}

/**
 API to manage remote Deluge server. Allows user to view, add, pause, resume, and remove torrents
 
 - Important: Must Call `DelugeClient.authenticate()` before any other method
 or else methods will propagate errors and Promises will be rejected
 */
class DelugeClient {
    //  swiftlint:disable:previous type_body_length
    let clientConfig: ClientConfig

    private let Manager: Session
    
    private let retrier: RetryPolicy

    /// Dispatch Queue used for JSON Serialization
    let queue: DispatchQueue

    init(config: ClientConfig) {
        self.clientConfig = config
        self.queue = DispatchQueue.global(qos: .background)
        
        let trustManager = ServerTrustManager(evaluators: [self.clientConfig.hostname: DisabledTrustEvaluator()])
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 35
        configuration.httpAdditionalHeaders = HTTPHeaders.default.dictionary
        
        retrier = RetryPolicy(retryLimit: 3,
                              exponentialBackoffBase: RetryPolicy.defaultExponentialBackoffBase,
                              exponentialBackoffScale: RetryPolicy.defaultExponentialBackoffScale,
                              retryableHTTPMethods: [.post],
                              retryableHTTPStatusCodes: RetryPolicy.defaultRetryableHTTPStatusCodes,
                              retryableURLErrorCodes: RetryPolicy.defaultRetryableURLErrorCodes)
        
        Manager = Session(configuration: configuration, interceptor: retrier, serverTrustManager: trustManager)
    }

    
    public func authenticate() -> Promise<Void> {
        return _authenticate()
            .then { success -> Promise<Bool> in
                if !success { throw ClientError.incorrectPassword }
                return self.isConnected()
            }.done { (connected) in
                if !connected { throw ClientError.hostNotOnline }
            }
    }
    
    func authenticateAndConnect() -> Promise<Void> {
        return _authenticate()
        .then { [weak self] isValid -> Promise<[Host]> in
            guard let self = self, isValid else {
                throw ClientError.incorrectPassword
            }
            return self.getHosts()
        }.then { [weak self] host -> Promise<HostStatus> in
            guard let self = self, let host = host.first else {
                throw ClientError.noHostsExist
            }
            return self.getHostStatus(for: host)
        }.then { [weak self] host -> Promise<Void> in
            guard let self = self else {
                throw ClientError.unexpectedError
            }
            if host.status == "Online" {
                return self.connect(to: host)
            } else if host.status == "Connected" {
                return Promise<Void>()
            } else {
                throw ClientError.hostNotOnline
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
    private func _authenticate() -> Promise<Bool> { return Promise { seal in
        Manager.request(DelugeRouter.login(clientConfig))
            .validate().responseDecodable(of: DelugeResponse<Bool?>.self, queue: self.queue) { response in
            switch response.result {
                case .success(let data):
                    if let result = data.result {
                        seal.fulfill(result)
                    } else {
                        if let error = data.error {
                            seal.reject(ClientError.apiError(error))
                        } else {
                            seal.reject(ClientError.unexpectedResponse)
                        }
                    }
                case .failure(let error):
                    seal.reject(ClientError.other(error))
            }
        }
    }
    }
    
    func isConnected() -> Promise<Bool> { return Promise { seal in
        Manager.request(DelugeRouter.isConnected(self.clientConfig))
            .validate().responseDecodable(of: DelugeResponse<Bool?>.self, queue: self.queue) { response in
                switch response.result {
                    case .success(let data):
                        if let result = data.result {
                            seal.fulfill(result)
                        } else {
                            if let error = data.error {
                                seal.reject(ClientError.apiError(error))
                            } else {
                                seal.reject(ClientError.unexpectedResponse)
                            }
                        }
                    case .failure(let error):
                        seal.reject(ClientError.other(error))
                }
            }
        }
    }
    
    func checkAuth() -> Promise <Bool> { return Promise { seal in
        Manager.request(DelugeRouter.checkAuth(self.clientConfig))
            .validate().responseDecodable(of: DelugeResponse<Bool?>.self, queue: self.queue) { response in
                switch response.result {
                    case .success(let data):
                        if let result = data.result {
                            seal.fulfill(result)
                        } else {
                            if let error = data.error {
                                seal.reject(ClientError.apiError(error))
                            } else {
                                seal.reject(ClientError.unexpectedResponse)
                            }
                        }
                    case .failure(let error):
                        seal.reject(ClientError.other(error))
                }
            }
    }
    }

    /**
     Retrieves all data points for a torrent
     
     - precondition: `DelugeClient.authenticate()` must have been called or
     else `Promise` will be rejected with an error
     
     - Parameter hash: A `String` representation of a hash for a specific torrent the user would like query
     
     - Returns: A `Promise` embedded with an instance of `Torrent`
     */
    func getTorrentDetails(withHash hash: String) -> Promise<TorrentMetadata> { return Promise { seal in
        Manager.request(DelugeRouter.getMetadata(clientConfig, hash: hash))
            .validate().responseDecodable(of: DelugeResponse<TorrentMetadata?>.self, queue: queue) { response in
                switch response.result {
                    case .success(let data):
                        if let result = data.result {
                            seal.fulfill(result)
                        } else {
                            if let error = data.error {
                                seal.reject(ClientError.apiError(error))
                            } else {
                                seal.reject(ClientError.unexpectedResponse)
                            }
                        }
                    case .failure(let error):
                        if error.isRequestRetryError {
                            Logger.error(ClientError.other(error))
                            seal.reject(ClientError.other(error))
                        } else if error.isResponseSerializationError {
                            Logger.error(error)
                            seal.reject(ClientError.decoding)
                        } else {
                            Logger.error(error)
                        }
                }
            }
    }
    }
    
    /**
     Retrieves the torrent file structure for a given torrent
     
     - precondition: `DelugeClient.authenticate()` must have been called or
     else `Promise` will be rejected with an error
     
     - Parameter hash: A `String` representation of a hash for a specific torrent the user would like query
     
     - Returns: A `Promise` embedded with an instance of `TorrentFileStructure`
     */
    func getTorrentFiles(withHash hash: String) -> Promise<TorrentFileStructure?> { return Promise { seal in
        self.Manager.request(DelugeRouter.getFiles(clientConfig, hash: hash))
            .validate().responseJSON(queue: self.queue) { response in
                switch response.result {
                    case .success(let data):
                        guard let json = data as? JSON else { return seal.reject(ClientError.unexpectedResponse) }
                        
                        if let result = json["result"] as? JSON {
                            seal.fulfill(TorrentFileStructure(json: result))
                        } else {
                            if let error = DelugeError(json: json) {
                                seal.reject(ClientError.apiError(error))
                            } else {
                                seal.reject(ClientError.unexpectedResponse)
                            }
                        }
                    case .failure(let error):
                        seal.reject(ClientError.other(error))
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
    func getAllTorrents() -> Promise<[TorrentOverview]> { return Promise { seal in
        Manager.request(DelugeRouter.getOverview(clientConfig))
            .validate().responseDecodable(of: DelugeResponse<[String: TorrentOverview]?>.self, queue: self.queue){ response in
                switch response.result {
                    case .success(let data):
                        if let result = data.result {
                            seal.fulfill(result.map { $0.value })
                        } else {
                            if let error = data.error {
                                Logger.error(ClientError.apiError(error))
                                seal.reject(ClientError.apiError(error))
                            } else {
                                seal.reject(ClientError.unexpectedResponse)
                            }
                        }
                        
                    case .failure(let error):
                        if error.isRequestRetryError {
                            Logger.error(ClientError.other(error))
                            seal.reject(ClientError.other(error))
                        } else if error.isResponseSerializationError {
                            Logger.error(error)
                            seal.reject(ClientError.decoding)
                        } else {
                            Logger.error(error)
                        }
                }
            }
        }
    }
    /**
     Pause an individual torrent
     
     - precondition: `DelugeClient.authenticate()` must have been called or else `APIResult` will fail with an error
     
     - Parameter hash: the hash as a `String` of the torrent the user would like to pause
     This block returns a `Promis<Void>`
     */
    func pauseTorrent(withHash hash: String) -> Promise<Void>{ return Promise { seal in
        Manager.request(DelugeRouter.pause(clientConfig, hash: hash))
            .validate().response(queue: self.queue) { response in
                switch response.result {
                    case .success: seal.fulfill(())
                    case .failure(let error): seal.reject(ClientError.other(error))
                }
            }
        }
    }

    /**
     Pause all torrents in deluge client
     
     - precondition: `DelugeClient.authenticate()` must have been called or else `APIResult` will fail with an error
     */
    func pauseAllTorrents() -> Promise<Void> { return Promise { seal in
        Manager.request(DelugeRouter.pauseAllTorrents(clientConfig))
            .validate().response(queue: self.queue) { response in
                switch response.result {
                    case .success: seal.fulfill(())
                    case .failure(let error): seal.reject(ClientError.other(error))
                }
            }
        }
    }

    /**
     Resume an individual torrent
     
     - precondition: `DelugeClient.authenticate()` must have been called or else `APIResult` will fail with an error
     
     - Parameters:
     - hash: the hash as a `String` of the torrent the user would like to resume
     */
    func resumeTorrent(withHash hash: String) -> Promise<Void> { return Promise { seal in
        Manager.request(DelugeRouter.resume(clientConfig, hash: hash)).validate().response(queue: self.queue) { response in
            switch response.result {
                case .success: seal.fulfill(())
                case .failure(let error): seal.reject(ClientError.other(error))
            }
        }
    }
    }

    /**
     Resume all torrents in deluge client
     
     - precondition: `DelugeClient.authenticate()` must have been called or else `APIResult` will fail with an error
     */
    func resumeAllTorrents() -> Promise<Void> { return Promise { seal in
        Manager.request(DelugeRouter.resumeAllTorrents(clientConfig))
            .validate().responseJSON(queue: queue) { response in
                switch response.result {
                    case .success: seal.fulfill(())
                    case .failure(let error): seal.reject(ClientError.other(error))
                }
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
     
     - Returns:  `Promise<Void>`. If successful, bool will always be true.
     */
    func removeTorrent(withHash hash: String, removeData: Bool) -> Promise<Bool> { return Promise { seal in
        
        Manager.request(DelugeRouter.removeTorrent(clientConfig, hash: hash, withData: removeData))
            .validate().responseJSON(queue: self.queue) { response in
                switch response.result {
                    case .success(let data):
                        guard let json = data as? JSON else { return seal.reject(ClientError.unexpectedResponse) }
                        if let result = json["result"] as? Bool {
                            seal.fulfill(result)
                        } else {
                            if let error = DelugeError(json: json) {
                                seal.reject(ClientError.apiError(error))
                            } else {
                                seal.reject(ClientError.unexpectedResponse)
                            }
                        }
                    case .failure(let error):
                        seal.reject(ClientError.other(error))
                }
            }
    }
    }

    /// Adds a magnet link to the server
    ///
    /// Returns the hash
    func addTorrentMagnet(url: URL, with config: TorrentConfig) -> Promise<String> { return Promise { seal in
        // TODO: Add File Priorities
        Manager.request(DelugeRouter.addTorrentMagnet(clientConfig, url, config: config))
            .validate().responseDecodable(of: DelugeResponse<String>?.self, queue: self.queue) { response in
                switch response.result {
                    case .success(let data):
                        if let result = data?.result {
                            seal.fulfill(result)
                        } else {
                            if let error = data?.error {
                                seal.reject(ClientError.apiError(error))
                            } else {
                                seal.reject(ClientError.unexpectedResponse)
                            }
                        }
                    case .failure(let error): seal.reject(ClientError.other(error))
                }
            }
        }
    }

    func getMagnetInfo(url: URL) -> Promise<MagnetInfo> { return Promise { seal in
            Manager.request(DelugeRouter.getMagnetInfo(clientConfig, url))
                .validate().responseDecodable(of: DelugeResponse<MagnetInfo>?.self, queue: self.queue) { response in
                    switch response.result {
                    case .success(let data):
                        if let result = data?.result {
                            seal.fulfill(result)
                        } else {
                            if let error = data?.error {
                                seal.reject(ClientError.apiError(error))
                            } else {
                                seal.reject(ClientError.unexpectedResponse)
                            }
                        }
                    case .failure(let error):
                        seal.reject(ClientError.other(error))
                    }
            }
        }
    }

    func addTorrentFile(fileName: String, torrent: Data, with config: TorrentConfig) -> Promise<String> { return Promise { seal in
        Manager.request(DelugeRouter.addTorrentFile(self.clientConfig, filename: fileName, data: torrent, config: config))
            .validate().responseDecodable(of: DelugeResponse<String>?.self, queue: self.queue) { response in
                switch response.result {
                    case .success(let data):
                        if let result = data?.result {
                            seal.fulfill(result)
                        } else {
                            if let error = data?.error {
                                seal.reject(ClientError.apiError(error))
                            } else {
                                seal.reject(ClientError.unexpectedResponse)
                            }
                        }
                    case .failure(let error): seal.reject(ClientError.other(error))
                }
            }
        }
    }

    private func upload(torrentData: Data) -> Promise<String> { return Promise { seal in
        let headers: HTTPHeaders = [
            "Content-Type": "multipart/form-data; charset=utf-8;"
        ]
        
        // swiftlint:disable:next trailing_closure
        Manager.upload(multipartFormData: { $0.append(torrentData, withName: "file") },
                       to: clientConfig.uploadURL, method: .post, headers: headers)
            .responseJSON{ (response) in
                switch response.result {
                    case .success(let data):
                        guard let json = data as? JSON else { return seal.reject(ClientError.unexpectedResponse) }
                        if let files = json["files"] as? [String],
                           let file = files.first {
                            seal.fulfill(file)
                        } else {
                            if let error = DelugeError(json: json) {
                                seal.reject(ClientError.apiError(error))
                            } else {
                                seal.reject(ClientError.uploadFailed)
                            }
                        }
                    case .failure(let error):
                        seal.reject(ClientError.other(error))
                }
            }
        }
    }

    func getTorrentInfo(torrent: Data) -> Promise<UploadedTorrentInfo> { return Promise { seal in
            firstly { upload(torrentData: torrent) }
                .done { fileName in
                    self.Manager.request(DelugeRouter.getUploadedTorrentInfo(self.clientConfig, filename: fileName))
                        .validate().responseJSON(queue: self.queue) { response in
                            switch response.result {
                            case .success(let json):
                                guard
                                    let dict = json as? JSON,
                                    let result = dict["result"] as? JSON,
                                    let info = UploadedTorrentInfo(json: result)
                                else {
                                    seal.reject(ClientError.unexpectedResponse)
                                    return
                                }
                                seal.fulfill(info)
                            case .failure(let error):
                                seal.reject(ClientError.other(error))
                            }
                    }

                }.catch { error in
                    seal.reject(error)
            }
        }
    }

    func getAddTorrentConfig() -> Promise<TorrentConfig> { return Promise { seal in
        Manager.request(DelugeRouter.getDefaultTorrentConfig(self.clientConfig))
                .validate().responseDecodable(of: DelugeResponse<TorrentConfig?>.self, queue: queue) { response in
                    switch response.result {
                    case .success(let data):
                        if let result = data.result {
                            seal.fulfill(result)
                        } else {
                            if let error = data.error {
                                seal.reject(ClientError.apiError(error))
                            } else {
                                seal.reject(ClientError.unexpectedResponse)
                            }
                        }
                    case .failure(let error):
                        seal.reject(ClientError.other(error))
                    }
            }
        }
    }

    func setTorrentOptions(hash: String, options: JSON) -> Promise<Void> {
        return Promise { seal in
            Manager.request(DelugeRouter.setTorrentOptions(self.clientConfig, hash: hash, options))
                .validate().response { response in
                    if let error = response.error {
                        seal.reject(error)
                    } else {
                        seal.fulfill(())
                    }
                }
        }
    }

    func moveTorrent(hash: String, filepath: String) -> Promise<Void> { return Promise { seal in
        Manager.request(DelugeRouter.moveTorrent(self.clientConfig, hash: hash, filePath: filepath))
            .validate().response { response in
                if let error = response.error {
                    seal.reject(error)
                } else {
                    seal.fulfill(())
                }
            }
    }
    }

    func getHosts() -> Promise<[Host]> { return Promise { seal in
        Manager.request(DelugeRouter.getHosts(self.clientConfig))
            .validate().responseJSON(queue: queue) { response in
                switch response.result {
                    case .failure(let error):
                        seal.reject(error)
                    case .success(let json):
                        guard
                            let json = json as? JSON,
                            let result = json["result"] as? [[Any]]
                        else {
                            seal.reject(ClientError.unexpectedResponse)
                            return
                        }
                        let hosts = result.compactMap { Host(jsonArray: $0) }
                        seal.fulfill(hosts)
                }
            }
        
    }
    }

    func getHostStatus(for host: Host) -> Promise<HostStatus> { return Promise { seal in
        Manager.request(DelugeRouter.getHostStatus(clientConfig, host))
                .validate().responseJSON(queue: queue) { response in
                    switch response.result {
                    case .failure(let error):
                        seal.reject(error)
                    case .success(let json):
                        guard
                            let json = json as? JSON,
                            let result = json["result"] as? [Any],
                            let status = HostStatus(jsonArray: result)
                        else {
                            seal.reject(ClientError.unexpectedResponse)
                                return
                        }

                        seal.fulfill(status)
                    }
            }

        }
    }
    
    func connect(to host: Host) -> Promise<Void> { return Promise { seal in
        Manager.request(DelugeRouter.connect(clientConfig, host))
            .validate().responseJSON(queue: queue) { response in
                switch response.result {
                    case .failure(let error):
                        seal.reject(error)
                    case .success:
                        seal.fulfill(())
                }
            }
        }
    }

    /**
     Gets the session status values `for keys`, these keys are taken
     from libtorrent's session status.
     See: [http://www.rasterbar.com/products/libtorrent/manual.html#status](http://www.rasterbar.com/products/libtorrent/manual.html#status)
     
     */
    @discardableResult
    func getSessionStatus() -> Promise<SessionStatus> { return Promise { seal in

        Manager.request(DelugeRouter.getSessionStatus(self.clientConfig))
                .validate().responseDecodable(of: DelugeResponse<SessionStatus?>.self, queue: queue) { response in
                    switch response.result {
                    case .success(let data):
                        if let result = data.result {
                            seal.fulfill(result)
                        } else {
                            if let error = data.error {
                                seal.reject(ClientError.apiError(error))
                            } else {
                                seal.reject(ClientError.unexpectedResponse)
                            }
                        }
                    case .failure(let error):
                        seal.reject(ClientError.other(error))
                    }
            }
        }
    }
} // swiftlint:disable:this file_length

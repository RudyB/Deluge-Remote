//
//  ClientConfig.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/25/18.
//  Copyright © 2018 Rudy Bermudez. All rights reserved.
//

import Foundation

struct ClientConfig: Codable, Comparable {
   
    let nickname: String
    let hostname: String
    let relativePath: String
    let port: Int
    let password: String
    let isHTTP: Bool
    let url: URL
    let uploadURL: URL
    
    static func < (lhs: ClientConfig, rhs: ClientConfig) -> Bool {
        return lhs.nickname == rhs.nickname && lhs.hostname == rhs.hostname && lhs.relativePath == rhs.relativePath
        && lhs.port == rhs.port && lhs.password == rhs.password && lhs.isHTTP == rhs.isHTTP
    }
    
    init?(nickname: String, hostname: String, relativePath: String, port: Int, password: String, isHTTP: Bool) {
        
        self.nickname = nickname
        self.hostname = hostname
        self.relativePath = relativePath
        self.port = port
        self.password = password
        self.isHTTP = isHTTP
        
        let sslConfig: NetworkSecurity = isHTTP ? .http : .https
        
        var urlBuilder = URLComponents()
        urlBuilder.scheme = sslConfig.rawValue
        urlBuilder.host = hostname
        urlBuilder.port = port
        
        guard var baseURL = try? urlBuilder.asURL() else { return nil }
        baseURL.appendPathComponent(relativePath)
        
        self.uploadURL = baseURL.appendingPathComponent("upload")
        self.url = baseURL.appendingPathComponent("json")
        
        print(url.absoluteString)
        
        print( "\(sslConfig.rawValue)://\(hostname):\(port)\(relativePath)/json")
    }

}

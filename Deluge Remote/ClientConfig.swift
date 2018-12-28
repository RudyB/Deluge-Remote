//
//  ClientConfig.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/25/18.
//  Copyright © 2018 Rudy Bermudez. All rights reserved.
//

import Foundation

struct ClientConfig: Codable, Comparable {
    static func < (lhs: ClientConfig, rhs: ClientConfig) -> Bool {
        return lhs.nickname == rhs.nickname && lhs.hostname == rhs.hostname && lhs.relativePath == rhs.relativePath
        && lhs.port == rhs.port && lhs.password == rhs.password && lhs.isHTTP == rhs.isHTTP
    }

    let nickname: String
    let hostname: String
    let relativePath: String
    let port: String
    let password: String
    let isHTTP: Bool

    var url: String {
        var sslConfig: NetworkSecurity
        if isHTTP {
            sslConfig = NetworkSecurity.http(port: port)
        } else {
            sslConfig = NetworkSecurity.https
        }
        return "\(sslConfig.name())\(hostname):\(sslConfig.port())\(relativePath)/json"
    }

    init(nickname: String, hostname: String, relativePath: String, port: String, password: String, isHTTP: Bool) {
        self.nickname = nickname
        self.hostname = hostname
        self.relativePath = relativePath
        self.port = port
        self.password = password
        self.isHTTP = isHTTP
    }

}

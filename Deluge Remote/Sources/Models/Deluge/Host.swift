//
//  Host.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 1/10/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import Foundation

class Host {
    let id: String
    let url: URL?
    let port: Int?

    init?(jsonArray: [Any]) {

        // Deluge 1.0 API returns an array of 5
        // Deluge 2.0 API returns an array of 3

        if jsonArray.count == 5 {
             guard
                 let id = jsonArray[0] as? String,
                 let urlString = jsonArray[1] as? String,
                 let url = URL(string: urlString),
                 let port = jsonArray[2] as? Int
             else { return nil }

             self.id = id
             self.url = url
             self.port = port
        } else {
            guard
                let id = jsonArray[0] as? String
            else { return nil }

            self.id = id
            self.url = nil
            self.port = nil
        }

    }

}

class HostStatus: Host {
    let status: String

    override init?(jsonArray: [Any]) {

        // Deluge 1.0 API returns an array of 5
        // Deluge 2.0 API returns an array of 3

        if jsonArray.count == 5 {
            guard let status = jsonArray[3] as? String else { return nil }
            self.status = status
        } else {
            guard let status = jsonArray[1] as? String else { return nil }
            self.status = status
        }

        super.init(jsonArray: jsonArray)
    }
}

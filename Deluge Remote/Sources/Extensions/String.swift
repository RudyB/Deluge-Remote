//
//  String.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 1/7/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import Foundation

extension String {

    func parsedTorrentName() -> String {
        return self.replacingOccurrences(of: "([.|\\-|_])", with: " ", options: .regularExpression).lowercased()
    }
}

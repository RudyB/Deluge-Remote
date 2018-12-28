//
//  Extensions.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/27/18.
//  Copyright © 2018 Rudy Bermudez. All rights reserved.
//

import Foundation

extension Int {
    func transferRateString() -> String {
        return sizeString() + "/s"
    }

    func sizeString() -> String {
        return ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: ByteCountFormatter.CountStyle.memory)
    }
}

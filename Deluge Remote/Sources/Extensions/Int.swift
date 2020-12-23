//
//  Int.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 1/4/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
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

extension Double
{
    func transferRateString() -> String {
        return sizeString() + "/s"
    }

    func sizeString() -> String {
        return ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: ByteCountFormatter.CountStyle.memory)
    }
}

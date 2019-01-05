//
//  DelugeBool.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 1/3/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import Foundation

enum DelugeBool: Decodable {
    case int(Int)
    case bool(Bool)

    var value: Bool {
        switch self {
        case .int(let int):
            return int == 1
        case .bool(let bool):
            return bool
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = try .bool(container.decode(Bool.self))
        } catch DecodingError.typeMismatch {
            do {
                self = try .int(container.decode(Int.self))
            } catch DecodingError.typeMismatch {
                throw DecodingError.typeMismatch(DelugeBool.self, DecodingError
                    .Context(codingPath: decoder.codingPath,
                             debugDescription: "Encoded payload not of an expected type"))
            }
        }
    }
}

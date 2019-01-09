//
//  DelugeFileProgress.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 1/8/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import Foundation

enum DelugeFileProgress: Decodable {
    case double(Double)
    case array([Double])

    var value: [Double] {
        switch self {
        case .double(let double):
            return [double]
        case .array(let array):
            return array
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = try .double(container.decode(Double.self))
        } catch DecodingError.typeMismatch {
            do {
                self = try .array(container.decode([Double].self))
            } catch DecodingError.typeMismatch {
                throw DecodingError.typeMismatch(DelugeFileProgress.self, DecodingError
                    .Context(codingPath: decoder.codingPath,
                             debugDescription: "Encoded payload not of an expected type"))
            }
        }
    }
}

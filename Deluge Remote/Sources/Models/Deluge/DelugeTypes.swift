//
//  DelugeTypes.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/13/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import Foundation

//
//  DelugeTypes.swift
//  DelugeRemote
//
//  Created by Rudy Bermudez on 6/29/20.
//

import Foundation

// MARK: - Deluge Reponse
struct DelugeResponse<T: Decodable>: Decodable {
    let id: Int
    let result: T
    let error: DelugeError?
}

// MARK: - Deluge Error
struct DelugeError: Decodable {
    let message: String
    let code: Int
    
    init?(json: JSON) {
        guard
            let error = json["error"] as? JSON,
            let message = error["message"] as? String,
            let code = error["code"] as? Int
        else { return nil }
        
        self.message = message
        self.code = code
    }
}

// MARK: - Deluge Bool
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


// MARK: - Deluge File Progress
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

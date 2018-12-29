//
//  Bencoder.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/28/18.
//  Copyright © 2018 Rudy Bermudez. All rights reserved.
//

import Foundation

class Bencoder {

    let dict: M13OrderedDictionary

    init?(torrentFileURL: URL) {
        guard
            let data = try? Data(contentsOf: torrentFileURL),
            let bencode = try? NSBencodeSerialization.bencodedObject(with: data),
            let bencodeDict = bencode as? M13OrderedDictionary
        else { return nil }

        self.dict = bencodeDict
    }

    func getTorrentFiles() -> [(String, Int)]? {
        guard
            let infoDict = dict["info"] as? M13OrderedDictionary,
            let files = infoDict["files"] as? NSMutableArray
        else { return nil }

        var output: [(String, Int)] = []

        for file in files {
            if let fileDict = file as? M13OrderedDictionary,
                let filePathArray = fileDict["path"] as? NSMutableArray,
                let fileName = filePathArray.firstObject as? NSString,
                let fileSize = fileDict["length"] as? NSNumber {

                output.append((String(fileName), Int(fileSize)))
            }
        }

        return output.isEmpty ? nil : output
    }

    func getTorrentName() -> String? {
        guard
            let infoDict = dict["info"] as? M13OrderedDictionary,
            let fileName = infoDict["name"] as? NSString
        else { return nil }

        return String(fileName)
    }

    func getTorrentSize() -> Int? {
        guard
            let infoDict = dict["info"] as? M13OrderedDictionary,
            let fileSize = infoDict["length"] as? NSNumber
        else { return nil }

        return Int(fileSize)
    }
}

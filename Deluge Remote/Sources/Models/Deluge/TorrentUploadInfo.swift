//
//  FileTree.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/31/18.
//  Copyright © 2018 Rudy Bermudez. All rights reserved.
//

import Foundation


struct MagnetInfo: Decodable {
    let name: String
    let info_hash: String
}

struct UploadedTorrentInfo {
    let name: String
    let hash: String
    let files: UploadedTorrentFileNode
    
    init?(json: JSON) {
        guard
            let name = json["name"] as? String,
            let info_hash = json["info_hash"] as? String,
            let fileTree = json["files_tree"] as? JSON,
            let fileTreeContents = fileTree["contents"] as? JSON,
            let fileTreeRootKey = fileTreeContents.keys.first,
            let fileTreeRootJSON = fileTreeContents[fileTreeRootKey] as? JSON,
            let files = UploadedTorrentFileNode(fileName: name, json: fileTreeRootJSON)
        else { return nil }
        
        self.name = name
        self.hash = info_hash
        self.files = files
    }
}

struct UploadedTorrentFileNode {
    let download: Bool?
    let fileName: String
    let path: String?
    let length: Int?
    let isDirectory: Bool
    let index: Int?
    var children: [UploadedTorrentFileNode] = []

    init?(fileName: String, json: JSON) {
        self.fileName = fileName
        self.download = json["download"] as? Bool
        self.path = json["path"] as? String
        self.length = json["length"] as? Int
        self.isDirectory = json["type"] as? String == "dir" ? true : false
        self.index = json["index"] as? Int

        if let children  = json["contents"] as? JSON {
            self.children = children.keys.compactMap { (key) -> UploadedTorrentFileNode? in
                guard let innerContent = children[key] as? JSON else { return nil }
                return UploadedTorrentFileNode(fileName: key, json: innerContent)
            }
        }
    }
}

extension UploadedTorrentFileNode {

    func prettyPrint() {
        print(self.fileName)

        for child in self.children where !child.isDirectory {
            print("\t\(child.fileName) - \(child.length?.sizeString() ?? "")")
        }
        for child in self.children where child.isDirectory {
            printChildrenHelper(node: child)
        }
    }

    private func printChildrenHelper(node: UploadedTorrentFileNode) {

        if !node.isDirectory {
            print("\t\t\(node.fileName) - \(node.length?.sizeString() ?? "") ")
        } else {
            print("\t/\(node.fileName)")
            for child in node.children {
                printChildrenHelper(node: child)
            }
        }
    }
}

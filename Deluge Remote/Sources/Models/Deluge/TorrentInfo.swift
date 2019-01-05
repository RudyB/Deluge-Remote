//
//  FileTree.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/31/18.
//  Copyright © 2018 Rudy Bermudez. All rights reserved.
//

import Foundation

struct TorrentInfo {
    let name: String
    let hash: String
    let isDirectory: Bool
    let files: FileNode
}

struct FileNode {
    let download: Bool?
    let fileName: String
    let path: String?
    let length: Int?
    let isDirectory: Bool
    let index: Int?
    var children: [FileNode] = []

    init(fileName: String, json: [String: Any]) {
        self.fileName = fileName
        self.download = json["download"] as? Bool
        self.path = json["path"] as? String
        self.length = json["length"] as? Int
        self.isDirectory = json["type"] as? String == "dir" ? true : false
        self.index = json["index"] as? Int

        if let children  = json["contents"] as? [String: Any] {
            for key in children.keys {
                if let innerContent = children[key] as? [String: Any] {
                    self.children.append(FileNode(fileName: key, json: innerContent))
                }
            }
        }
    }
}

extension FileNode {

    func prettyPrint() {
        print(self.fileName)

        for child in self.children where !child.isDirectory {
            print("\t\(child.fileName) - \(child.length?.sizeString() ?? "")")
        }
        for child in self.children where child.isDirectory {
            printChildrenHelper(node: child)
        }
    }

    private func printChildrenHelper(node: FileNode) {

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

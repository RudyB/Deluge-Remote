//
//  TorrentFileStructure.swift
//  DelugeRemote
//
//  Created by Rudy Bermudez on 6/29/20.
//

import Foundation
import ExpandableCollectionViewKit

typealias DirectoryName = String


struct TorrentFileStructure {
    
    let files: DownloadedTorrentFileNode
    let isDir: Bool
    
    init?(json: JSON) {
        guard
            let type = json["type"] as? String,
            let contents = json["contents"] as? JSON,
            let rootKey = contents.keys.first,
            let rootKeyJSON = contents[rootKey] as? JSON,
            let files = DownloadedTorrentFileNode(fileName: rootKey, json: rootKeyJSON)
        else { return nil }
        
        self.isDir = type == "dir"
        self.files = files
            
    }
}


struct DownloadedTorrentFileNode
{
    let fileName: String
    let priority: Int
    let index: Int? // Only when it is a file
    let offset: Int? // Only when it is a file
    let progress: Double
    let path: String
    let isDir: Bool
    let size: Int
    var children: [DownloadedTorrentFileNode] = []
    let progresses: [Double]? // Only when it is a dir
    
    init?(fileName: String, json: JSON) {
        guard
            let priority = json["priority"] as? Int,
            let progress = json["progress"] as? Double,
            let path = json["path"] as? String,
            let type = json["type"] as? String,
            let size = json["size"] as? Int
        else { return nil }
        
        self.fileName = fileName
        self.priority = priority
        self.progress = progress
        self.path = path
        self.isDir = type == "dir"
        self.size = size
        self.index = json["index"] as? Int
        self.offset = json["offset"] as? Int
        self.progresses = json["progresses"] as? [Double]
        
        if let children = json["contents"] as? JSON {
            self.children = children.keys.compactMap { (key) -> DownloadedTorrentFileNode? in
                guard let innerContent = children[key] as? JSON else { return nil }
                return DownloadedTorrentFileNode(fileName: key, json: innerContent)
            }
        }
    }
}

extension DownloadedTorrentFileNode {

    func prettyPrint() {
        print(self.fileName)

        for child in children where !child.isDir {
            print("\t\(child.fileName) - \(child.size.sizeString())")
        }
        for child in children where child.isDir {
            printChildrenHelper(node: child)
        }
    }

    private func printChildrenHelper(node: DownloadedTorrentFileNode) {

        if !node.isDir {
            print("\t\t\(node.fileName) - \(node.size.sizeString()) ")
        } else {
            print("\t/\(node.fileName)")
            for child in node.children {
                printChildrenHelper(node: child)
            }
        }

    }
    
    func toExpandableItems() -> ExpandableItem {
        if isDir {
            let folder = Folder(title: fileName)
            folder.isExpanded(true)
            folder.isItemsCountVisible(true)
            children.forEach { (file) in
                folder.addItems(file.toExpandableItems())
            }
            return folder
        } else {
            let item = Item(title: fileName)
            item.setImage(systemName: "doc.fill")
            item.setTintColor(.systemGray)
            return item
        }
    }
}

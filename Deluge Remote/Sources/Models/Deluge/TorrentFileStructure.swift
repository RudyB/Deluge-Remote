//
//  TorrentFileStructure.swift
//  DelugeRemote
//
//  Created by Rudy Bermudez on 6/29/20.
//

import Foundation

typealias DirectoryName = String

fileprivate struct TorrentFiles: Decodable {

    let files: [TorrentFile]

    enum CodingKeys: String, CodingKey {
        case files = "contents"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        let data = try values.decode([DirectoryName:RawTorrentFileStructureNode].self)
        files  = data.map { TorrentFile(name: $0, data: $1) }
    }
}

struct TorrentFileStructure: Decodable {
    let type: String
    private let contents: TorrentFiles
    var isDirectory: Bool { return type == "dir" }
    
    var files: [TorrentFile] { return contents.files }
}


fileprivate struct RawTorrentFileStructureNode: Decodable
{
    let priority: Int
    let index: Int? // Only when it is a file
    let offset: Int? // Only when it is a file
    let progress: Double
    let path: String
    let type: String
    let size: Int
    let contents: TorrentFiles?
    let progresses: [Double]? // Only when it is a dir
}

struct TorrentFile: Identifiable, Hashable {

    fileprivate init(name: String, data: RawTorrentFileStructureNode) {
        self.name = name
        self.priority = data.priority
        self.index = data.index
        self.offset = data.offset
        self.progress = data.progress
        self.path = data.path
        self.type = data.type
        self.size = data.size
        self.contents = data.contents?.files
        self.progresses = data.progresses
    }

    let name: String
    var isDirectory: Bool { return type == "dir" }
    let id = UUID()

    let priority: Int
    let index: Int? // Only when it is a file
    let offset: Int? // Only when it is a file
    let progress: Double
    let path: String
    let type: String
    let size: Int
    let contents: [TorrentFile]?
    let progresses: [Double]? // Only when it is a dir
}

extension TorrentFile {

    func prettyPrint() {
        print(self.name)

        guard let children = contents else { return }
        for child in children where !child.isDirectory {
            print("\t\(child.name) - \(child.size.sizeString())")
        }
        for child in children where child.isDirectory {
            printChildrenHelper(node: child)
        }
    }

    private func printChildrenHelper(node: TorrentFile) {

        if !node.isDirectory {
            print("\t\t\(node.name) - \(node.size.sizeString()) ")
        } else {
            print("\t/\(node.name)")
            guard let children = node.contents else { return }
            for child in children {
                printChildrenHelper(node: child)
            }
        }

    }
}

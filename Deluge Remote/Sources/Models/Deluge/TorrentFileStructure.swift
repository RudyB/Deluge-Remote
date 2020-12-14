//
//  TorrentFileStructure.swift
//  DelugeRemote
//
//  Created by Rudy Bermudez on 6/29/20.
//

import Foundation

typealias DirectoryName = String

struct TorrentFileList: Decodable {

    let files: [TorrentFileStructureNode]

    enum CodingKeys: String, CodingKey {
        case files = "contents"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        let data = try values.decode([DirectoryName:RawTorrentFileStructureNode].self)
        files  = data.map { TorrentFileStructureNode(name: $0, data: $1) }
    }
}

struct TorrentFileStructure: Decodable {
    let type: String
    private let contents: TorrentFileList
    var isDirectory: Bool { return type == "dir" }
    
    var files: [TorrentFileStructureNode] { return contents.files }
}


struct RawTorrentFileStructureNode: Decodable
{
    let priority: Int
    let index: Int? // Only when it is a file
    let offset: Int? // Only when it is a file
    let progress: Double
    let path: String
    let type: String
    let size: Int
    let contents: TorrentFileList?
    let progresses: [Double]? // Only when it is a dir
}

struct TorrentFileStructureNode: Identifiable, Hashable {

    init(name: String, data: RawTorrentFileStructureNode) {
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
    let contents: [TorrentFileStructureNode]?
    let progresses: [Double]? // Only when it is a dir
}

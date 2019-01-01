//: Playground - noun: a place where people can play

import UIKit

//var str = "Hello, playground"
//
//enum WebSecurityProtocol {
//    case https
//    case http(port: Int)
//
//    func port() -> Int {
//        switch self {
//        case .https:
//            return 443
//        case .http(let port):
//            return port
//        }
//    }
//
//    func name() -> String {
//        switch self {
//        case .https:
//            return "https://"
//        default:
//            return "http://"
//        }
//    }
//}
//
//WebSecurityProtocol.https.name()
//WebSecurityProtocol.http(port: 2390).port()
//
//let port = WebSecurityProtocol.http(port: 80)
//
//port.port()
//
//let url = "https://wall.seedhost.eu"
//var newURL = URL(string: url)!
//var relativePath = "/plexserver/deluge"
//
//let hostname = url
//var host = hostname.replacingOccurrences(of: "http://", with: "")
//host = host.replacingOccurrences(of: "https://", with: "")
//
//port.name()
//newURL.host
//port.port()
//newURL.path
//
//let newestURL = "\(port.name())\(newURL.host!):\(port.port())\(relativePath)/json"
//
//let count = ByteCountFormatter()
//count.string(fromByteCount: 8224171119)

//extension Int {
//    func transferRateString() -> String {
//        return sizeString() + "/s"
//    }
//
//    func sizeString() -> String {
//        return ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: ByteCountFormatter.CountStyle.memory)
//    }
//}
//
//7047517042.sizeString()
////let formatter = DateFormatter()
////formatter.dateFormat = "MM/d/yyyy, h:mm a"
////formatter.string(from: Date(timeIntervalSince1970: 1545806976.0))
//
//let formatter = DateComponentsFormatter()
//
//formatter.allowedUnits = [.year, .day, .hour, .minute]
//formatter.unitsStyle = .full
//
//let formattedString = formatter.string(from: TimeInterval(170823))!
//
//let tracker = URL(string: "http://bttracker.debian.org:6969/announce")!
//tracker.host

extension Int {
    func transferRateString() -> String {
        return sizeString() + "/s"
    }
    
    func sizeString() -> String {
        return ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: ByteCountFormatter.CountStyle.memory)
    }
}



let jsonData1 =
"""
{
    "id": "1135417108",
    "result": {
        "files_tree": {
            "type": "dir",
            "contents": {
                "Catch-22 (147)": {
                    "download": true,
                    "length": 742296,
                    "type": "dir",
                    "contents": {
                        "metadata.opf": {
                            "download": true,
                            "path": "Catch-22 (147)/metadata.opf",
                            "length": 3504,
                            "type": "file",
                            "index": 2
                        },
                        "cover.jpg": {
                            "download": true,
                            "path": "Catch-22 (147)/cover.jpg",
                            "length": 26213,
                            "type": "file",
                            "index": 1
                        },
                        "Catch-22 - Joseph Heller.mobi": {
                            "download": true,
                            "path": "Catch-22 (147)/Catch-22 - Joseph Heller.mobi",
                            "length": 712579,
                            "type": "file",
                            "index": 0
                        }
                    }
                }
            }
        },
        "name": "Catch-22 (147)",
        "info_hash": "bc5dfc6b86e4ce4f635d3036a79100bcfe9a1ec3"
    },
    "error": null
}
""".data(using: .utf8)!

let jsonData2 = """
{
"id": "1",
"result": {
"files_tree": {
"type": "dir",
"contents": {
"In.A.Lonely.Place.1950.DVDRip.XviD-MDX": {
"download": true,
"length": 751744065,
"type": "dir",
"contents": {
"Sample": {
"download": true,
"length": 7960576,
"type": "dir",
"contents": {
"lonely.place.sample-mdx.avi": {
"download": true,
"path": "In.A.Lonely.Place.1950.DVDRip.XviD-MDX/Sample/lonely.place.sample-mdx.avi",
"length": 7960576,
"type": "file",
"index": 0
}
}
},
"In.A.Lonely.Place.1950.DVDRip.XviD-MDX.avi": {
"download": true,
"path": "In.A.Lonely.Place.1950.DVDRip.XviD-MDX/In.A.Lonely.Place.1950.DVDRip.XviD-MDX.avi",
"length": 734631936,
"type": "file",
"index": 3
},
"Subs": {
"download": true,
"length": 9140765,
"type": "dir",
"contents": {
"lonely.place.subs-mdx.rar": {
"download": true,
"path": "In.A.Lonely.Place.1950.DVDRip.XviD-MDX/Subs/lonely.place.subs-mdx.rar",
"length": 9140411,
"type": "file",
"index": 1
},
"lonely.place.subs-mdx.sfv": {
"download": true,
"path": "In.A.Lonely.Place.1950.DVDRip.XviD-MDX/Subs/lonely.place.subs-mdx.sfv",
"length": 354,
"type": "file",
"index": 2
}
}
},
"lonely.place-mdx.nfo": {
"download": true,
"path": "In.A.Lonely.Place.1950.DVDRip.XviD-MDX/lonely.place-mdx.nfo",
"length": 10788,
"type": "file",
"index": 4
}
}
}
}
},
"name": "In.A.Lonely.Place.1950.DVDRip.XviD-MDX",
"info_hash": "4d2352a604c7cb416c12ce85bee3b0d925563b7a"
},
"error": null
}
""".data(using: .utf8)!

let jsonData3 = """
{
"id": "1",
"result": {
"files_tree": {
"contents": {
"The New Confessions of An Economic Hit Man.epub": {
"download": true,
"index": 0,
"length": 4166871,
"type": "file"
}
}
},
"name": "The New Confessions of An Economic Hit Man.epub",
"info_hash": "ef74545675a02b8babc91f71ea744c94592fdea3"
},
"error": null
}
""".data(using: .utf8)!

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

func parseJSON() {
    let json = try! JSONSerialization.jsonObject(with: jsonData2) as! [String: Any]

    guard
        let result = json["result"] as? [String: Any]
    else { print("Failure"); return }

    guard
        let torrentName = result["name"] as? String,
        let torrentHash = result["info_hash"] as? String,
        let fileTree = result["files_tree"] as? [String: Any],
        let fileTreeContents = fileTree["contents"] as? [String: Any],
        let rootKey = fileTreeContents.keys.first,
        let rootJSON = fileTreeContents[rootKey] as? [String: Any]
    else { print("Failure 2"); return }

    let type = fileTree["type"] as? String
    let files = FileNode(fileName: rootKey, json: rootJSON)

    let info = TorrentInfo(name: torrentName, hash: torrentHash,
                           isDirectory: type == "dir", files: files)

    info.files.prettyPrint()
}

parseJSON()

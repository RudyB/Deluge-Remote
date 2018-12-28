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

extension Int {
    func transferRateString() -> String {
        return sizeString() + "/s"
    }

    func sizeString() -> String {
        return ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: ByteCountFormatter.CountStyle.memory)
    }
}

7047517042.sizeString()
//let formatter = DateFormatter()
//formatter.dateFormat = "MM/d/yyyy, h:mm a"
//formatter.string(from: Date(timeIntervalSince1970: 1545806976.0))

let formatter = DateComponentsFormatter()

formatter.allowedUnits = [.year, .day, .hour, .minute]
formatter.unitsStyle = .full

let formattedString = formatter.string(from: TimeInterval(170823))!

let tracker = URL(string: "http://bttracker.debian.org:6969/announce")!
tracker.host

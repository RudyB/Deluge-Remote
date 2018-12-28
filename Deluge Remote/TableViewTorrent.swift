//
//  TorrentMenuItem.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 7/18/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import Foundation

struct TableViewTorrent: Decodable, Comparable {
    static func < (lhs: TableViewTorrent, rhs: TableViewTorrent) -> Bool {
        return lhs.hash == rhs.hash
    }

	let download_payload_rate: Double
	let hash: String
	let ratio: Double
	let upload_payload_rate: Double
	let name: String
	let total_wanted: Double
	let progress: Double
	let state: String
	let tracker_host: String
	let label: String
	let eta: Double

}

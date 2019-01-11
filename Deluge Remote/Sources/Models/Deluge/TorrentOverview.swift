//
//  TorrentMenuItem.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 7/18/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import Foundation

struct TorrentOverview: Decodable, Equatable {
    static func == (lhs: TorrentOverview, rhs: TorrentOverview) -> Bool {
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
	let label: String?
    let time_added: Double
	let eta: Double
    let total_size: Int
    let all_time_download: Int
    let total_uploaded: Int
}

//
//  Protocols.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 11/9/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import Foundation

protocol JSONDecodable {
	init?(dataPoints: JSON)
}

typealias JSON = [String: Any]

extension Double {
	/// Rounds the double to decimal places value
	func roundTo(places: Int) -> Double {
		let divisor = pow(10.0, Double(places))
		return (self * divisor).rounded() / divisor
	}
}

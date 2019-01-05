//
//  Double.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 1/4/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import Foundation

extension Double {

    func timeRemainingString(unitStyle style: DateComponentsFormatter.UnitsStyle = .full) -> String? {
        if self > 0 {
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.year, .day, .hour, .minute, .second]
            formatter.unitsStyle = style
            return formatter.string(from: TimeInterval(self))
        } else {
            return "Done"
        }
    }

    /// Rounds the double to decimal places value
    func roundTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

}

//
//  ColorCompatibility.swift
//  Deluge Remote
//
//  Created by Maikel Reijnders on 12/10/2019.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import UIKit

enum ColorCompatibility {
    static var label: UIColor {
        if #available(iOS 13, *) {
            return .label
        }
        return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    }

    static var secondaryLabel: UIColor {
        if #available(iOS 13, *) {
            return .secondaryLabel
        }
        return UIColor(red: 0.9215686274509803, green: 0.9215686274509803, blue: 0.9607843137254902, alpha: 0.6)
    }

    // ... 21 more definitions: full code at the bottom of this post
}

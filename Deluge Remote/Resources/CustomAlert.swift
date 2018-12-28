//
//  CustomAlert.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 11/15/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import Foundation
import UIKit

func showAlert(target: UIViewController, title: String, message: String? = nil, style: UIAlertControllerStyle = .alert, actionList: [UIAlertAction] = [UIAlertAction(title: "OK", style: .default, handler: nil)] ) {
	let alert = UIAlertController(title: title, message: message, preferredStyle: style)
	for action in actionList {
		alert.addAction(action)
	}
	target.present(alert, animated: true, completion: nil)
}

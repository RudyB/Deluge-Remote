//
//  CustomAlert.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 11/15/16.
//  Copyright © 2016 Rudy Bermudez. All rights reserved.
//

import Foundation
import UIKit

/** Easily Create, Customize, and Present an UIAlertController on a UIViewController
 
 - Parameters:
 - target: The instance of a UIViewController that you would like to present tye UIAlertController upon.
 - title: The `title` for the UIAlertController.
 - message: Optional `message` field for the UIAlertController. nil by default
 - style: The `preferredStyle` for the UIAlertController. UIAlertControllerStyle.alert by default
 - actionList: A list of `UIAlertAction`. If no action is added, `[UIAlertAction(title: "OK", style: .default, handler: nil)]` will be added.
 
 */

func showAlert(target: UIViewController, title: String, message: String? = nil, style: UIAlertController.Style = .alert, sender: AnyObject? = nil, actionList: [UIAlertAction] = [UIAlertAction(title: "OK", style: .default, handler: nil)] ) {
    // swiftlint:disable:previous line_length

    let alert = UIAlertController(title: title, message: message, preferredStyle: style)

    if let button = sender as? UIBarButtonItem,
        style == .actionSheet {
        alert.modalPresentationStyle = .popover
        alert.popoverPresentationController?.barButtonItem = button
    }

	for action in actionList {
		alert.addAction(action)
	}

    if target.presentedViewController == nil {
        target.present(alert, animated: true, completion: nil)
    }
}

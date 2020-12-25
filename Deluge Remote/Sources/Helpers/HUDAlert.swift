//
//  HUDAlert.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 1/6/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import Foundation
import MBProgressHUD

extension UIView {

    enum HUDType {
        case success
        case failure
    }

    func showHUD(title: String, type: HUDType = .success, square: Bool = false, onCompletion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            
            var image: UIImage {
                return type == .success ?  #imageLiteral(resourceName: "icons8-checkmark") :  #imageLiteral(resourceName: "icons8-cancel")
            }
            
            let hud = MBProgressHUD.showAdded(to: self, animated: true)
            hud.mode = MBProgressHUDMode.customView
            hud.customView = UIImageView(image: image.withTintColor(.label))
            hud.isSquare = square
            hud.label.text = title
            let delay = type == .success ? 1.5 : 3.0
            hud.hide(animated: true, afterDelay: delay)
            hud.completionBlock = onCompletion
        }
    }
}

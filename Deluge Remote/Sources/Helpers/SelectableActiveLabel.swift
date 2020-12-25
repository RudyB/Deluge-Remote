//
//  SelectableLabel.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/22/20.
//  Copyright © 2020 Rudy Bermudez. All rights reserved.
//

import UIKit
import ActiveLabel

/// Label that allows selection with long-press gesture, e.g. for copy-paste.
class SelectableActiveLabel: ActiveLabel {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        enabledTypes = [.url]
        urlMaximumLength = 30
        handleURLTap { url in UIApplication.shared.open(url) }
        isUserInteractionEnabled = true
        addGestureRecognizer(
            UILongPressGestureRecognizer(
                target: self,
                action: #selector(handleLongPress(_:))
            )
        )
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }
    
    // MARK: - UIResponderStandardEditActions
    
    override func copy(_ sender: Any?) {
        UIPasteboard.general.string = text
    }
    
    
    
    // MARK: - Long-press Handler
    
    @objc func handleLongPress(_ recognizer: UIGestureRecognizer) {
        if recognizer.state == .began,
           let recognizerView = recognizer.view {
            recognizerView.becomeFirstResponder()
            let textWidth = sizeThatFits(CGSize(width: frame.size.width, height: CGFloat(MAXFLOAT))).width
            let xPos = recognizerView.frame.width-textWidth
            let adjusted = CGRect(x: xPos, y: recognizerView.frame.midY, width: textWidth, height: recognizerView.frame.height)
            UIMenuController.shared.showMenu(from: recognizerView, rect: adjusted)
        }
    }
    
}

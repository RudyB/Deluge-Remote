//
//  NotificationHelper.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 1/2/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import Foundation

final class NewTorrentNotifier {
    public static var shared = NewTorrentNotifier()

    private var _userInfo: [AnyHashable: Any]?

    private init() {}

    private let lockQueue = DispatchQueue(label: "io.rudybermudez.deluge.notificationHelper",
                                          qos: .default, attributes: .concurrent)

    public var userInfo: [AnyHashable: Any]? {
        set {
            lockQueue.async(flags: .barrier) {
                self._userInfo = newValue
                if self._didMainTableVCCreateObserver && newValue != nil {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name("AddTorrentNotification"),
                                                        object: nil, userInfo: self._userInfo)
                    }

                }
            }
        }
        get {
            return lockQueue.sync {
                return _userInfo
            }
        }
    }

    private var _didMainTableVCCreateObserver = false

    public var didMainTableVCCreateObserver: Bool {
        set {
            lockQueue.async(flags: .barrier) {
                self._didMainTableVCCreateObserver = newValue
                if newValue && self._userInfo != nil {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name("AddTorrentNotification"),
                                                        object: nil, userInfo: self._userInfo)
                    }
                }
            }
        }
        get {
            return lockQueue.sync {
                return _didMainTableVCCreateObserver
            }
        }
    }
}

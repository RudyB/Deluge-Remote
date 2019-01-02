//
//  ClientManager.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 12/26/18.
//  Copyright © 2018 Rudy Bermudez. All rights reserved.
//

import Foundation
import Valet

final class ClientManager {

    // MARK: Properties
    public static var shared = ClientManager()
    private var _activeClient: DelugeClient?
    private let lockQueue = DispatchQueue(label: "io.rudybermudez.deluge.clientManager",
                                          qos: .default, attributes: .concurrent)
    private let keychain = Valet.valet(with: Identifier(nonEmpty: "io.rudybermudez.deluge")!,
                                       accessibility: .whenUnlocked)

    public static let NewActiveClientNotification = "NewActiveClient"
    public var activeClient: DelugeClient? {
        get {
            return lockQueue.sync {
                return _activeClient
            }
        }
        set {
            lockQueue.async(flags: .barrier) {
                self._activeClient = newValue
            }
            if let newValue = newValue, let data = try? JSONEncoder().encode(newValue.clientConfig) {
                keychain.set(object: data, forKey: "ActiveClient")
            } else {
                keychain.removeObject(forKey: "ActiveClient")
            }

            NotificationCenter.default
                .post(name: Notification.Name(ClientManager.NewActiveClientNotification), object: nil)
        }
    }

    // MARK: Methods
    private init() {
        guard
            let data = keychain.object(forKey: "ActiveClient"),
            let config = try? JSONDecoder().decode(ClientConfig.self, from: data)
        else { return }
        self.activeClient = DelugeClient(config: config)
    }
}

//
//  PromiseKit.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 10/15/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import Foundation
import PromiseKit

func attempt<T>(maximumRetryCount: Int = 3, delayBeforeRetry: DispatchTimeInterval = .seconds(2), _ body: @escaping () -> Promise<T>) -> Promise<T> {
    var attempts = 0
    func attempt() -> Promise<T> {
        attempts += 1
        return body().recover { error -> Promise<T> in
            guard attempts < maximumRetryCount else { throw error }
            return after(interval: delayBeforeRetry).then(execute: attempt)
        }
    }
    return attempt()
}

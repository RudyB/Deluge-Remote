//
//  DelugeRequestRetrier.swift
//  Deluge Remote
//
//  Created by Rudy Bermudez on 1/7/19.
//  Copyright © 2019 Rudy Bermudez. All rights reserved.
//

import Alamofire
import Foundation
import Houston

class DelugeClientRequestRetrier: RequestRetrier {

    // [Request url: Number of times retried]
    private var retriedRequests: [String: Int] = [:]

    internal func should(_ manager: SessionManager,
                         retry request: Request,
                         with error: Error,
                         completion: @escaping RequestRetryCompletion) {

        guard
            request.task?.response == nil,
            error._code != NSURLErrorTimedOut,
            let url = request.request?.url?.absoluteString
        else {
            removeCachedUrlRequest(url: request.request?.url?.absoluteString)
            completion(false, 0.0) // don't retry
            return
        }

        Logger.debug("Retrying: \(url)")

        guard let retryCount = retriedRequests[url] else {
            retriedRequests[url] = 1
            completion(true, 1.0) // retry after 1 second
            return
        }

        if retryCount <= 3 {
            retriedRequests[url] = retryCount + 1
            completion(true, 1.0) // retry after 1 second
        } else {
            removeCachedUrlRequest(url: url)
            completion(false, 0.0) // don't retry
        }

    }

    private func removeCachedUrlRequest(url: String?) {
        guard let url = url else {
            return
        }
        retriedRequests.removeValue(forKey: url)
    }

}

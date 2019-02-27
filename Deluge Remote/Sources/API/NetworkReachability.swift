//
//  NetworkReachability.swift
//  Bulldog Bucks
//
//  Created by Rudy Bermudez on 11/23/16.
//
//

import Foundation
import SystemConfiguration

/**
 Determines if there is an active connection to the internet
 
 - Returns: `true` if Internet is Reachable else `false`
 */
func IsConnectedToNetwork() -> Bool {

    var zeroAddress = sockaddr()
    zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
    zeroAddress.sa_family = sa_family_t(AF_INET)

    guard let defaultRouteReachability: SCNetworkReachability = withUnsafePointer(to: &zeroAddress, {
        SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
    }) else { return false }

    var flags: SCNetworkReachabilityFlags = []
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
        return false
    }

    let isReachable = flags.contains(.reachable)
    let needsConnection = flags.contains(.connectionRequired)

    return (isReachable && !needsConnection)
}

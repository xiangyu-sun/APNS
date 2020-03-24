//
//  APNSResponse.swift
//  APNSKit
//
//  Created by xiangyu sun on 4/27/18.
//  Copyright © 2018 Uriphium. All rights reserved.
//

import Foundation


public enum APNServiceStatus: Error {
    case success
    case badRequest
    case badCertitficate
    case badMethod
    case deviceTokenIsNoLongerActive
    case badNotificationPayload
    case serverReceivedTooManyRequests
    case internalServerError
    case serverShutingDownOrUnavailable
    
    public static func statusCodeFrom(response:HTTPURLResponse) -> (Int, APNServiceStatus) {
        switch response.statusCode {
        case 400:
            return (response.statusCode,APNServiceStatus.badRequest)
        case 403:
            return (response.statusCode,APNServiceStatus.badCertitficate)
        case 405:
            return (response.statusCode,APNServiceStatus.badMethod)
        case 410:
            return (response.statusCode,APNServiceStatus.deviceTokenIsNoLongerActive)
        case 413:
            return (response.statusCode,APNServiceStatus.badNotificationPayload)
        case 429:
            return (response.statusCode,APNServiceStatus.serverReceivedTooManyRequests)
        case 500:
            return (response.statusCode,APNServiceStatus.internalServerError)
        case 503:
            return (response.statusCode,APNServiceStatus.serverShutingDownOrUnavailable)
        default: return (response.statusCode,APNServiceStatus.success)
        }
    }
}

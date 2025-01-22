//
//  CTClock.swift
//  CleverTapSDK
//
//  Created by Kushagra Mishra on 22/01/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

import Foundation

@objc
protocol CTClock: NSObjectProtocol {
    func timeIntervalSince1970() -> NSNumber
    func currentDate() -> Date
}

@objc(CTSystemClock)
class CTSystemClock: NSObject, CTClock {
    @objc
    func timeIntervalSince1970() -> NSNumber {
        return NSNumber(value: Date().timeIntervalSince1970)
    }
    
    @objc
    func currentDate() -> Date {
        return Date()
    }
}

//
//  InAppSchedulingStrategy.swift
//  CleverTapSDK
//
//  Created by Sonal Kachare on 22/01/26.
//  Copyright © 2026 CleverTap. All rights reserved.
//

import Foundation

/// Strategy protocol for handling storage operations before/after scheduling
@objc public protocol InAppSchedulingStrategy {
    
//    / Prepare data before scheduling (e.g., save to DB)
//    / - Parameter inApps: Array of in-app dictionaries
//    / - Returns: true if preparation successful, false otherwise
    @objc func prepareForScheduling(inApps: [[String: Any]]) -> Bool
    
    /// Retrieve data after timer completes
    /// - Parameter id: Timer identifier
    /// - Returns: Dictionary if found, nil otherwise
    @objc func retrieveAfterTimer(id: String) -> [String: Any]?
    
    /// Cleanup after timer completes or cancelled
    /// - Parameter id: Timer identifier
    @objc func clear(id: String)
    
    /// Clear all stored data
    @objc func clearAll()
}

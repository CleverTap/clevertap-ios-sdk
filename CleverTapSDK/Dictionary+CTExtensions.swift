//
//  Dictionary+CTExtensions.swift
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 5.06.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

import Foundation

@objc
public extension NSDictionary {

    /// Uses JSONSerialization. NSDate values will be removed from the result.
    /// - Returns: The JSON string representation using UTF8 encoding, or nil if serialization fails
    @objc(ct_toJsonString)
    func ct_toJsonString() -> String? {
        guard self.count > 0 else { return nil }

        do {
            let cleaned = NSMutableDictionary()

            for (key, value) in self {
                // Skip NSDate values
                if value is Date {
                    continue
                }
                cleaned[key] = value
            }

            let jsonData = try JSONSerialization.data(withJSONObject: cleaned, options: [])
            return String(data: jsonData, encoding: .utf8)
        } catch {
            return nil
        }
    }

    /// Executes the block on each dictionary value and returns a new dictionary.
    /// Does not deep copy the current dictionary. If the value is mutable and modified in the block,
    /// this will modify the current dictionary value.
    /// - Parameter block: The block to execute on each value
    /// - Returns: New dictionary with the transformed values
    @objc(ct_dictionaryWithTransformUsingBlock:)
    func ct_dictionaryWithTransform(using block: (Any) -> Any) -> NSDictionary {
        let result = NSMutableDictionary()

        self.enumerateKeysAndObjects { key, value, _ in
            let transformedValue = block(value)
            result[key] = transformedValue
        }

        return result.copy() as! NSDictionary
    }

    /// Removes NSNull values and returns a new dictionary. Current dictionary is unmodified.
    /// - Returns: New dictionary without NSNull values
    @objc(ct_dictionaryRemovingNullValues)
    func ct_dictionaryRemovingNullValues() -> NSDictionary {
        let keys = self.keysOfEntries { key, obj, stop in
            return obj != nil && !(obj is NSNull)
        }
        return self.dictionaryWithValues(forKeys: Array(keys) as! [String]) as NSDictionary
    }
}

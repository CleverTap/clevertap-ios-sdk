//
//  ContentMerger.swift
//  CleverTapSDK
//
//  Swift replacement for ContentMerger.h/.m. Recursively merges a server-delivered `diff`
//  onto a `vars` (defaults) tree, used by CTVarCache to overlay variable overrides.
//
//  Access control:
//  - `@objc(ContentMerger) @objcMembers public final class` preserves the exact ObjC class
//    name and keeps the merge entry point callable from CTVarCache.m. The Swift method
//    `merge(withVars:diff:)` maps to the original selector `mergeWithVars:diff:`.
//
//  Behaviour is a faithful translation of the ObjC recursion:
//   1. nil diff                          → return vars
//   2. diff is primitive (num/str/null)  → return diff
//   3. vars is primitive                 → return diff
//   4. neither is a dictionary           → return nil
//   5. vars is not a dictionary          → return diff
//   6. vars is a dictionary, diff is not → return a copy of vars
//   7. both are dictionaries             → merge recursively (skip keys whose merge is nil)
//
//  Note: `as? NSDictionary` is used as the isKindOfClass: equivalent — it fails for NSArray
//  (unlike a plain cast), matching the original type checks.

import Foundation

@objc(ContentMerger)
@objcMembers
public final class ContentMerger: NSObject {

    public static func merge(withVars vars: Any?, diff: Any?) -> Any? {
        guard let diff = diff else {
            return vars
        }

        // Return the modified value if it is a primitive
        if diff is NSNumber || diff is NSString || diff is NSNull {
            return diff
        }
        if let vars = vars, vars is NSNumber || vars is NSString || vars is NSNull {
            return diff
        }

        let varsDict = vars as? NSDictionary
        let diffDict = diff as? NSDictionary

        // Return nil if neither vars nor diff is a dictionary.
        if varsDict == nil && diffDict == nil {
            return nil
        }

        // vars is not a dictionary (diff is) → return diff
        guard let varsDict = varsDict else {
            return diff
        }

        // vars is a dictionary
        let merged = NSMutableDictionary(dictionary: varsDict)
        guard let diffDict = diffDict else {
            return merged
        }

        // vars and diff are dictionaries → merge recursively
        diffDict.enumerateKeysAndObjects { key, value, _ in
            let defaultValue = merged.object(forKey: key)
            if let mergedValue = ContentMerger.merge(withVars: defaultValue, diff: value) {
                merged.setObject(mergedValue, forKey: key as! NSCopying)
            }
        }

        return merged
    }
}

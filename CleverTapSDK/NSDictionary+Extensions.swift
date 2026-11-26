//
//  NSDictionary+Extensions.swift
//  CleverTapSDK
//
//  Swift replacement for the NSDictionary (Extensions) category (NSDictionary+Extensions.h/.m).
//  A Swift `extension NSDictionary` whose `@objc(…)` selectors are pinned byte-identical to the
//  original category methods, so the ObjC callers (CleverTap.m `toJsonString`; LeanplumCT.m
//  `dictionaryWithTransformUsingBlock:` + `dictionaryRemovingNullValues`) keep compiling via the
//  generated CleverTapSDK-Swift.h.
//
//  `public` is required: the ObjC *test* files reach these through the framework's public
//  -Swift.h (the test target is a separate module). This slightly widens NSDictionary's surface
//  for consumers — acceptable for a behavior-preserving migration of an internal utility.
//
//  Translation notes:
//  - The ObjC `@try/@catch` around NSJSONSerialization (Swift can't catch the ObjC
//    "invalid type" NSException) is replaced by an `isValidJSONObject` guard, preserving the
//    "return nil on non-serializable content" behavior.
//  - Return types stay immutable NSDictionary (matching the original `[result copy]` /
//    `dictionaryWithValuesForKeys:`). Verified no caller mutates the result (they `mutableCopy`
//    or read), so this is safe per the mutable-return-bridging rule.
//  - The `if (self == nil)` guard is dropped — `self` is never nil for a Swift instance method.

import Foundation

public extension NSDictionary {

    /// Uses JSONSerialization. NSDate values are removed from the result.
    /// Returns the UTF-8 JSON string, or nil if the content is not serializable.
    @objc(toJsonString)
    func toJsonString() -> String? {
        let cleaned = NSMutableDictionary()
        enumerateKeysAndObjects { key, value, _ in
            if value is NSDate { return }
            cleaned[key as! NSCopying] = value
        }
        guard JSONSerialization.isValidJSONObject(cleaned),
              let data = try? JSONSerialization.data(withJSONObject: cleaned) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    /// Executes the block on each value and returns a new dictionary. Does not deep copy — if a
    /// value is mutable and modified in the block, the current dictionary's value is modified too.
    @objc(dictionaryWithTransformUsingBlock:)
    func withTransformUsing(_ block: @escaping (Any) -> Any) -> NSDictionary {
        let result = NSMutableDictionary()
        enumerateKeysAndObjects { key, value, _ in
            result[key as! NSCopying] = block(value)
        }
        return result.copy() as! NSDictionary
    }

    /// Removes `NSNull` values and returns a new dictionary. Current dictionary is unmodified.
    @objc(dictionaryRemovingNullValues)
    func dictionaryRemovingNullValues() -> NSDictionary {
        let result = NSMutableDictionary()
        enumerateKeysAndObjects { key, value, _ in
            if value is NSNull { return }
            result[key as! NSCopying] = value
        }
        return result.copy() as! NSDictionary
    }
}

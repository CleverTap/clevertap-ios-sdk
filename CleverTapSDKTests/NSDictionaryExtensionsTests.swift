// NSDictionaryExtensionsTests.swift
// CleverTapSDKTests
//
// Swift Testing suite for the NSDictionary (Extensions) category — mirrors
// NSDictionaryExtensionsTest.m. Uses the modern Swift Testing framework (@Test / @Suite / #expect).
//
// These are ObjC category methods on NSDictionary (stateless), so inputs are declared as
// NSDictionary and the category methods are called directly. Structural comparisons use
// NSDictionary.isEqual(_:) to avoid Equatable-of-Any issues.
//
// Imported names (ObjC → Swift via "omit needless words"):
//   dictionaryWithTransformUsingBlock: → withTransformUsing(_:)
//   dictionaryRemovingNullValues       → dictionaryRemovingNullValues()  (kept full)
//   toJsonString                       → toJsonString()

import Testing
import Foundation
@testable import CleverTapSDK

@Suite("NSDictionary+Extensions")
struct NSDictionaryExtensionsTests {

    // MARK: - dictionaryWithTransformUsingBlock

    @Test("transform number values with block (original unchanged)")
    func transformNumberValuesWithBlock() {
        let original: NSDictionary = ["key1": 1, "key2": 2, "key3": 3]
        let transformed = original.withTransformUsing { value in
            if let n = value as? NSNumber { return NSNumber(value: n.intValue * 2) }
            return value
        }
        let expected: NSDictionary = ["key1": 2, "key2": 4, "key3": 6]
        #expect(!original.isEqual(transformed))
        #expect((transformed as NSDictionary).isEqual(expected))
    }

    @Test("transform string/dict values with block (original unchanged)")
    func transformValuesWithBlock() {
        let original: NSDictionary = ["str": "str", "dict": ["test": 123]]
        let transformed = original.withTransformUsing { value in
            if value is String { return "mod" }
            if value is [AnyHashable: Any] { return ["mod": "mod"] }
            return value
        }
        let expected: NSDictionary = ["str": "mod", "dict": ["mod": "mod"]]
        #expect(!original.isEqual(transformed))
        #expect((transformed as NSDictionary).isEqual(expected))
    }

    @Test("transform mutable values mutates the original (no deep copy)")
    func transformMutableValuesWithBlock() {
        let mstr = NSMutableString(string: "mstr")
        let mdict = NSMutableDictionary(dictionary: ["test": 123])
        let original: NSDictionary = ["mstr": mstr, "mdict": mdict]
        let transformed = original.withTransformUsing { value in
            if let ms = value as? NSMutableString { ms.append("mod"); return ms }
            if let md = value as? NSMutableDictionary { md["mod"] = "mod"; return md }
            return value
        }
        let expected: NSDictionary = ["mstr": "mstrmod", "mdict": ["test": 123, "mod": "mod"]]
        // Original's mutable values were modified in-place, so it now equals expected too.
        #expect(original.isEqual(expected))
        #expect((transformed as NSDictionary).isEqual(expected))
    }

    @Test("transform array values like LeanplumCT.transformArrayValuesInDictionary")
    func transformArrayValuesMirrorsLeanplumUsage() {
        // Mirrors the production block in LeanplumCT.transformArrayValuesInDictionary:
        // array values become "[v0,v1,...]" (NSNull filtered out); non-array values pass through.
        let original: NSDictionary = ["arr": [1, 2, NSNull(), 3], "name": "Alice"]
        let transformed = original.withTransformUsing { value in
            if let array = value as? [Any] {
                let filtered = array.filter { !($0 is NSNull) }
                let joined = filtered.map { ($0 as AnyObject).description }.joined(separator: ",")
                return "[\(joined)]"
            }
            return value
        }
        let expected: NSDictionary = ["arr": "[1,2,3]", "name": "Alice"]
        #expect((transformed as NSDictionary).isEqual(expected))
    }

    // MARK: - dictionaryRemovingNullValues

    @Test("removes NSNull values")
    func removeNullValues() {
        let original: NSDictionary = ["key1": "value1", "key2": NSNull(), "key3": "value3", "key4": NSNull()]
        let expected: NSDictionary = ["key1": "value1", "key3": "value3"]
        let transformed = original.dictionaryRemovingNullValues()
        #expect((transformed as NSDictionary).isEqual(expected))
    }

    // MARK: - toJsonString

    @Test("toJsonString simple dict returns valid json")
    func toJsonStringSimpleDict() throws {
        let dict: NSDictionary = ["a": 1, "b": "hello"]
        let json = try #require(dict.toJsonString())
        let data = try #require(json.data(using: .utf8))
        let roundTripped = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(roundTripped["a"] as? NSNumber == 1)
        #expect(roundTripped["b"] as? String == "hello")
    }

    @Test("toJsonString empty dict returns empty json")
    func toJsonStringEmptyDict() {
        let json = ([:] as NSDictionary).toJsonString()
        #expect(json == "{}")
    }

    @Test("toJsonString filters out NSDate")
    func toJsonStringFiltersOutNSDate() throws {
        let dict: NSDictionary = ["date": Date(), "name": "Alice"]
        let json = try #require(dict.toJsonString())
        #expect(!json.contains("\"date\""))
        #expect(json.contains("name"))
    }

    @Test("toJsonString nested dict returns valid json")
    func toJsonStringNestedDict() throws {
        let dict: NSDictionary = ["outer": ["inner": 42]]
        let json = try #require(dict.toJsonString())
        let data = try #require(json.data(using: .utf8))
        let roundTripped = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect((roundTripped["outer"] as? [String: Any])?["inner"] as? NSNumber == 42)
    }

    @Test("toJsonString non-serializable value returns nil")
    func toJsonStringNonSerializableValue() {
        let dict: NSDictionary = ["bad": NSObject()]
        #expect(dict.toJsonString() == nil)
    }
}

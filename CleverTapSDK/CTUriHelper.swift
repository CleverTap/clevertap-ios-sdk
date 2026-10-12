//
//  CTUriHelper.swift
//  CleverTapSDK
//
//  Swift replacement for CTUriHelper.h/.m. Stateless URL/urchin parsing helper used by
//  CleverTap.m (deep-link referrer + query parsing).
//
//  Access control:
//  - `@objc(CTUriHelper) @objcMembers public final class` preserves the exact ObjC class name
//    and the two class-method selectors (`getUrchinFromUri:withSourceApp:`,
//    `getQueryParameters:andDecode:`) used by the ObjC callers. The private helpers stay
//    `private static` (internal to the parsing).
//
//  Translation notes:
//  - The ObjC source wrapped its logic in defensive `@try/@catch (NSException)` blocks
//    ("won't happen"). Swift cannot catch ObjC NSExceptions, and none of the operations here
//    (URL(string:), String components, dictionary access) throw, so the guards are dropped —
//    the observable nil / empty-dictionary fallbacks are preserved via optionals/guards.
//  - The `wm` validation `^email$|^social$|^search$` (an anchored full-match alternation) is
//    expressed as membership in {email, social, search} — exactly equivalent.

import Foundation

@objc(CTUriHelper)
@objcMembers
public final class CTUriHelper: NSObject {

    // Returns a fresh NSMutableDictionary (not an immutable [String: Any]) because the caller
    // -[CleverTap _pushDeepLink:...] adds an "install" key to the result via setValue:forKey:.
    // The original ObjC implementation returned an NSMutableDictionary (declared as NSDictionary),
    // and bridging a Swift [String: Any] back to ObjC yields an immutable NSDictionary, which
    // would raise on mutation. Returning NSMutableDictionary preserves that contract.
    public static func getUrchinFromUri(_ uri: String?, withSourceApp sourceApp: String?) -> NSMutableDictionary {
        let referrer = NSMutableDictionary()

        // Don't care for null values — they won't be added anyway
        if let sourceApp = sourceApp, !sourceApp.isEmpty, !sourceApp.hasPrefix("fb") {
            referrer["referrer"] = sourceApp
        }
        if let source = getUtmOrWzrkValue("source", fromURI: uri) {
            referrer["us"] = source
        }
        if let medium = getUtmOrWzrkValue("medium", fromURI: uri) {
            referrer["um"] = medium
        }
        if let campaign = getUtmOrWzrkValue("campaign", fromURI: uri) {
            referrer["uc"] = campaign
        }
        if let wm = getWzrkValue(forKey: "medium", fromURI: uri),
           ["email", "social", "search"].contains(wm) {
            referrer["wm"] = wm
        }
        return referrer
    }

    public static func getQueryParameters(_ url: URL?, andDecode decode: Bool) -> [String: Any] {
        guard let url = url, let query = url.query else { return [:] }

        var params: [String: Any] = [:]
        for param in query.components(separatedBy: "&") {
            let elts = param.components(separatedBy: "=")
            if elts.count < 2 { continue }
            if decode {
                if let decoded = elts[1].removingPercentEncoding {
                    params[elts[0]] = decoded
                }
            } else {
                params[elts[0]] = elts[1]
            }
        }
        return params
    }

    // MARK: - private helpers

    // Give preference to utm_*, else try wzrk_*
    private static func getUtmOrWzrkValue(_ key: String, fromURI uri: String?) -> String? {
        getUtmValue(forKey: key, fromURI: uri) ?? getWzrkValue(forKey: key, fromURI: uri)
    }

    private static func getWzrkValue(forKey key: String, fromURI uri: String?) -> String? {
        normalizedValue(forKey: "wzrk_\(key)", fromURI: uri)
    }

    private static func getUtmValue(forKey key: String, fromURI uri: String?) -> String? {
        normalizedValue(forKey: "utm_\(key)", fromURI: uri)
    }

    // Whitespace-only values are treated as nil (not added), matching the ObjC trimming check.
    private static func normalizedValue(forKey key: String, fromURI uri: String?) -> String? {
        guard let value = value(forKey: key, fromURI: uri) else { return nil }
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return nil
        }
        return value
    }

    private static func value(forKey key: String, fromURI uri: String?) -> String? {
        guard let uri = uri, let url = URL(string: uri) else { return nil }
        return getQueryParameters(url, andDecode: false)[key] as? String
    }
}

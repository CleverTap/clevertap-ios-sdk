// CTInActionResult.swift
// CleverTapSDK
//
// Swift replacement for CTInActionResult.h/.m. Immutable value type describing the
// outcome of a scheduled in-action in-app.
//
// Access control:
// - `@objcMembers public final class` + `@objc public enum` preserve the public API
//   surface and keep the type usable from Objective-C. CTInAppDisplayManager.m switches
//   on `type` and reads `inActionId`/`message`; InAppDataExtractor.swift creates instances.
// - Enum raw values are kept in declaration order (readyToFetch=0, error=1, cancelled=2,
//   discarded=3) to match the original NS_ENUM.

import Foundation

@objc public enum CTInActionResultType: Int {
    case readyToFetch
    case error
    case cancelled
    case discarded
}

@objcMembers
public final class CTInActionResult: NSObject {

    public let type: CTInActionResultType
    public let inActionId: String
    public let data: [String: Any]?
    public let message: String?

    private init(type: CTInActionResultType,
                 inActionId: String,
                 data: [String: Any]?,
                 message: String?) {
        self.type = type
        self.inActionId = inActionId
        self.data = data
        self.message = message
        super.init()
    }

    public static func readyToFetch(withId inActionId: String, data: [String: Any]) -> CTInActionResult {
        CTInActionResult(type: .readyToFetch, inActionId: inActionId, data: data, message: nil)
    }

    public static func error(withId inActionId: String, message: String) -> CTInActionResult {
        CTInActionResult(type: .error, inActionId: inActionId, data: nil, message: message)
    }

    public static func cancelled(withId inActionId: String, message: String) -> CTInActionResult {
        CTInActionResult(type: .cancelled, inActionId: inActionId, data: nil, message: message)
    }

    public static func discarded(withId inActionId: String, message: String) -> CTInActionResult {
        CTInActionResult(type: .discarded, inActionId: inActionId, data: nil, message: message)
    }
}

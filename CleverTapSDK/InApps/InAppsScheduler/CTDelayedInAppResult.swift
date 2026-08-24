// CTDelayedInAppResult.swift
// CleverTapSDK
//
// Swift replacement for CTDelayedInAppResult.h/.m. Immutable value type describing the
// outcome of a scheduled delayed in-app.
//
// Access control:
// - `@objcMembers public final class` + `@objc public enum` preserve the public API
//   surface and keep the type usable from Objective-C. CTInAppDisplayManager.m switches
//   on `type` and reads `data`; InAppDataExtractor.swift creates instances via the
//   factory methods.
// - Enum raw values are kept in declaration order to match the original NS_ENUM
//   (CTDelayedInAppResultType: success=0, error=1, discarded=2 —
//    CTErrorReason: unknown=0, preparationFailed=1, dataNotFound=2).
//
// API note: the original ObjC header declared the factory methods `instancetype _Nullable`
// and `resultId` as `_Nullable`, but the factories never return nil and always copy a
// `_Nonnull` id. This translation drops the accidental nullability (factories return a
// non-optional instance, `resultId` is non-optional) — matching the CTInActionResult
// sibling and avoiding an implicit optional→Any coercion warning at the call site in
// InAppDataExtractor.swift. `data`/`exception`/`message` remain optional (case-specific).

import Foundation

@objc public enum CTDelayedInAppResultType: Int {
    case success
    case error
    case discarded
}

@objc public enum CTErrorReason: Int {
    case unknown
    case preparationFailed
    case dataNotFound
}

@objcMembers
public final class CTDelayedInAppResult: NSObject {

    public let type: CTDelayedInAppResultType
    public let resultId: String

    // Success case
    public let data: [String: Any]?

    // Error case
    public let reason: CTErrorReason
    public let exception: NSError?

    // Discarded case
    public let message: String?

    private init(type: CTDelayedInAppResultType,
                 resultId: String,
                 data: [String: Any]?,
                 reason: CTErrorReason,
                 exception: NSError?,
                 message: String?) {
        self.type = type
        self.resultId = resultId
        self.data = data
        self.reason = reason
        self.exception = exception
        self.message = message
        super.init()
    }

    public static func success(withId resultId: String, data: [String: Any]?) -> CTDelayedInAppResult {
        CTDelayedInAppResult(type: .success, resultId: resultId, data: data, reason: .unknown, exception: nil, message: nil)
    }

    public static func error(withId resultId: String, reason: CTErrorReason, exception: NSError?) -> CTDelayedInAppResult {
        CTDelayedInAppResult(type: .error, resultId: resultId, data: nil, reason: reason, exception: exception, message: nil)
    }

    public static func discarded(withId resultId: String, message: String?) -> CTDelayedInAppResult {
        CTDelayedInAppResult(type: .discarded, resultId: resultId, data: nil, reason: .unknown, exception: nil, message: message)
    }
}

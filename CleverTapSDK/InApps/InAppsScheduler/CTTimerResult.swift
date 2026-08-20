// CTTimerResult.swift
// CleverTapSDK
//
// Swift replacement for CTTimerResult.h/.m. Immutable value type describing the
// outcome of a scheduled in-app timer.
//
// Access control:
// - `@objcMembers public final class` + `@objc public enum` preserve the existing
//   public API surface and keep the type usable from Objective-C (it appears in the
//   generated CleverTapSDK-Swift.h). The InAppsScheduler module (InAppTimerManager.swift)
//   consumes it from Swift; ObjC callers see the same `completedWithId:scheduledAt:`,
//   `errorWithId:exception:`, `discardedWithId:` selectors as before.
// - Enum raw values are kept in declaration order (completed=0, error=1, discarded=2)
//   to match the original NS_ENUM.

import Foundation

@objc public enum CTTimerResultType: Int {
    case completed
    case error
    case discarded
}

@objcMembers
public final class CTTimerResult: NSObject {

    public let type: CTTimerResultType
    public let resultId: String
    public let scheduledAt: TimeInterval
    public let exception: NSError?

    private init(type: CTTimerResultType,
                 resultId: String,
                 scheduledAt: TimeInterval,
                 exception: NSError?) {
        self.type = type
        self.resultId = resultId
        self.scheduledAt = scheduledAt
        self.exception = exception
        super.init()
    }

    public static func completed(withId resultId: String, scheduledAt: TimeInterval) -> CTTimerResult {
        CTTimerResult(type: .completed, resultId: resultId, scheduledAt: scheduledAt, exception: nil)
    }

    public static func error(withId resultId: String, exception: NSError?) -> CTTimerResult {
        CTTimerResult(type: .error, resultId: resultId, scheduledAt: 0, exception: exception)
    }

    public static func discarded(withId resultId: String) -> CTTimerResult {
        CTTimerResult(type: .discarded, resultId: resultId, scheduledAt: 0, exception: nil)
    }
}

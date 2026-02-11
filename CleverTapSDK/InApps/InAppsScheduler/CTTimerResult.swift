//
//  CTTimerResult.swift
//  CleverTapSDK
//
//  Created by Sonal Kachare on 23/01/26.
//

import Foundation

@objc public enum CTTimerResultType: Int {
    case completed
    case error
    case discarded
}

@objc(CTTimerResult)
@objcMembers
public class CTTimerResult: NSObject {

    // MARK: - Properties

    public let type: CTTimerResultType
    public let resultId: String?
    public let scheduledAt: TimeInterval
    public let exception: NSError?

    // MARK: - Private Initialization

    private init(type: CTTimerResultType, resultId: String?, scheduledAt: TimeInterval = 0, exception: NSError? = nil) {
        self.type = type
        self.resultId = resultId
        self.scheduledAt = scheduledAt
        self.exception = exception
        super.init()
    }

    // MARK: - Factory Methods

    @objc(completedWithId:scheduledAt:)
    public static func completed(withId id: String, scheduledAt: TimeInterval) -> CTTimerResult {
        return CTTimerResult(type: .completed, resultId: id, scheduledAt: scheduledAt)
    }

    @objc(errorWithId:exception:)
    public static func error(withId id: String, exception: NSError) -> CTTimerResult {
        return CTTimerResult(type: .error, resultId: id, exception: exception)
    }

    @objc(discardedWithId:)
    public static func discarded(withId id: String) -> CTTimerResult {
        return CTTimerResult(type: .discarded, resultId: id)
    }
}

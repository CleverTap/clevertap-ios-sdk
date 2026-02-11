//
//  CTDelayedInAppResult.swift
//  CleverTapSDK
//
//  Created by Sonal Kachare on 24/01/26.
//

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

@objc(CTDelayedInAppResult)
@objcMembers
public class CTDelayedInAppResult: NSObject {

    // MARK: - Properties

    public let type: CTDelayedInAppResultType
    public let resultId: String?
    public let data: [String: Any]?
    public let reason: CTErrorReason
    public let exception: NSError?
    public let message: String?

    // MARK: - Private Initialization

    private init(
        type: CTDelayedInAppResultType,
        resultId: String?,
        data: [String: Any]? = nil,
        reason: CTErrorReason = .unknown,
        exception: NSError? = nil,
        message: String? = nil
    ) {
        self.type = type
        self.resultId = resultId
        self.data = data
        self.reason = reason
        self.exception = exception
        self.message = message
        super.init()
    }

    // MARK: - Factory Methods

    @objc(successWithId:data:)
    public static func success(withId resultId: String, data: [String: Any]?) -> CTDelayedInAppResult {
        return CTDelayedInAppResult(type: .success, resultId: resultId, data: data)
    }

    @objc(errorWithId:reason:exception:)
    public static func error(withId resultId: String, reason: CTErrorReason, exception: NSError?) -> CTDelayedInAppResult {
        return CTDelayedInAppResult(type: .error, resultId: resultId, reason: reason, exception: exception)
    }

    @objc(discardedWithId:message:)
    public static func discarded(withId resultId: String, message: String?) -> CTDelayedInAppResult {
        return CTDelayedInAppResult(type: .discarded, resultId: resultId, message: message)
    }
}

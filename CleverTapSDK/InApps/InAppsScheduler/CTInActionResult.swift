//
//  CTInActionResult.swift
//  CleverTapSDK
//
//  Created by Sonal Kachare on 24/01/26.
//

import Foundation

@objc public enum CTInActionResultType: Int {
    case readyToFetch
    case error
    case cancelled
    case discarded
}

@objc(CTInActionResult)
@objcMembers
public class CTInActionResult: NSObject {

    // MARK: - Properties

    public let type: CTInActionResultType
    public let inActionId: String
    public let data: [String: Any]?
    public let message: String?

    // MARK: - Private Initialization

    private init(
        type: CTInActionResultType,
        inActionId: String,
        data: [String: Any]? = nil,
        message: String? = nil
    ) {
        self.type = type
        self.inActionId = inActionId
        self.data = data
        self.message = message
        super.init()
    }

    // MARK: - Factory Methods

    @objc(readyToFetchWithId:data:)
    public static func readyToFetch(withId inActionId: String, data: [String: Any]) -> CTInActionResult {
        return CTInActionResult(type: .readyToFetch, inActionId: inActionId, data: data)
    }

    @objc(errorWithId:message:)
    public static func error(withId inActionId: String, message: String) -> CTInActionResult {
        return CTInActionResult(type: .error, inActionId: inActionId, message: message)
    }

    @objc(cancelledWithId:message:)
    public static func cancelled(withId inActionId: String, message: String) -> CTInActionResult {
        return CTInActionResult(type: .cancelled, inActionId: inActionId, message: message)
    }

    @objc(discardedWithId:message:)
    public static func discarded(withId inActionId: String, message: String) -> CTInActionResult {
        return CTInActionResult(type: .discarded, inActionId: inActionId, message: message)
    }
}

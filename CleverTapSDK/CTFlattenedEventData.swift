//
//  CTFlattenedEventData.swift
//  CleverTapSDK
//
//  Copyright © 2023 CleverTap. All rights reserved.
//

import Foundation

@objc public enum CTFlattenedEventDataType: Int {
    case profileChanges
    case eventProperties
    case noData
}

@objc(CTFlattenedEventData)
@objcMembers
public class CTFlattenedEventData: NSObject {

    // MARK: - Properties

    public let type: CTFlattenedEventDataType
    private let data: [String: Any]?

    // MARK: - Singleton for noData case

    @objc public static let noData: CTFlattenedEventData = {
        return CTFlattenedEventData(type: .noData, data: nil)
    }()

    // MARK: - Private Initialization

    private init(type: CTFlattenedEventDataType, data: [String: Any]?) {
        self.type = type
        self.data = data
        super.init()
    }

    // MARK: - Factory Methods

    @objc(profileChanges:)
    public static func profileChanges(_ changes: [String: Any]) -> CTFlattenedEventData {
        return CTFlattenedEventData(type: .profileChanges, data: changes)
    }

    @objc(eventProperties:)
    public static func eventProperties(_ properties: [String: Any]) -> CTFlattenedEventData {
        return CTFlattenedEventData(type: .eventProperties, data: properties)
    }

    // MARK: - Public Methods

    @objc
    public func profileChanges() -> [String: Any]? {
        return type == .profileChanges ? data : nil
    }

    @objc
    public func eventProperties() -> [String: Any]? {
        return type == .eventProperties ? data : nil
    }

    @objc
    public func isNoData() -> Bool {
        return type == .noData
    }
}

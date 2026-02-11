//
//  CleverTapEventDetail.swift
//  CleverTapSDK
//

import Foundation

@objc(CleverTapEventDetail)
@objcMembers
public class CleverTapEventDetail: NSObject {
    public var eventName: String?
    public var normalizedEventName: String?
    public var firstTime: TimeInterval = 0
    public var lastTime: TimeInterval = 0
    public var count: UInt = 0
    public var deviceID: String?

    public override var description: String {
        return "CleverTapEventDetail (event name = \(eventName ?? "nil"); normalized event name = \(normalizedEventName ?? "nil"); first time = \(Int(firstTime)), last time = \(Int(lastTime)); count = \(count); device ID = \(deviceID ?? "nil"))"
    }
}

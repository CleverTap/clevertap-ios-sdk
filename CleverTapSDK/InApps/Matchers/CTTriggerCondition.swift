//
//  CTTriggerCondition.swift
//  CleverTapSDK
//
//  Migrated from CTTriggerCondition.m (originally created by Nikola Zagorchev on 2.09.23).
//  Copyright © 2023 CleverTap. All rights reserved.
//

import Foundation

/// A single property condition of a trigger: the property name, the comparison operator,
/// and the expected value. Built from server JSON by `CTTriggerAdapter` and evaluated by
/// `CTTriggerEvaluator`.
@objcMembers
public final class CTTriggerCondition: NSObject {

    /// The event-property name this condition tests.
    ///
    /// Non-optional: the ObjC origin declared it `nonnull` and a nil name would already have
    /// crashed the lookup in `-[CTEventAdapter getPropertyValue:]` (`NSDictionary` nil-key
    /// subscript), so nil was never a working path upstream.
    public let propertyName: String

    /// The comparison operator, stored as the raw `CTTriggerOperator` code rather than the
    /// enum type. This mirrors the ObjC behaviour `self.op = (CTTriggerOperator)op;`, which
    /// kept unknown, server-sent codes verbatim. `CTTriggerEvaluator` compares against the
    /// known `CTTriggerOperator` constants and routes anything else to "no match", so an
    /// unknown code must survive untouched (a sealed Swift enum would not allow that).
    public let op: UInt

    /// The expected value to compare the event property against.
    public let value: CTTriggerValue

    @available(*, unavailable)
    public override init() {
        fatalError("init() is unavailable; use initWithProperyName:andOperator:andValue:")
    }

    @objc(initWithProperyName:andOperator:andValue:)
    public init(properyName: String, op: UInt, value: CTTriggerValue) {
        self.propertyName = properyName
        self.op = op
        self.value = value
        super.init()
    }
}

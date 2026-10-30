//
//  CTTriggerOperator.swift
//  CleverTapSDK
//
//  Swift replacement for CTTriggerOperator.h — the operator codes for a trigger property condition.
//  Migrated 2026-10-30, completing the InApps/Matchers cluster.
//
//  `@objc public enum … : Int` keeps the named constants (e.g. `CTTriggerOperatorEquals`) available to
//  the one remaining ObjC consumer, CTNdGateTest.m, via the framework's CleverTapSDK-Swift.h. The enum
//  is used only as a *named constant*: the operator actually stored on CTTriggerCondition and passed to
//  CTTriggerEvaluator is a raw `UInt`, so an unknown, server-sent code still passes through verbatim to
//  the evaluator's switch `default` ("no match"). That forward-compat — the reason the old ObjC NS_ENUM
//  was kept "open" — now lives in the `UInt`, not here, so a sealed Swift enum is safe.
//

import Foundation

@objc public enum CTTriggerOperator: Int {
    case greaterThan = 0
    case equals = 1
    case lessThan = 2
    case contains = 3
    case between = 4
    case notEquals = 15
    case set = 26         // Exists
    case notSet = 27      // Not exists
    case notContains = 28
}

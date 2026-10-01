//
//  CTTriggerRadius.swift
//  CleverTapSDK
//
//  Swift replacement for CTTriggerRadius.h/.m. Plain mutable data holder for a geo-radius
//  trigger (latitude / longitude / radius), populated by CTTriggerAdapter.geoRadiusAtIndex:
//  from the trigger JSON (lat / lng / rad) and read by CTTriggersMatcher.
//
//  Access control:
//  - `@objcMembers public final class` preserves the API surface and keeps the type usable
//    from Objective-C (CTTriggerAdapter.m creates instances and assigns the properties;
//    CTTriggersMatcher.m / CTTriggerAdapterTest.m read them).
//
//  Migration note: the original ObjC header was NS_ASSUME_NONNULL with three
//  `strong NSNumber *` properties, but they are nil until assigned and CTTriggerAdapter
//  assigns possibly-nil JSON values (item[@"lat"] etc.). The nonnull annotation was
//  therefore incorrect. The Swift properties are now optional (NSNumber?), matching the
//  runtime reality and the `_Nullable` return of geoRadiusAtIndex:.

import Foundation

@objcMembers
public final class CTTriggerRadius: NSObject {
    public var latitude: NSNumber?
    public var longitude: NSNumber?
    public var radius: NSNumber?
}

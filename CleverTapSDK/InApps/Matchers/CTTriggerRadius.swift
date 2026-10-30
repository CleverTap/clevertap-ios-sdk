//
//  CTTriggerRadius.swift
//  CleverTapSDK
//
//  Swift replacement for CTTriggerRadius.h/.m. Plain mutable data holder for a geo-radius
//  trigger (latitude / longitude / radius), populated by CTTriggerAdapter.geoRadiusAtIndex:
//  from the trigger JSON (lat / lng / rad) and read by CTTriggersMatcher.
//
//  Internal to the (now all-Swift) Matchers cluster: CTTriggerAdapter (Swift) creates instances
//  and assigns the properties; CTTriggersMatcher (Swift) reads them. No ObjC consumer remains, so
//  the @objcMembers interop scaffold has been removed.
//
//  Migration note: the original ObjC header was NS_ASSUME_NONNULL with three
//  `strong NSNumber *` properties, but they are nil until assigned and CTTriggerAdapter
//  assigns possibly-nil JSON values (item[@"lat"] etc.). The nonnull annotation was
//  therefore incorrect. The Swift properties are now optional (NSNumber?), matching the
//  runtime reality and the `_Nullable` return of geoRadiusAtIndex:.

import Foundation

final class CTTriggerRadius: NSObject {
    var latitude: NSNumber?
    var longitude: NSNumber?
    var radius: NSNumber?
}

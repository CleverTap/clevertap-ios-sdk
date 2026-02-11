//
//  CTTriggerRadius.swift
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 5.11.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

import Foundation

@objc(CTTriggerRadius)
@objcMembers
public class CTTriggerRadius: NSObject {

    // MARK: - Properties

    public var latitude: NSNumber?
    public var longitude: NSNumber?
    public var radius: NSNumber?
}

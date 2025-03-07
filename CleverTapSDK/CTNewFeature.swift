//
//  CTNewFeature.swift
//  CleverTapSDK
//
//  Created by Akash Malhotra on 14/10/24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

import Foundation

@objc public class CTNewFeature: NSObject {
    @objc public func newFeature() {
        CTRequestFactory.description()
    }
}

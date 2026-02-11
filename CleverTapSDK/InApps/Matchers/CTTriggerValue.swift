//
//  CTTriggerValue.swift
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 31.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

import Foundation

@objc(CTTriggerValue)
@objcMembers
public class CTTriggerValue: NSObject {

    // MARK: - Properties

    public let value: Any
    public let stringValue: String?
    public let numberValue: NSNumber?
    public let arrayValue: [Any]?

    // MARK: - Initialization

    @objc(initWithValue:)
    public init(value: Any) {
        self.value = value

        if let string = value as? String {
            self.stringValue = string
            self.numberValue = nil
            self.arrayValue = nil
        } else if let number = value as? NSNumber {
            self.stringValue = nil
            self.numberValue = number
            self.arrayValue = nil
        } else if let array = value as? [Any] {
            self.stringValue = nil
            self.numberValue = nil
            self.arrayValue = array
        } else {
            self.stringValue = nil
            self.numberValue = nil
            self.arrayValue = nil
        }

        super.init()
    }

    // MARK: - Public Methods

    @objc
    public func isArray() -> Bool {
        return arrayValue != nil
    }
}

//
//  CTKnownProfileFields.swift
//  CleverTapSDK
//

import Foundation

@objc
public enum KnownField: Int {
    case name = 100
    case email
    case education
    case married
    case dob
    case birthday
    case employed
    case gender
    case phone
    case age
    case unknown
}

@objc(CTKnownProfileFields)
@objcMembers
public class CTKnownProfileFields: NSObject {

    private static let fieldMap: [String: KnownField] = [
        "Name": .name,
        "Email": .email,
        "Education": .education,
        "Married": .married,
        "DOB": .dob,
        "Birthday": .birthday,
        "Employed": .employed,
        "Gender": .gender,
        "Phone": .phone,
        "Age": .age
    ]

    @objc
    public static func getKnownFieldIfPossible(forKey key: String) -> KnownField {
        return fieldMap[key] ?? .unknown
    }
}

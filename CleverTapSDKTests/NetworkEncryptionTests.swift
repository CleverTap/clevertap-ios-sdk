//
//  NetworkEncryptionTests.swift
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 03/05/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

import UIKit
import XCTest
@testable import CleverTapSDK

class NetworkEncryptionTests: XCTestCase {
    
    func testSessionKeyIsConsistent() {
        let manager = NetworkEncryptionManager.shared
        let key1 = manager.getSessionKeyBase64()
        let key2 = manager.getSessionKeyBase64()
        XCTAssertEqual(key1, key2, "Session key should be consistent across multiple calls")
    }
    
    func testSessionKeyBase64IsNotNilOrEmpty() {
        let keyBase64 = NetworkEncryptionManager.shared.getSessionKeyBase64()
        XCTAssertNotNil(keyBase64, "Base64 key should not be nil")
        XCTAssertFalse(keyBase64!.isEmpty, "Base64 key should not be empty")
    }
    
    func testEncryptReturnsExpectedKeys() {
        let input = ["foo": "bar"]
        let encrypted = NetworkEncryptionManager.shared.encrypt(object: input)
        
        XCTAssertNotNil(encrypted["encryptedPayload"], "\"encryptedPayload\" key should be present")
        XCTAssertNotNil(encrypted["nonceData"], "\"nonceData\" key should be present")
        
        XCTAssertTrue(encrypted["encryptedPayload"] is String)
        XCTAssertTrue(encrypted["nonceData"] is Data)
    }
    
    func testEncryptDecryptRoundTrip() {
        let original = ["user": "alice", "score": 100] as [String : Any]
        let manager = NetworkEncryptionManager.shared
        let encrypted = manager.encrypt(object: original)
        
        guard let payload = encrypted["encryptedPayload"] as? String,
              let nonceData = encrypted["nonceData"] as? Data else {
            XCTFail("Encryption failed or missing keys")
            return
        }
        
        let mockAPIResponse: [String: Any] = [
            NetworkEncryptionManager.ITP: payload,
            NetworkEncryptionManager.ITV: nonceData.base64EncodedString()
        ]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: mockAPIResponse, options: [])
        let decrypted = manager.decrypt(responseData: jsonData)
        
        XCTAssertFalse(decrypted.isEmpty, "Decrypted data should not be empty")
        
        guard let result = try? JSONSerialization.jsonObject(with: decrypted) as? [String: Any] else {
            XCTFail("Failed to deserialize decrypted data")
            return
        }
        XCTAssertEqual(result["user"] as? String, "alice")
        XCTAssertEqual(result["score"] as? Int, 100)
    }
    
    func testDecryptFailsWithGarbageData() {
        let invalidData = Data("not-a-json".utf8)
        let decrypted = NetworkEncryptionManager.shared.decrypt(responseData: invalidData)
        XCTAssertEqual(decrypted, Data(), "Invalid JSON input should return empty data")
    }
    
    func testDecryptFailsWithMissingFields() {
        let incomplete = [NetworkEncryptionManager.ITP: "dummy"]
        guard let data = try? JSONSerialization.data(withJSONObject: incomplete, options: []) else {
            XCTFail("Failed to serialize incomplete response")
            return
        }
        let decrypted = NetworkEncryptionManager.shared.decrypt(responseData: data)
        XCTAssertEqual(decrypted, Data(), "Missing nonce should cause decryption failure")
    }
    
    func testDecryptFailsWithCorruptPayload() {
        let corrupt = [
            NetworkEncryptionManager.ITP: Data("invalid".utf8).base64EncodedString(),
            NetworkEncryptionManager.ITV: Data("nonce".utf8).base64EncodedString()
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: corrupt, options: []) else {
            XCTFail("Failed to serialize corrupt response")
            return
        }
        let decrypted = NetworkEncryptionManager.shared.decrypt(responseData: data)
        XCTAssertEqual(decrypted, Data(), "Corrupt encrypted payload should not crash and should return empty data")
    }
    
    func testEncryptInvalidJSONObjectReturnsEmpty() {
        let manager = NetworkEncryptionManager.shared
        
        // Create an invalid JSON object (e.g., a custom class instance)
        class NotEncodable {}
        let invalidObject = NotEncodable()
        
        let result = manager.encrypt(object: invalidObject)
        
        XCTAssertTrue(result.isEmpty, "Encrypt should return an empty dictionary for invalid JSON objects")
    }

}

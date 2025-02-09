//
//  CTEncryptionManager.swift
//  CleverTapSDK
//
//  Created by Kushagra Mishra on 07/02/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

import Foundation
import CryptoKit

@available(iOSApplicationExtension 13.0, *)
@objc(CTEncryptionManager)
class CTEncryptionManager: NSObject {
    private let keychainManager: CTKeychainManager
    private let aesGCM: CTAESGCMCrypt
    private let AES_GCM_PREFIX = "<ct<"
    private let AES_GCM_SUFFIX = ">ct>"

    @objc
    init(keychainTag: String) {
        self.keychainManager = CTKeychainManager(keychainTag: keychainTag)
        self.aesGCM = CTAESGCMCrypt()
    }

    private func getOrCreateKey() throws -> SymmetricKey {
        do {
            let keyData = try keychainManager.retrieveKey()
            return SymmetricKey(data: keyData)
        } catch {
            let newKey = aesGCM.generateKey()
            try keychainManager.saveKey(newKey.withUnsafeBytes { Data($0) })
            return newKey
        }
    }

    @objc
    func encryptData(_ data: Data) throws -> Data {
        let key = try getOrCreateKey()
        let encrypted = try aesGCM.encrypt(data, using: key)

        // Combine nonce, ciphertext, and tag
        var combinedData = Data()
        
        // Add prefix
        if let prefixData = AES_GCM_PREFIX.data(using: .utf8) {
            combinedData.append(prefixData)
        }
        
        combinedData.append(encrypted.nonce.withUnsafeBytes { Data($0) })
        combinedData.append(encrypted.ciphertext)
        combinedData.append(encrypted.tag)
        
        // Add suffix
        if let suffixData = AES_GCM_SUFFIX.data(using: .utf8) {
            combinedData.append(suffixData)
        }
        return combinedData
    }

    @objc
    func decryptData(_ combinedData: Data) throws -> Data {
        // Check for prefix and suffix
        guard let prefix = AES_GCM_PREFIX.data(using: .utf8),
              let suffix = AES_GCM_SUFFIX.data(using: .utf8) else {
            throw EncryptionError.invalidInput
        }
        
        // Verify prefix and suffix
        guard combinedData.starts(with: prefix),
              combinedData.suffix(suffix.count) == suffix else {
            throw EncryptionError.invalidInput
        }
        
        // Remove prefix and suffix
        let strippedData = combinedData.dropFirst(prefix.count).dropLast(suffix.count)
        
        // Verify minimum length (12 for nonce + 16 for tag + actual data)
        guard strippedData.count >= 28 else {
            throw EncryptionError.invalidInput
        }

        let nonceData = strippedData.prefix(12)
        let tagData = strippedData.suffix(16)
        let ciphertextData = strippedData.dropFirst(12).dropLast(16)

        let nonce = try AES.GCM.Nonce(data: nonceData)
        let encryptedData = EncryptedData(
            ciphertext: ciphertextData,
            nonce: nonce,
            tag: tagData
        )

        let key = try getOrCreateKey()
        let decryptedData = try aesGCM.decrypt(encryptedData, using: key)
        return decryptedData
    }
}

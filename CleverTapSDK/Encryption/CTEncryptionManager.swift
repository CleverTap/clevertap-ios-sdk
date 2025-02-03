//
//  CTEncryptionManager.swift
//  CleverTapSDK
//
//  Created by Kushagra Mishra on 03/02/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

import Foundation
import CryptoKit

@available(iOSApplicationExtension 13.0, *)
@objc(CTEncryptionManager)
class CTEncryptionManager: NSObject {
    private let keychainManager: CTKeychainManager
    private let aesGCM: CTAESGCMCrypt
    
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
        combinedData.append(encrypted.nonce.withUnsafeBytes { Data($0) }) // Fixed: proper nonce data conversion
        combinedData.append(encrypted.ciphertext)
        combinedData.append(encrypted.tag)
        
        return combinedData
    }
    
    @objc
    func decryptData(_ combinedData: Data) throws -> Data {
        guard combinedData.count >= 28 else { // 12 (nonce) + 16 (tag) minimum
            throw EncryptionError.invalidInput
        }
        
        let nonceData = combinedData.prefix(12)
        let tagData = combinedData.suffix(16)
        let ciphertextData = combinedData.dropFirst(12).dropLast(16)
        
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
    
    @objc
    func encryptDataWithAES(_ data: Data) throws -> Data {
        let key = try getOrCreateKey()
        let encrypted = try aesGCM.encrypt(data, using: key)
        
        // Combine nonce, ciphertext, and tag
        var combinedData = Data()
        combinedData.append(encrypted.nonce.withUnsafeBytes { Data($0) }) // Fixed: proper nonce data conversion
        combinedData.append(encrypted.ciphertext)
        combinedData.append(encrypted.tag)
        
        return combinedData
    }
    
    @objc
    func decryptDataWithAES(_ combinedData: Data) throws -> Data {
        guard combinedData.count >= 28 else { // 12 (nonce) + 16 (tag) minimum
            throw EncryptionError.invalidInput
        }
        
        let nonceData = combinedData.prefix(12)
        let tagData = combinedData.suffix(16)
        let ciphertextData = combinedData.dropFirst(12).dropLast(16)
        
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

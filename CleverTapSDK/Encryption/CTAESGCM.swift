//
//  CTAESGCM.swift
//  CleverTapSDK
//
//  Created by Kushagra Mishra on 03/02/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

import Foundation
import CryptoKit

@objc public enum AESGCMEncryptionErrorCode: Int {
    case encryptionFailed
    case decryptionFailed
    case invalidData
    case dataNotFound
}

@objcMembers
class AESGCMCryptResult: NSObject {
    let iv: Data
    let data: Data
    
    init(iv: Data, data: Data) {
        self.iv = iv
        self.data = data
        super.init()
    }
}

@objc enum CryptError: Int, Error {
    case invalidMode = 0
    case keyGenerationFailed = 1
    case encryptionFailed = 2
    case decryptionFailed = 3
    case ivRequired = 4
}

@available(iOS 13, *)
@objcMembers
class AESGCMCrypt: NSObject {
    private let keyIdentifier = "your.key.identifier"
    private static let ivSize = 12
    
    private func generateOrGetKey() throws -> SymmetricKey {
        if let existingKey = try? getKeyFromKeychain() {
            return existingKey
        }
        
        let newKey = SymmetricKey(size: .bits256)
        try storeKeyInKeychain(newKey)
        return newKey
    }
    
    func performCryptOperation(mode: Bool, data: Data, iv: Data? = nil) throws -> AESGCMCryptResult {
        let key = try generateOrGetKey()
        
        if mode { // Encrypt
            let nonce = try AES.GCM.Nonce(data: iv ?? Data())
            let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
            
            return AESGCMCryptResult(
                iv: sealedBox.nonce.withUnsafeBytes { Data($0) },
                data: sealedBox.ciphertext + sealedBox.tag
            )
        } else { // Decrypt
            guard let iv = iv else {
                throw CryptError.ivRequired
            }
            
            let tagLength = 16
            let ciphertext = data.dropLast(tagLength)
            let tag = data.suffix(tagLength)
            
            let nonce = try AES.GCM.Nonce(data: iv)
            let sealedBox = try AES.GCM.SealedBox(
                nonce: nonce,
                ciphertext: ciphertext,
                tag: tag
            )
            
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return AESGCMCryptResult(iv: iv, data: decryptedData)
        }
    }
    
    
    private func storeKeyInKeychain(_ key: SymmetricKey) throws {
            // Implement secure key storage in Keychain
        }
        
        private func getKeyFromKeychain() throws -> SymmetricKey? {
            // Implement secure key retrieval from Keychain
            return nil
        }
}

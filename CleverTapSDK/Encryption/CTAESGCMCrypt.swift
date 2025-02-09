//
//  CTAESGCMCrypt.swift
//  CleverTapSDK
//
//  Created by Kushagra Mishra on 07/02/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

import Foundation
import CryptoKit

@available(iOSApplicationExtension 13.0, *)
class CTAESGCMCrypt {
    private let keySize = SymmetricKeySize.bits256
    
    func generateKey() -> SymmetricKey {
        return SymmetricKey(size: keySize)
    }
    
    func encrypt(_ data: Data, using key: SymmetricKey) throws -> EncryptedData {
        let nonce = try AES.GCM.Nonce(data: Data(count: 12))
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
        
        return EncryptedData(
            ciphertext: sealedBox.ciphertext,
            nonce: sealedBox.nonce,
            tag: sealedBox.tag
        )
    }
    
    func decrypt(_ encryptedData: EncryptedData, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(
            nonce: encryptedData.nonce,
            ciphertext: encryptedData.ciphertext,
            tag: encryptedData.tag
        )
        
        return try AES.GCM.open(sealedBox, using: key)
    }
}

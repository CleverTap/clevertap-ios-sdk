//
//  CTCryptModel.swift
//  CleverTapSDK
//
//  Created by Kushagra Mishra on 07/02/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

import Foundation
import CryptoKit

@available(iOSApplicationExtension 13.0, *)
struct EncryptedData {
    let ciphertext: Data
    let nonce: AES.GCM.Nonce
    let tag: Data
}

enum KeychainError: Error {
    case unableToStoreKey
    case unableToRetrieveKey
    case unableToDeleteKey
}

enum EncryptionError: Error {
    case invalidInput
    case encryptionFailed
    case decryptionFailed
}

enum CryptoOperation {
    case encrypt
    case decrypt
}

enum EncryptionAlgorithm {
    case AES
    case AES_GCM
}

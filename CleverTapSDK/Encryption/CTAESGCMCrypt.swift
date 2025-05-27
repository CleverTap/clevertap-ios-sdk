import Foundation
import CryptoKit
import Security

@available(iOS 13.0, tvOS 13.0, *)
@objc(CTAESGCMCrypt)
public class AESGCMCrypt: NSObject {
    // MARK: - Properties
    private let keychainTag: String
    private let AES_GCM_PREFIX = "<ct<"
    private let AES_GCM_SUFFIX = ">ct>"
    
    @objc public init(keychainTag: String) {
        self.keychainTag = keychainTag
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Encrypts a string and returns a base64 encoded string with a prefix and suffix.
    @objc public func encryptString(_ message: String, error errorPointer: NSErrorPointer) -> String? {
        guard let data = message.data(using: .utf8) else {
            setNSError(errorPointer, cryptError: .stringToDataConversionFailed)
            return nil
        }
        return encryptData(data, error: errorPointer)
    }
    
    /// Encrypts data using AES-GCM and returns a formatted string.
    @objc public func encryptData(_ data: Data, error errorPointer: NSErrorPointer) -> String? {
        do {
            let key = try getKey()
            let nonce = AES.GCM.Nonce()
            let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
            
            let nonceData = nonce.withUnsafeBytes { Data($0) }
            let combinedData = nonceData + sealedBox.ciphertext + sealedBox.tag
            let base64String = combinedData.base64EncodedString()
            return "\(AES_GCM_PREFIX)\(base64String)\(AES_GCM_SUFFIX)"
        } catch {
            setNSError(errorPointer, cryptError: .encryptionFailed)
            return nil
        }
    }
    
    /// Decrypts an encrypted string and returns the original string.
    @objc public func decryptString(_ encryptedString: String, error errorPointer: NSErrorPointer) -> String? {
        guard let decryptedData = decryptData(encryptedString, error: errorPointer),
              let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            return nil
        }
        return decryptedString
    }
    
    /// Decrypts an encrypted string and returns the original data.
    @objc public func decryptData(_ encryptedString: String, error errorPointer: NSErrorPointer) -> Data? {
        guard let combinedData = extractCombinedData(from: encryptedString, error: errorPointer) else {
            return nil
        }
        let nonceLength = 12
        let tagLength = 16
        
        do {
            let nonce = combinedData.prefix(nonceLength)
            let ciphertext = combinedData.dropFirst(nonceLength).dropLast(tagLength)
            let tag = combinedData.suffix(tagLength)
            
            let key = try getKey()
            let nonceBytes = try AES.GCM.Nonce(data: nonce)
            let sealedBox = try AES.GCM.SealedBox(nonce: nonceBytes, ciphertext: ciphertext, tag: tag)
            
            do {
                return try AES.GCM.open(sealedBox, using: key)
            } catch {
                if error.localizedDescription.contains("authentication") {
                    throw CryptError.authenticationFailed
                } else {
                    throw CryptError.decryptionFailed
                }
            }
        } catch {
            setNSError(errorPointer, cryptError: .decryptionFailed)
            return nil
        }
    }
    
    // MARK: - Private Helpers
    
    /// Extracts and validates the base64 encoded encrypted data.
    private func extractCombinedData(from encryptedString: String, error errorPointer: NSErrorPointer) -> Data? {
        guard encryptedString.hasPrefix(AES_GCM_PREFIX),
              encryptedString.hasSuffix(AES_GCM_SUFFIX) else {
            setNSError(errorPointer, cryptError: .invalidFormat)
            return nil
        }
        
        let base64String = String(encryptedString.dropFirst(AES_GCM_PREFIX.count).dropLast(AES_GCM_SUFFIX.count))
        
        guard let combinedData = Data(base64Encoded: base64String) else {
            setNSError(errorPointer, cryptError: .invalidBase64)
            return nil
        }
        
        let nonceLength = 12
        let tagLength = 16
        
        guard combinedData.count > nonceLength + tagLength else {
            setNSError(errorPointer, cryptError: .invalidDataLength)
            return nil
        }
        return combinedData
    }
    
    // MARK: - Keychain Operations
    
    /// Retrieves or generates an AES key and stores it securely in the Keychain.
    @available(iOS 13.0, tvOS 13.0, *)
    private func getKey() throws -> SymmetricKey {
        if let existingKey = try retrieveKeyFromKeychain() {
            return existingKey
        }
        let newKey = SymmetricKey(size: .bits256)
        try saveKeyToKeychain(newKey)
        return newKey
    }
    
    /// Saves the AES key to the Keychain.
    @available(iOS 13.0, tvOS 13.0, *)
    private func saveKeyToKeychain(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        // Query to identify the item
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keychainTag.data(using: .utf8)!
        ]
        
        // Attributes to update
        let attributes: [String: Any] = [
            kSecValueData as String: keyData
        ]
        
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        if updateStatus == errSecSuccess {
            // Item was successfully updated
            print("Keychain item successfully updated")
            return
        } else if updateStatus == errSecItemNotFound {
            // Item doesn't exist, so add it
            print("Keychain item not found, attempting to add")
            let addQuery: [String: Any] = query.merging([
                kSecValueData as String: keyData,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]) { (_, new) in new }
            
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            if addStatus == errSecSuccess {
                print("Keychain item successfully added")
            } else {
                print("Failed to add keychain item, error: \(addStatus)")
                throw CryptError.keychainSaveFailed
            }
        } else {
            // Some other error occurred during update
            print("Failed to update keychain item, error: \(updateStatus)")
            throw CryptError.keychainSaveFailed
        }
    }
    
    /// Retrieves the AES key from the Keychain if available.
    @available(iOS 13.0, tvOS 13.0, *)
    private func retrieveKeyFromKeychain() throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keychainTag.data(using: .utf8)!,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let keyData = result as? Data else {
            return nil
        }
        return SymmetricKey(data: keyData)
    }
    
    // MARK: - Error Handling
    
    private enum CryptError: Error {
        case stringToDataConversionFailed
        case encryptionFailed
        case decryptionFailed
        case invalidFormat
        case invalidBase64
        case invalidDataLength
        case keychainSaveFailed
        case authenticationFailed
    }
    
    /// Converts CryptError to NSError and assigns it to the provided error pointer.
    private func setNSError(_ errorPointer: NSErrorPointer?, cryptError: CryptError) {
        guard let errorPointer = errorPointer else { return }
        
        let errorMessage: String
        let errorCode: Int
        
        switch cryptError {
        case .stringToDataConversionFailed:
            errorMessage = "Failed to convert string to Data."
            errorCode = 1001
        case .encryptionFailed:
            errorMessage = "Encryption process failed."
            errorCode = 1002
        case .decryptionFailed:
            errorMessage = "Decryption process failed."
            errorCode = 1003
        case .invalidFormat:
            errorMessage = "Invalid format of encrypted data."
            errorCode = 1004
        case .invalidBase64:
            errorMessage = "Base64 decoding failed."
            errorCode = 1005
        case .invalidDataLength:
            errorMessage = "Data length is invalid."
            errorCode = 1006

        case .keychainSaveFailed:
            errorMessage = "Failed to save key to keychain."
            errorCode = 1007
        case .authenticationFailed:
            errorMessage = "Authentication failed."
            errorCode = 1008
        }
        
        errorPointer?.pointee = NSError(domain: "AESGCMCrypt", code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
    }
}

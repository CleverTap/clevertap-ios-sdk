import Foundation
import CryptoKit
import Security

@available(iOSApplicationExtension 13.0, *)
@objc(CTAESGCMCrypt)
public class AESGCMCrypt: NSObject {
    private let keychainTag: String
    private let AES_GCM_PREFIX = "<ct<"
    private let AES_GCM_SUFFIX = ">ct>"
    
    @objc public init(keychainTag: String) {
        self.keychainTag = keychainTag
        super.init()
    }
    
    // MARK: - Public Methods
    
    @objc public func encryptString(_ message: String, error: NSErrorPointer) -> String? {
        guard let data = message.data(using: .utf8) else {
            if let error = error {
                error.pointee = NSError(domain: "AESGCMCrypt",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data"])
            }
            return nil
        }
        
        do {
            let key = try getKey()
            let nonce = AES.GCM.Nonce()
            
            guard let sealedBox = try? AES.GCM.seal(data, using: key, nonce: nonce) else {
                throw NSError(domain: "AESGCMCrypt",
                              code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Encryption failed"])
            }
            
            let nonceData = nonce.withUnsafeBytes { Data($0) }
            let combinedData = nonceData + sealedBox.ciphertext + sealedBox.tag
            let base64String = combinedData.base64EncodedString()
            return "\(AES_GCM_PREFIX)\(base64String)\(AES_GCM_SUFFIX)"
            
        } catch let catchError as NSError {
            if let error = error {
                error.pointee = catchError
            }
            return nil
        }
    }
    
    @objc public func encryptData(_ data: Data, error: NSErrorPointer) -> String? {
        
        do {
            let key = try getKey()
            let nonce = AES.GCM.Nonce()
            
            guard let sealedBox = try? AES.GCM.seal(data, using: key, nonce: nonce) else {
                throw NSError(domain: "AESGCMCrypt",
                              code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Encryption failed"])
            }
            
            let nonceData = nonce.withUnsafeBytes { Data($0) }
            let combinedData = nonceData + sealedBox.ciphertext + sealedBox.tag
            let base64String = combinedData.base64EncodedString()
            return "\(AES_GCM_PREFIX)\(base64String)\(AES_GCM_SUFFIX)"
            
        } catch let catchError as NSError {
            if let error = error {
                error.pointee = catchError
            }
            return nil
        }
    }
    
    @objc public func decryptString(_ encryptedString: String, error: NSErrorPointer) -> String? {
        guard encryptedString.hasPrefix(AES_GCM_PREFIX),
              encryptedString.hasSuffix(AES_GCM_SUFFIX) else {
            if let error = error {
                error.pointee = NSError(domain: "AESGCMCrypt",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid format"])
            }
            return nil
        }
        
        let startIndex = encryptedString.index(encryptedString.startIndex, offsetBy: AES_GCM_PREFIX.count)
        let endIndex = encryptedString.index(encryptedString.endIndex, offsetBy: -AES_GCM_SUFFIX.count)
        let base64String = String(encryptedString[startIndex..<endIndex])
        
        guard let combinedData = Data(base64Encoded: base64String) else {
            if let error = error {
                error.pointee = NSError(domain: "AESGCMCrypt",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid base64 data"])
            }
            return nil
        }
        
        let nonceLength = 12
        let tagLength = 16
        
        guard combinedData.count > nonceLength + tagLength else {
            if let error = error {
                error.pointee = NSError(domain: "AESGCMCrypt",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid data length"])
            }
            return nil
        }
        
        do {
            let nonce = combinedData.prefix(nonceLength)
            let ciphertext = combinedData.dropFirst(nonceLength).dropLast(tagLength)
            let tag = combinedData.suffix(tagLength)
            
            let key = try getKey()
            
            guard let nonceBytes = try? AES.GCM.Nonce(data: nonce) else {
                throw NSError(domain: "AESGCMCrypt",
                              code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Invalid nonce"])
            }
            
            let sealedBox = try AES.GCM.SealedBox(nonce: nonceBytes,
                                                  ciphertext: ciphertext,
                                                  tag: tag)
            
            guard let decryptedData = try? AES.GCM.open(sealedBox, using: key),
                  let decryptedString = String(data: decryptedData, encoding: .utf8) else {
                throw NSError(domain: "AESGCMCrypt",
                              code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Decryption failed"])
            }
            
            return decryptedString
            
        } catch let catchError as NSError {
            if let error = error {
                error.pointee = catchError
            }
            return nil
        }
    }
    
    @objc public func decryptData(_ encryptedString: String, error: NSErrorPointer) -> Data? {
        guard encryptedString.hasPrefix(AES_GCM_PREFIX),
              encryptedString.hasSuffix(AES_GCM_SUFFIX) else {
            if let error = error {
                error.pointee = NSError(domain: "AESGCMCrypt",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid format"])
            }
            return nil
        }
        
        let startIndex = encryptedString.index(encryptedString.startIndex, offsetBy: AES_GCM_PREFIX.count)
        let endIndex = encryptedString.index(encryptedString.endIndex, offsetBy: -AES_GCM_SUFFIX.count)
        let base64String = String(encryptedString[startIndex..<endIndex])
        
        guard let combinedData = Data(base64Encoded: base64String) else {
            if let error = error {
                error.pointee = NSError(domain: "AESGCMCrypt",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid base64 data"])
            }
            return nil
        }
        
        let nonceLength = 12
        let tagLength = 16
        
        guard combinedData.count > nonceLength + tagLength else {
            if let error = error {
                error.pointee = NSError(domain: "AESGCMCrypt",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid data length"])
            }
            return nil
        }
        
        do {
            let nonce = combinedData.prefix(nonceLength)
            let ciphertext = combinedData.dropFirst(nonceLength).dropLast(tagLength)
            let tag = combinedData.suffix(tagLength)
            
            let key = try getKey()
            
            guard let nonceBytes = try? AES.GCM.Nonce(data: nonce) else {
                throw NSError(domain: "AESGCMCrypt",
                              code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Invalid nonce"])
            }
            
            let sealedBox = try AES.GCM.SealedBox(nonce: nonceBytes,
                                                  ciphertext: ciphertext,
                                                  tag: tag)
            
            guard let decryptedData = try? AES.GCM.open(sealedBox, using: key) else {
                throw NSError(domain: "AESGCMCrypt",
                              code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "Decryption failed"])
            }
            
            return decryptedData
            
        } catch let catchError as NSError {
            if let error = error {
                error.pointee = catchError
            }
            return nil
        }
    }
    
    
    // MARK: - Keychain Operations
    
    @available(iOS 13.0, *)
    private func getKey() throws -> SymmetricKey {
        
        if let existingKey = try retrieveKeyFromKeychain() {
            return existingKey
        }
        
        let newKey = SymmetricKey(size: .bits256)
        try saveKeyToKeychain(newKey)
        return newKey
    }
    
    @available(iOS 13.0, *)
    private func saveKeyToKeychain(_ key: SymmetricKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keychainTag.data(using: .utf8)!,
            kSecValueData as String: key.withUnsafeBytes { Data($0) },
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw CryptError.keychainError
        }
    }
    
    @available(iOS 13.0, *)
    private func retrieveKeyFromKeychain() throws -> SymmetricKey? {
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keychainTag.data(using: .utf8)!,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            return nil
        }
        
        return SymmetricKey(data: keyData)
    }
    
}
    // MARK: - Error Types
    
    private enum CryptError: Error {
        case invalidFormat
        case keychainError
    }


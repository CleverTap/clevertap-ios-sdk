import Foundation
import Security
import CryptoKit

@objc public enum KeychainErrorCode: Int {
    case keyGenerationFailed
    case keychainError
    case keyNotFound
}

@objc public class CTKeychainManager: NSObject {
    // MARK: - Constants
    private static let keyAlias = "com.clevertap.encryption.key"
    
    @objc(getOrGenerateKeyAndReturnError:)
        public static func getOrGenerateKey() throws -> Data {
            // First try to load existing key
            if let existingKey = try? loadKeyFromKeychain() {
                return existingKey
            }
            
            // If no key exists, generate and store new one
            return try generateAndStoreKey()
        }
    
    private static func generateAndStoreKey() throws -> Data {
        // Generate random key data
        var keyData = Data(count: 32) // 256 bits
        let result = keyData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 32, bytes.baseAddress!)
        }
        
        guard result == errSecSuccess else {
            throw NSError(domain: "KeychainManager", code: KeychainErrorCode.keyGenerationFailed.rawValue)
        }
        
        // Store key in keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyAlias,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.default.app"
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "KeychainManager", code: KeychainErrorCode.keychainError.rawValue)
        }
        
        return keyData
    }
    
    @objc public static func loadKeyFromKeychain() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyAlias,
            kSecReturnData as String: true,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.default.app"
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            throw NSError(domain: "KeychainManager", code: KeychainErrorCode.keyNotFound.rawValue)
        }
        
        return keyData
    }
    
    @objc(deleteKeyAndReturnError:)
        public static func deleteKey() throws {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: keyAlias,
                kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.default.app"
            ]
            
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw NSError(domain: "KeychainManager", code: KeychainErrorCode.keychainError.rawValue)
            }
        }
}

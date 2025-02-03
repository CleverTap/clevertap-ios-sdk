import Foundation
import Security

class CTKeychainManager {
    private let keychainTag: String
    
    init(keychainTag: String) {
        self.keychainTag = keychainTag
    }
    
    func saveKey(_ key: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keychainTag.data(using: .utf8)!,
            kSecValueData as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Update existing key
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassKey,
                kSecAttrApplicationTag as String: keychainTag.data(using: .utf8)!
            ]
            
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: key
            ]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unableToStoreKey
            }
        } else if status != errSecSuccess {
            throw KeychainError.unableToStoreKey
        }
    }
    
    func retrieveKey() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keychainTag.data(using: .utf8)!,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            throw KeychainError.unableToRetrieveKey
        }
        
        return keyData
    }
    
    func deleteKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keychainTag.data(using: .utf8)!
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDeleteKey
        }
    }
}

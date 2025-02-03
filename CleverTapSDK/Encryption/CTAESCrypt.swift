import Foundation
import CommonCrypto

class CryptoUtils {
    // AES128 encryption/decryption method
    func aes128(operation: CCOperation,
                key: String,
                identifier: String,
                data: Data) -> Data? {
        // Prepare key
        var keyCString = [CChar](repeating: 0, count: kCCKeySizeAES128 + 1)
        key.getCString(&keyCString, maxLength: keyCString.count, encoding: .utf8)
        
        // Prepare identifier
        var identifierCString = [CChar](repeating: 0, count: kCCBlockSizeAES128 + 1)
        identifier.getCString(&identifierCString, maxLength: identifierCString.count, encoding: .utf8)
        
        // Prepare output buffer
        let outputAvailableSize = data.count + kCCBlockSizeAES128
        let outputBuffer = UnsafeMutableRawPointer.allocate(byteCount: outputAvailableSize, alignment: 1)
        defer { outputBuffer.deallocate() }
        
        var outputMovedSize: size_t = 0
        
        let cryptStatus = data.withUnsafeBytes { dataBytes in
            CCCrypt(
                operation,
                CCAlgorithm(kCCAlgorithmAES),
                CCOptions(kCCOptionPKCS7Padding),
                keyCString,
                kCCBlockSizeAES128,
                identifierCString,
                dataBytes.baseAddress,
                data.count,
                outputBuffer,
                outputAvailableSize,
                &outputMovedSize
            )
        }
        
        guard cryptStatus == kCCSuccess else {
            print("Failed to encode/decode with error code: \(cryptStatus)")
            return nil
        }
        
        return Data(bytes: outputBuffer, count: outputMovedSize)
    }
    
    // Get cached key
    func getCachedKey(from value: String) -> String? {
        guard let index = value.firstIndex(of: "_") else { return nil }
        return String(value[..<index])
    }
    
    // Get cached identifier
    func getCachedIdentifier(from value: String) -> String? {
        guard let index = value.firstIndex(of: "_") else { return nil }
        return String(value[value.index(after: index)...])
    }
    
    // Generate key password (assuming accountID is a property or passed in)
    func generateKeyPassword(accountID: String) -> String {
        return "\(kCRYPT_KEY_PREFIX)\(accountID)\(kCRYPT_KEY_SUFFIX)"
    }
    
    // Encrypt object to base64 string
    func getEncryptedBase64String<T: Codable>(objectToEncrypt: T) -> String? {
        do {
            let encoder = JSONEncoder()
            let dataValue = try encoder.encode(objectToEncrypt)
            
            guard let encryptedData = convertData(dataValue, withOperation: .encrypt) else {
                return nil
            }
            
            return encryptedData.base64EncodedString()
        } catch {
            print("Error encrypting object: \(error)")
            return nil
        }
    }
    
    // Decrypt object from base64 string
    func getDecryptedObject<T: Codable>(encryptedString: String) -> T? {
        guard let dataValue = Data(base64Encoded: encryptedString) else { return nil }
        
        do {
            guard let decryptedData = convertData(dataValue, withOperation: .decrypt) else {
                return nil
            }
            
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: decryptedData)
        } catch {
            print("Error decrypting object: \(error)")
            return nil
        }
    }
    
    // Helper method for encryption/decryption
    private func convertData(_ data: Data, withOperation operation: CryptoOperation) -> Data? {
        // You'll need to implement the key and identifier generation logic here
        // This is a placeholder and should be replaced with your actual key generation method
        let key = "YourDefaultKey"
        let identifier = "YourDefaultIdentifier"
        
        return aes128(
            operation: operation == .encrypt ? CCOperation(kCCEncrypt) : CCOperation(kCCDecrypt),
            key: key,
            identifier: identifier,
            data: data
        )
    }
    
    // Enum to represent crypto operation
    enum CryptoOperation {
        case encrypt
        case decrypt
    }
}

// Constants (you should replace these with your actual values)
private let kCRYPT_KEY_PREFIX = "PREFIX_"
private let kCRYPT_KEY_SUFFIX = "_SUFFIX"

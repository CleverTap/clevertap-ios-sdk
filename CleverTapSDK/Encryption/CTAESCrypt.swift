import Foundation
import CommonCrypto
import Security

enum CTCryptoError: Error {
    case keyGenerationFailed
    case encryptionFailed
    case decryptionFailed
    case keyManagementFailed
}

class CTAESCrypt {
    // Private keychain manager for key storage
    private let keychainManager: CTKeychainManager
    
    // Initialize with a specific keychain tag
    init(keychainTag: String) {
        self.keychainManager = CTKeychainManager(keychainTag: keychainTag)
    }
    
    // Generate a random encryption key
    private func generateRandomKey(length: Int = kCCKeySizeAES128) -> Data? {
        var key = Data(count: length)
        let result = key.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!)
        }
        return result == errSecSuccess ? key : nil
    }
    
    // Generate a random IV
    private func generateRandomIV(length: Int = kCCBlockSizeAES128) -> Data? {
        var iv = Data(count: length)
        let result = iv.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!)
        }
        return result == errSecSuccess ? iv : nil
    }
    
    // Ensure a key exists, generating one if necessary
    private func ensureKey() throws -> Data {
        do {
            return try keychainManager.retrieveKey()
        } catch {
            // Generate and save a new key if retrieval fails
            guard let newKey = generateRandomKey() else {
                throw CTCryptoError.keyGenerationFailed
            }
            try keychainManager.saveKey(newKey)
            return newKey
        }
    }
    
    // AES encryption method
    private func performCrypt(_ operation: CCOperation,
                               data: Data,
                               key: Data,
                               iv: Data) throws -> Data {
        guard key.count == kCCKeySizeAES128 else {
            throw CTCryptoError.keyManagementFailed
        }
        
        let dataLength = data.count
        let dataLength_ = size_t(dataLength)
        
        let bufferSize = dataLength + kCCBlockSizeAES128
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: bufferSize, alignment: 1)
        defer { buffer.deallocate() }
        
        let ivBuffer = (iv as NSData).bytes.assumingMemoryBound(to: UInt8.self)
        let keyBuffer = (key as NSData).bytes.assumingMemoryBound(to: UInt8.self)
        let dataBuffer = (data as NSData).bytes.assumingMemoryBound(to: UInt8.self)
        
        var numBytesProcessed: size_t = 0
        
        let cryptStatus = CCCrypt(operation,
                                  CCAlgorithm(kCCAlgorithmAES),
                                  CCOptions(kCCOptionPKCS7Padding),
                                  keyBuffer,
                                  key.count,
                                  ivBuffer,
                                  dataBuffer,
                                  dataLength_,
                                  buffer,
                                  bufferSize,
                                  &numBytesProcessed)
        
        guard cryptStatus == kCCSuccess else {
            throw (operation == CCOperation(kCCEncrypt))
                ? CTCryptoError.encryptionFailed
                : CTCryptoError.decryptionFailed
        }
        
        return Data(bytes: buffer, count: numBytesProcessed)
    }
    
    // Encrypt data
    func encrypt(_ data: Data) throws -> (encryptedData: Data, iv: Data) {
        // Ensure we have a key
        let key = try ensureKey()
        
        // Generate a random IV
        guard let iv = generateRandomIV() else {
            throw CTCryptoError.keyGenerationFailed
        }
        
        // Encrypt the data
        let encryptedData = try performCrypt(
            CCOperation(kCCEncrypt),
            data: data,
            key: key,
            iv: iv
        )
        
        return (encryptedData, iv)
    }
    
    // Decrypt data
    func decrypt(data: Data, iv: Data) throws -> Data {
        // Retrieve the key
        let key = try ensureKey()
        
        // Decrypt the data
        return try performCrypt(
            CCOperation(kCCDecrypt),
            data: data,
            key: key,
            iv: iv
        )
    }
}

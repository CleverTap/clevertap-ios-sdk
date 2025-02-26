import Foundation
import CryptoKit
import Security

@available(iOSApplicationExtension 13.0, *)
@objc class NetworkEncryptionManager: NSObject {
    
    // TODO: Check if we can use actor or something else
    @objc nonisolated(unsafe) static let shared = NetworkEncryptionManager()
    private override init() {}
    
    private var sessionKey: SymmetricKey?
    
    private func getOrGenerateSessionKey() -> SymmetricKey {
        if let key = sessionKey {
            return key
        }
        
        let newKey = SymmetricKey(size: .bits256)
        sessionKey = newKey
        return newKey
    }
    
    @objc func getEncryptedSessionKey(withBase64PublicKey base64Key: String) -> String? {
        // Step 1: Decode the Base64 public key
        guard let keyData = Data(base64Encoded: base64Key) else {
            print("Invalid Base64 public key")
            return nil
        }

        // Step 2: Create SecKey from public key data
        guard let publicKey = createSecKey(from: keyData) else {
            print("Failed to create SecKey from public key data")
            return nil
        }

        // Step 3: Convert SymmetricKey to Data
        let symmetricKeyData = getOrGenerateSessionKey().withUnsafeBytes { Data($0) }

        // Step 4: Encrypt Symmetric Key using RSA-OAEP with SHA-256
        var error: Unmanaged<CFError>?
        guard let encryptedData = SecKeyCreateEncryptedData(
            publicKey,
            SecKeyAlgorithm.rsaEncryptionOAEPSHA256,
            symmetricKeyData as CFData,
            &error
        ) as Data? else {
            print("Encryption failed: \(error!.takeRetainedValue() as Error)")
            return nil
        }

        // Step 5: Return encrypted key as Base64 string
        return encryptedData.base64EncodedString()
    }

    // Helper Method: Convert DER-encoded public key to SecKey
    private func createSecKey(from keyData: Data) -> SecKey? {
        let options: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 2048
        ]
        
        return SecKeyCreateWithData(keyData as CFData, options as CFDictionary, nil)
    }
    
    @objc func encrypt(object: Any) -> [String: Any] {
        do {
            guard JSONSerialization.isValidJSONObject(object),
                  let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
                return [:]
            }
            
            let nonce = AES.GCM.Nonce()
            let nonceData = Data(nonce)
            let sealedBox = try AES.GCM.seal(data, using: getOrGenerateSessionKey(), nonce: nonce)
            
            
            // Combine Ciphertext + Tag (this is what Java expects)
            let combinedData = sealedBox.ciphertext + sealedBox.tag
            let encodedPayload = combinedData.base64EncodedString()
            
            print("🔹 Ciphertext Length: \(sealedBox.ciphertext.count) bytes")
            print("🔹 Tag Length: \(sealedBox.tag.count) bytes") // Should be 16 bytes
            
            return ["encodedPayload": encodedPayload, "nonceData": nonceData]
            // Send this to the server
        }
        catch {
            return [:]
        }
    }
    
    @objc func decrypt(responseData: Data) -> Data {
        guard let response = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
            JSONSerialization.isValidJSONObject(response),
              let nonce = response["iv"] as? String,
              let nonceData = Data(base64Encoded: nonce),
              let encryptedPayload = response["encryptedPayload"] as? String,
              let encryptedData = Data(base64Encoded: encryptedPayload)
        else {
            return Data()
        }
        do {
            let sealedBox = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: nonceData),
                                                  ciphertext: encryptedData.dropLast(16), // Excluding the tag
                                                  tag: encryptedData.suffix(16)) // Last 16 bytes are the authentication tag
            
            let decryptedData = try AES.GCM.open(sealedBox, using: getOrGenerateSessionKey())
            return decryptedData
        } catch {
            //TODO: Add logging
            print("Decryption error: \(error)")
            return Data()
        }
    }
}

import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif
import Security

@objc public class NetworkEncryptionManager: NSObject {
    
    @objc public static let shared = NetworkEncryptionManager()
    @objc public static let ITP = "itp"
    @objc public static let ITK = "itk"
    @objc public static let ITV = "itv"
    private override init() {}
    
    private let keyQueue = DispatchQueue(label: "com.clevertap.NetworkEncryptionManager.keyqueue")
    
    private var sessionKey: Any?
    
    @available(iOS 13.0, tvOS 13.0, *)
    func getOrGenerateSessionKey() -> SymmetricKey {
        return keyQueue.sync {
            if let key = sessionKey as? SymmetricKey {
                return key
            }
            
            let newKey = SymmetricKey(size: .bits256)
            NSLog("[CleverTap]: Generated new session key.")
            sessionKey = newKey
            return newKey
        }
    }
    
    @objc public func getSessionKeyBase64() -> String? {
        if #available(iOS 13.0, tvOS 13.0, *) {
            let key = getOrGenerateSessionKey()
            let keyData = key.withUnsafeBytes { Data($0) }
            return keyData.base64EncodedString()
        } else {
            NSLog("[CleverTap]: Encryption in transit is only available from iOS 13 and later.")
            return nil
        }
    }
    
    @objc public func encrypt(object: Any) -> [String: Any] {
        if #available(iOS 13.0, tvOS 13.0, *) {
            do {
                guard JSONSerialization.isValidJSONObject(object),
                      let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
                    return [:]
                }
                
                let nonce = AES.GCM.Nonce()
                let nonceData = Data(nonce).base64EncodedString()
                let sealedBox = try AES.GCM.seal(data, using: getOrGenerateSessionKey(), nonce: nonce)
                
                // Combine Ciphertext + Tag because the server expects it this way
                let combinedData = sealedBox.ciphertext + sealedBox.tag
                let encryptedPayload = combinedData.base64EncodedString()
                
                return ["encryptedPayload": encryptedPayload, "nonceData": nonceData]
            }
            catch {
                NSLog("[CleverTap]: Encryption in transit error: %@", error.localizedDescription)
                return [:]
            }
        } else {
            NSLog("[CleverTap]: Encryption in transit is only available from iOS 13 and later.")
            return [:]
        }
    }
    
    @objc public func decrypt(responseData: Data) -> Data {
        if #available(iOS 13.0, tvOS 13.0, *) {
            guard let response = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                  JSONSerialization.isValidJSONObject(response),
                  let nonce = response[NetworkEncryptionManager.ITV] as? String,
                  let nonceData = Data(base64Encoded: nonce),
                  let encryptedPayload = response[NetworkEncryptionManager.ITP] as? String,
                  let encryptedData = Data(base64Encoded: encryptedPayload)
            else {
                return Data()
            }
            do {
                NSLog("[CleverTap]: Encrypted Response: %@", response)
                let sealedBox = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: nonceData),
                                                      ciphertext: encryptedData.dropLast(16), // Excluding the tag
                                                      tag: encryptedData.suffix(16)) // Last 16 bytes are the authentication tag
                
                let decryptedData = try AES.GCM.open(sealedBox, using: getOrGenerateSessionKey())
                return decryptedData
            } catch {
                NSLog("[CleverTap]: Decryption in transit error: %@", error.localizedDescription)
                return Data()
            }
        } else {
            NSLog("[CleverTap]: Encryption in transit is only available from iOS 13 and later.")
            return Data()
        }
    }
}

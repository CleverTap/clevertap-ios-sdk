import Foundation
import CryptoKit
import Security

@available(iOSApplicationExtension 13.0, *)

@objc class NetworkEncryptionManager: NSObject {
    
    @objc static let shared = NetworkEncryptionManager()
    @objc static let ITP = "itp"
    @objc static let ITK = "itk"
    @objc static let ITV = "itv"
    private override init() {}
    
    private let keyQueue = DispatchQueue(label: "com.clevertap.NetworkEncryptionManager.keyqueue")
    private var sessionKey: SymmetricKey?
    
    private func getOrGenerateSessionKey() -> SymmetricKey {
        return keyQueue.sync {
            if let key = sessionKey {
                return key
            }
            
            let newKey = SymmetricKey(size: .bits256)
            NSLog("[CleverTap]: Generated new session key.")
            sessionKey = newKey
            return newKey
        }
    }
    
    @objc func getSessionKeyBase64() -> String? {
        let key = getOrGenerateSessionKey()
        let keyData = key.withUnsafeBytes { Data($0) }
        return keyData.base64EncodedString()
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
            
            return ["encodedPayload": encodedPayload, "nonceData": nonceData]
        }
        catch {
            NSLog("Encryption in transit error", error.localizedDescription)
            return [:]
        }
    }
    
    @objc func decrypt(responseData: Data) -> Data {
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
            let sealedBox = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: nonceData),
                                                  ciphertext: encryptedData.dropLast(16), // Excluding the tag
                                                  tag: encryptedData.suffix(16)) // Last 16 bytes are the authentication tag
            
            let decryptedData = try AES.GCM.open(sealedBox, using: getOrGenerateSessionKey())
            return decryptedData
        } catch {
            NSLog("Decryption in transit error", error.localizedDescription)
            return Data()
        }
    }
}

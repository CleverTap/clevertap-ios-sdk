import Foundation
import CryptoKit

@available(iOS 13, *)
@objc class CTEncryptor: NSObject {
    @objc func encrypt(secret: String, nonceString: String) -> String {
        do {
            let plain = "This is a random text to be encrypted"
            let nonce = try AES.GCM.Nonce(data: Data(base64Encoded: nonceString)!)
            let symKey = SymmetricKey(data: secret.data(using: .utf8)!)

            let sealedBox = try AES.GCM.seal(plain.data(using: .utf8)!, using: symKey, nonce: nonce)
            let encryptedData = sealedBox.ciphertext + sealedBox.tag
            let encryptedDataBase64 = encryptedData.base64EncodedString()

            print("Encrypted String: \(encryptedDataBase64)")
            return encryptedDataBase64
        } catch {
            print("Encryption error: \(error)")
            return ""
        }
    }
    
    @objc func decrypt(ciphertext: String, secret: String, nonceString: String) {
        do {
            let nonce = try AES.GCM.Nonce(data: Data(base64Encoded: nonceString)!)
            let symKey = SymmetricKey(data: secret.data(using: .utf8)!)

            let ciphertextData = Data(base64Encoded: ciphertext)!
            let tagData = ciphertextData.suffix(16)

            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertextData.prefix(ciphertextData.count - 16), tag: tagData)
            let decryptedData = try AES.GCM.open(sealedBox, using: symKey)

            if let decryptedString = String(data: decryptedData, encoding: .utf8) {
                print("Decrypted Text: \(decryptedString)")
            } else {
                print("Failed to convert decrypted data to string.")
            }
        } catch {
            print("Decryption error: \(error)")
        }
    }
    
    @objc func generateRandomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    @objc func performEncryptionDecryption() {
        let passphrase = generateRandomString(length: 32)
        let nonceKey = passphrase.data(using: .utf8)?.base64EncodedString() ?? ""

        let encryptedData = encrypt(secret: passphrase, nonceString: nonceKey)
        decrypt(ciphertext: encryptedData, secret: passphrase, nonceString: nonceKey)
    }
}

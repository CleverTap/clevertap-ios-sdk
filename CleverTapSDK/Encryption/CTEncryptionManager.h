#import <Foundation/Foundation.h>
#import "CleverTap.h"

/**
 * @enum CleverTapEncryptionAlgorithm
 *
 * @abstract
 * Specifies the encryption algorithm to be used for data encryption.
 *
 * @constant PlainText
 * No encryption. Data is stored in plain text.
 *
 * @constant AES
 * Legacy AES encryption mode.
 *
 * @constant AES_GCM
 * AES-GCM (Galois/Counter Mode) encryption providing both confidentiality and authenticity.
 */
typedef NS_ENUM(int, CleverTapEncryptionAlgorithm) {
    AES = 1,        ///< AES encryption mode
    AES_GCM = 2     ///< AES-GCM encryption mode
};

NS_ASSUME_NONNULL_BEGIN
/**
 * @class CTEncryptionManager
 *
 * @brief Handles encryption and decryption operations for CleverTap data.
 */
@interface CTEncryptionManager : NSObject <NSSecureCoding>

/**
 * Initializes the encryption manager with an account ID.
 *
 * @param accountID The account identifier.
 * @return An instance of CTEncryptionManager.
 */
- (instancetype)initWithAccountID:(NSString * _Nonnull)accountID;

/**
 * Initializes the encryption manager with an account ID, encryption level, and instance type.
 *
 * @param accountID The account identifier.
 * @param encryptionLevel The encryption level to be used.
 * @param isDefaultInstance Indicates if this is the default instance.
 * @return An instance of CTEncryptionManager.
 */
- (instancetype)initWithAccountID:(NSString * _Nonnull)accountID
                 encryptionLevel:(CleverTapEncryptionLevel)encryptionLevel
             isDefaultInstance:(BOOL)isDefaultInstance;

/**
 * Initializes the encryption manager with an account ID, encryption level, and instance type.
 *
 * @param accountID The account identifier.
 * @param encryptionLevel The encryption level to be used.
 * @return An instance of CTEncryptionManager.
 */
- (instancetype)initWithAccountID:(NSString * _Nonnull)accountID
                  encryptionLevel:(CleverTapEncryptionLevel)encryptionLevel;

/**
 * Encrypts a given string using the default AES128 encryption.
 *
 * @param plaintext The string to be encrypted.
 * @return The encrypted string.
 */
- (NSString *)encryptString:(NSString *)plaintext;

/**
 * Decrypts an AES128 encrypted string.
 *
 * @param ciphertext The encrypted string.
 * @return The decrypted string.
 */
- (NSString *)decryptString:(NSString *)ciphertext;

/**
 * Decrypts a string using a specified encryption algorithm.
 *
 * @param ciphertext The encrypted string.
 * @param algorithm The encryption algorithm used for encryption.
 * @return The decrypted string.
 */
- (NSString *)decryptString:(NSString *)ciphertext encryptionAlgorithm:(CleverTapEncryptionAlgorithm)algorithm;

/**
 * Encrypts an object and returns the encrypted representation.
 *
 * @param object The object to be encrypted.
 * @return The encrypted string representation of the object.
 */
- (NSString *)encryptObject:(id)object;

/**
 * Decrypts an encrypted object string and returns the original object.
 *
 * @param ciphertext The encrypted object string.
 * @return The decrypted object.
 */
- (id)decryptObject:(NSString *)ciphertext;

/**
 * Decrypts an encrypted object string using a specified encryption algorithm.
 *
 * @param ciphertext The encrypted object string.
 * @param algorithm The encryption algorithm used for encryption.
 * @return The decrypted object.
 */
- (id)decryptObject:(NSString *)ciphertext encryptionAlgorithm:(CleverTapEncryptionAlgorithm)algorithm;

/**
 * Checks if the given text is encrypted using AES-GCM.
 *
 * @param encryptedText The text to be checked.
 * @return YES if the text is AES-GCM encrypted, NO otherwise.
 */
- (BOOL)isTextAESGCMEncrypted:(NSString *)encryptedText;

@end

NS_ASSUME_NONNULL_END

#import <Foundation/Foundation.h>
#import "CleverTap.h"

@interface CTEncryptionManager : NSObject <NSSecureCoding>

- (instancetype)initWithAccountID:(NSString *)accountID;

- (instancetype)initWithAccountID:(NSString *)accountID encryptionLevel:(CleverTapEncryptionLevel)encryptionLevel isDefaultInstance:(BOOL)isDefaultInstance;

/**
 * Returns AES128 encrypted string using the crypto framework.
 */
- (NSString *)encryptString:(NSString *)plaintext;
- (NSString *)encryptString:(NSString *)plaintext encryptionAlgorithm:(CleverTapEncryptionAlgorithm)algorithm;

/**
 * Returns AES128 decrypted string using the crypto framework.
 */
- (NSString *)decryptString:(NSString *)ciphertext;
- (NSString *)decryptString:(NSString *)ciphertext encryptionAlgorithm:(CleverTapEncryptionAlgorithm)algorithm;

- (NSString *)encryptObject:(id)object;
- (NSString *)encryptObject:(id)object encryptionAlgorithm:(CleverTapEncryptionAlgorithm)algorithm;

- (id)decryptObject:(NSString *)ciphertext;
- (id)decryptObject:(NSString *)ciphertext encryptionAlgorithm:(CleverTapEncryptionAlgorithm)algorithm;

- (BOOL)isTextAESGCMEncrypted:(NSString *)encryptedText;

@end

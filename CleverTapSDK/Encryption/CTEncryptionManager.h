#import <Foundation/Foundation.h>
#import "CleverTap.h"

@interface CTEncryptionManager : NSObject <NSSecureCoding>

- (instancetype)initWithAccountID:(NSString *)accountID;

- (instancetype)initWithAccountID:(NSString *)accountID encryptionLevel:(CleverTapEncryptionLevel)encryptionLevel isDefaultInstance:(BOOL)isDefaultInstance;

/**
 * Returns AES128 encrypted string using the crypto framework.
 */
- (NSString *)encryptString:(NSString *)plaintext;

/**
 * Returns AES128 encrypted string using the crypto framework.
 */
- (NSString *)encryptStringWithAESGCM:(NSString *)plaintext;
- (NSString *)encryptObjectWithAESGCM:(id)object;
/**
 * Returns AES128 decrypted string using the crypto framework.
 */
- (NSString *)decryptString:(NSString *)ciphertext;

- (NSString *)decryptStringWithAESGCM:(NSString *)ciphertext;
- (id)decryptObjectWithAESGCM:(NSString *)ciphertext;

- (NSString *)encryptObject:(id)object;

- (id)decryptObject:(NSString *)ciphertext;

@end

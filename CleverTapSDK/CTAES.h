#import <Foundation/Foundation.h>
#import "CleverTap.h"

@interface CTAES : NSObject

/**
 * Returns AES128 encrypted string using the crypto framework.
 */
- (NSString *)getEncryptedString:(NSString *)identifier;

/**
 * Returns AES128 decrypted string using the crypto framework.
 */
- (NSString *)getDecryptedString:(NSString *)identifier;

- (instancetype)initWithAccountID:(NSString *)accountID encryptionLevel:(CleverTapEncryptionLevel)encryptionLevel isDefaultInstance:(BOOL)isDefaultInstance;

- (NSString *)getEncryptedBase64String:(id)objectToEncrypt;

- (instancetype)initWithAccountID:(NSString *)accountID;

@end

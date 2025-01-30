//
//  EncryptionBridge.h
//  Pods
//
//  Created by Kushagra Mishra on 29/01/25.
//
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTEncryptor : NSObject

// Key Management
+ (BOOL)generateKeyWithError:(NSError **)error;
+ (BOOL)deleteKeyWithError:(NSError **)error;

// Encryption/Decryption
+ (NSString * _Nullable)performCryptOperation:(NSString *)string error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

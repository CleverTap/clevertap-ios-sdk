//
//  CTAESCrypt.h
//  CleverTapSDK
//
//  Created by Kushagra Mishra on 04/02/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTAESCrypt : NSObject

/**
 * Performs AES-128 encryption/decryption operation
 *
 * @param operation The operation to perform (encryption or decryption)
 * @param key The encryption/decryption key
 * @param identifier The initialization vector
 * @param data The data to encrypt/decrypt
 * @return The processed data, or nil if operation fails
 */
- (nullable NSData *)AES128WithOperation:(CCOperation)operation
                                   key:(NSString *)key
                            identifier:(NSString *)identifier
                                  data:(NSData *)data;

- (NSString *)generateKeyPassword;

@end

NS_ASSUME_NONNULL_END

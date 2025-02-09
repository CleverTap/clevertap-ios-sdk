//
//  CTCryptHandler.h
//  CleverTapSDK
//
//  Created by Kushagra Mishra on 07/02/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "CleverTap.h"

@interface CTCryptHandler : NSObject <NSSecureCoding>

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

- (id)getDecryptedObject:(NSString *)encryptedString;

- (instancetype)initWithAccountID:(NSString *)accountID;

@end

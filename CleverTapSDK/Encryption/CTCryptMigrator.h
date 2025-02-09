//
//  CTCryptMigrator.h
//  CleverTapSDK
//
//  Created by Kushagra Mishra on 07/02/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTCryptMigrator : NSObject

- (instancetype)initWithAccountID:(NSString *)accountID isDefaultInstance:(BOOL)isDefaultInstance;

- (instancetype)initWithAccountID:(NSString *)accountID;

- (NSString *)generateKeyPassword;

@end

NS_ASSUME_NONNULL_END

//
//  CTCryptMigrator.m
//  CleverTapSDK
//
//  Created by Kushagra Mishra on 07/02/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//
#import "CTCryptMigrator.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTUtils.h"
#import "CTAESCrypt.h"

NSString *const kCRYPT_KEY_PREFIX = @"Lq3fz";
NSString *const kCRYPT_KEY_SUFFIX = @"bLti2";

@interface CTCryptMigrator () {}
@property (nonatomic, strong) NSString *accountID;
@property (nonatomic, assign) CleverTapEncryptionLevel encryptionLevel;
@property (nonatomic, assign) BOOL isDefaultInstance;
@end

@implementation CTCryptMigrator

- (instancetype)initWithAccountID:(NSString *)accountID
                isDefaultInstance:(BOOL)isDefaultInstance {
    if (self = [super init]) {
        _accountID = accountID;
        _isDefaultInstance = isDefaultInstance;
    }
    return self;
}

- (instancetype)initWithAccountID:(NSString *)accountID {
    if (self = [super init]) {
        _accountID = accountID;
    }
    return self;
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    if (self = [super init]) {
        _accountID = [coder decodeObjectForKey:@"accountID"];
        _isDefaultInstance = [coder decodeBoolForKey:@"isDefaultInstance"];
        _encryptionLevel = [coder decodeIntForKey:@"encryptionLevel"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject: _accountID forKey:@"accountID"];
    [coder encodeBool: _isDefaultInstance forKey:@"isDefaultInstance"];
    [coder encodeInt: _encryptionLevel forKey:@"encryptionLevel"];
}

+ (BOOL)supportsSecureCoding {
   return YES;
}

- (NSString *)generateKeyPassword {
    NSString *keyPassword = [NSString stringWithFormat:@"%@%@%@",kCRYPT_KEY_PREFIX, _accountID, kCRYPT_KEY_SUFFIX];
    return keyPassword;
}

@end

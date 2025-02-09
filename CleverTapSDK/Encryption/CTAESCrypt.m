//
//  CTAESCrypt.m
//  CleverTapSDK
//
//  Created by Kushagra Mishra on 07/02/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import "CTAESCrypt.h"
#import "CTConstants.h"

NSString *const kCRYPT_KEY_PREFIX = @"Lq3fz";
NSString *const kCRYPT_KEY_SUFFIX = @"bLti2";

@interface CTAESCrypt () {}
@property (nonatomic, strong) NSString *accountID;
@end

@implementation CTAESCrypt

- (nullable NSData *)AES128WithOperation:(CCOperation)operation
                               accountID:(NSString *)accountID
                                    data:(NSData *)data {
    // Note: The key will be 0's but we intentionally are keeping it this way to maintain
    // compatibility. The correct code is:
    // char keyPtr[[key length] + 1];
    char keyCString[kCCKeySizeAES128 + 1];
    memset(keyCString, 0, sizeof(keyCString));
    //The encryption/decryption key
    NSString *key = [self generateKeyPassword];
    [key getCString:keyCString maxLength:sizeof(keyCString) encoding:NSUTF8StringEncoding];
    
    char identifierCString[kCCBlockSizeAES128 + 1];
    memset(identifierCString, 0, sizeof(identifierCString));
    //The initialization vector
    NSString *iv = CLTAP_ENCRYPTION_IV;
    [iv getCString:identifierCString
                 maxLength:sizeof(identifierCString)
                  encoding:NSUTF8StringEncoding];
    
    size_t outputAvailableSize = [data length] + kCCBlockSizeAES128;
    void *output = malloc(outputAvailableSize);
    
    size_t outputMovedSize = 0;
    CCCryptorStatus cryptStatus = CCCrypt(operation,
                                        kCCAlgorithmAES128,
                                        kCCOptionPKCS7Padding,
                                        keyCString,
                                        kCCBlockSizeAES128,
                                        identifierCString,
                                        [data bytes],
                                        [data length],
                                        output,
                                        outputAvailableSize,
                                        &outputMovedSize);
    
    if (cryptStatus != kCCSuccess) {
        CleverTapLogStaticInternal(@"Failed to encode/deocde the string with error code: %d", cryptStatus);
        free(output);
        return nil;
    }
    
    return [NSData dataWithBytesNoCopy:output length:outputMovedSize];
}

- (NSString *)generateKeyPassword {
    NSString *keyPassword = [NSString stringWithFormat:@"%@%@%@",kCRYPT_KEY_PREFIX, _accountID, kCRYPT_KEY_SUFFIX];
    return keyPassword;
}

@end

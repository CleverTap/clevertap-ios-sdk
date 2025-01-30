//
//  AESCrypt.m
//  Pods
//
//  Created by Kushagra Mishra on 29/01/25.
//
#import "AESCrypt.h"

@implementation AESCrypt : NSObject

+ (NSData *)AES128WithOperation:(CCOperation)operation
                            key:(NSString *)key
                     identifier:(NSString *)identifier
                           data:(NSData *)data {
    // Note: The key will be 0's but we intentionally are keeping it this way to maintain
    // compatibility. The correct code is:
    // char keyPtr[[key length] + 1];
    char keyCString[kCCKeySizeAES128 + 1];
    memset(keyCString, 0, sizeof(keyCString));
    [key getCString:keyCString maxLength:sizeof(keyCString) encoding:NSUTF8StringEncoding];

    char identifierCString[kCCBlockSizeAES128 + 1];
    memset(identifierCString, 0, sizeof(identifierCString));
    [identifier getCString:identifierCString
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
        NSLog(@"Failed to encode/decode the string with error code: %d", cryptStatus);
        free(output);
        return nil;
    }

    return [NSData dataWithBytesNoCopy:output length:outputMovedSize];
}

@end

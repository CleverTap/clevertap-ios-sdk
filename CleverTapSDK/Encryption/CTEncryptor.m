// EncryptionBridge.m
#import "CTEncryptor.h"
#import "AESCrypt.h"
#if __has_include(<CleverTapSDK/CleverTapSDK-Swift.h>)
#import <CleverTapSDK/CleverTapSDK-Swift.h>
#else
#import "CleverTapSDK-Swift.h"
#endif

@implementation CTEncryptor

+ (BOOL)generateKeyWithError:(NSError **)error {
    @try {
        return [CTKeychainManager getOrGenerateKeyAndReturnError:error];
    } @catch (NSError *caughtError) {
        if (error) {
            *error = caughtError;
        }
        return NO;
    }
}

+ (BOOL)deleteKeyWithError:(NSError **)error {
    @try {
        return [CTKeychainManager deleteKeyAndReturnError:error];
    } @catch (NSError *caughtError) {
        if (error) {
            *error = caughtError;
        }
        return NO;
    }
}


+ (NSData * _Nullable)performCryptOperation:(NSData *)data error:(NSError **)error {
    @try {
        if (@available(iOS 13, *)) {
            AESGCMCrypt *aesgcmcryptor = [[AESGCMCrypt alloc] init];
            NSError *error = nil;

            // For encryption (mode = YES)
            AESGCMCryptResult *result = [aesgcmcryptor performCryptOperationWithMode:YES
                                                                               data:data
                                                                                 iv:nil
                                                                              error:&error];
            if (error) {
                NSLog(@"Encryption failed: %@", error.localizedDescription);
                return nil;
            }

            // For decryption (mode = NO)
            AESGCMCryptResult *decryptResult = [aesgcmcryptor performCryptOperationWithMode:NO
                                                                                      data:result.data
                                                                                        iv:result.iv
                                                                                     error:&error];
            if (error) {
                NSLog(@"Decryption failed: %@", error.localizedDescription);
                return nil;
            }
            
            return result.data;
        } else {
            // Handle earlier iOS versions if needed
//            NSData *outputData = [AESCrypt AES128WithOperation:kCCEncrypt
//                                                           key:[self generateKeyPassword]
//                                                    identifier:CLTAP_ENCRYPTION_IV
//                                                          data:data];
        }
    } @catch (NSError *caughtError) {
        if (error) {
            *error = caughtError;
        }
        return nil;
    }
    return nil;
}




@end

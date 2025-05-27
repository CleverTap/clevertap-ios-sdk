#import "CTEncryptionManager.h"
#import <CommonCrypto/CommonCryptor.h>
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTUtils.h"
#if __has_include(<CleverTapSDK/CleverTapSDK-Swift.h>)
#import <CleverTapSDK/CleverTapSDK-Swift.h>
#else
#import "CleverTapSDK-Swift.h"
#endif

static NSString *const kCRYPT_KEY_PREFIX = @"Lq3fz";
static NSString *const kCRYPT_KEY_SUFFIX = @"bLti2";

API_AVAILABLE(ios(13.0))
@interface CTEncryptionManager () {}
@property (nonatomic, strong) NSString *accountID;
@property (nonatomic, assign) CleverTapEncryptionLevel encryptionLevel;
@property (nonatomic, assign) BOOL isDefaultInstance;
@property (nonatomic, strong) CTAESGCMCrypt *ctaesgcm;
@end

@implementation CTEncryptionManager

#pragma mark - Initialization & Coding

- (instancetype)initWithAccountID:(NSString * _Nonnull)accountID
                  encryptionLevel:(CleverTapEncryptionLevel)encryptionLevel
                isDefaultInstance:(BOOL)isDefaultInstance {
    if (self = [super init]) {
        _accountID = accountID;
        _isDefaultInstance = isDefaultInstance;
        [self setupEncryptionWithLevel];
        [self updateEncryptionLevel:encryptionLevel];
    }
    return self;
}

- (instancetype)initWithAccountID:(NSString * _Nonnull)accountID {
    if (self = [super init]) {
        _accountID = accountID;
        [self setupEncryptionWithLevel];
    }
    return self;
}

- (instancetype)initWithAccountID:(NSString * _Nonnull)accountID encryptionLevel:(CleverTapEncryptionLevel)encryptionLevel {
    if (self = [super init]) {
        _accountID = accountID;
        _encryptionLevel = encryptionLevel;
        [self setupEncryptionWithLevel];
    }
    return self;
}

- (void)setupEncryptionWithLevel {
    if (@available(iOS 13.0, tvOS 13.0, *)) {
        _ctaesgcm = [[CTAESGCMCrypt alloc] initWithKeychainTag:ENCRYPTION_KEY_TAG];
    }
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

#pragma mark - Public Methods

- (void)updateEncryptionLevel:(CleverTapEncryptionLevel)encryptionLevel {
    _encryptionLevel = encryptionLevel;
    NSString *encryptionKey = [CTUtils getKeyWithSuffix:kENCRYPTION_KEY accountID:_accountID];
    long lastEncryptionLevel = [CTPreferences getIntForKey:encryptionKey withResetValue:0];
    if (lastEncryptionLevel != _encryptionLevel) {
        CleverTapLogStaticInternal(@"CleverTap Encryption level changed for account: %@ to: %d", _accountID, _encryptionLevel);
        [self updateCachedGUIDS];
        if (!_isDefaultInstance) {
            // For Default instance, we are updating this after updating Local DB values on App Launch.
            [CTPreferences putInt:_encryptionLevel forKey:encryptionKey];
        }
    }
}

#pragma mark - String Encryption

- (NSString *)encryptString:(NSString *)plaintext {
    return [self encryptString:plaintext
           encryptionAlgorithm:AES_GCM];
}

- (NSString *)encryptString:(NSString *)plaintext encryptionAlgorithm:(CleverTapEncryptionAlgorithm)algorithm {
    if (!plaintext || plaintext.length == 0) {
        return plaintext; // Return as is for empty or nil input
    }

    if (_encryptionLevel == CleverTapEncryptionNone) {
        return plaintext;
    }
    
    switch (algorithm) {
        case AES_GCM: {
            if (@available(iOS 13.0, tvOS 13.0, *)) {
                NSError *encryptError = nil;
                NSString *encryptedString = [_ctaesgcm encryptString:plaintext error:&encryptError];

                if (encryptError) {
                    CleverTapLogStaticInternal(@"AES-GCM Encryption failed: %@", encryptError.localizedDescription ?: @"Unknown error");
                    return plaintext;
                }
                return encryptedString;
            }
            
            // Fallback to AES if iOS < 13
            CleverTapLogStaticInternal(@"AES-GCM not supported, falling back to AES encryption.");
            // Intentional fallthrough to AES case
        }
        case AES: {
            @try {
                NSData *data = [plaintext dataUsingEncoding:NSUTF8StringEncoding];
                NSData *encryptedData = [self processData:data operation:kCCEncrypt];
                return encryptedData ? [encryptedData base64EncodedStringWithOptions:0] : plaintext;
            } @catch (NSException *exception) {
                CleverTapLogStaticInternal(@"AES Encryption error: %@", exception.debugDescription);
                return plaintext;
            }
        }
        default:
            CleverTapLogStaticInternal(@"Unsupported encryption algorithm: %ld", (long)algorithm);
            return plaintext;
    }
}

- (NSString *)decryptString:(NSString *)ciphertext {
    return [self decryptString:ciphertext
           encryptionAlgorithm:AES_GCM];
}

- (NSString *)decryptString:(NSString *)ciphertext encryptionAlgorithm:(CleverTapEncryptionAlgorithm)algorithm {
    if (!ciphertext || ciphertext.length == 0) {
        return ciphertext; // Return as is for empty or nil input
    }

    switch (algorithm) {
        case AES_GCM: {
            if (@available(iOS 13.0, tvOS 13.0, *)) {
                NSError *decryptError = nil;
                NSString *decryptedString = [_ctaesgcm decryptString:ciphertext error:&decryptError];

                if (decryptError) {
                    CleverTapLogStaticInternal(@"AES-GCM Decryption failed: %@", decryptError.localizedDescription ?: @"Unknown error");
                    return ciphertext;
                }
                return decryptedString;
            }

            // Fallback to AES if iOS < 13
            CleverTapLogStaticInternal(@"AES-GCM not supported, falling back to AES decryption.");
            // Intentional fallthrough to AES case
        }
        case AES: {
            @try {
                NSData *data = [[NSData alloc] initWithBase64EncodedString:ciphertext options:0];
                NSData *decryptedData = [self processData:data operation:kCCDecrypt];
                NSString *decryptedString = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
                return decryptedString ? decryptedString : nil;
            } @catch (NSException *exception) {
                CleverTapLogStaticInternal(@"AES Decryption error: %@", exception.debugDescription);
                return nil;
            }
        }
        default:
            CleverTapLogStaticInternal(@"Unsupported decryption algorithm: %ld", (long)algorithm);
            return ciphertext;
    }
}

#pragma mark - Object Encryption

- (NSString *)encryptObject:(id)object {
    return [self encryptObject:object encryptionAlgorithm:AES_GCM];
}

- (NSString *)encryptObject:(id)object encryptionAlgorithm:(CleverTapEncryptionAlgorithm)algorithm {
    if (!object) {
        return nil; // Return nil for a null object
    }
    
    @try {
        NSData *data;
                
        if (@available(iOS 11.0, tvOS 11.0, *)) {
            NSError *archiveError = nil;
            data = [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:NO error:&archiveError];
            
            if (!data || archiveError) {
                CleverTapLogStaticInternal(@"Failed to serialize object for encryption: %@", archiveError);
                return nil;
            }
        } else {
            // Fallback for iOS/tvOS versions below 11.0
            data = [NSKeyedArchiver archivedDataWithRootObject:object];
            
            if (!data) {
                CleverTapLogStaticInternal(@"Failed to serialize object for encryption.");
                return nil;
            }
        }

        switch (algorithm) {
            case AES_GCM: {
                if (@available(iOS 13.0, tvOS 13.0, *)) {
                    NSError *encryptError = nil;
                    NSString *encryptedString = [_ctaesgcm encryptData:data error:&encryptError];

                    if (encryptError) {
                        CleverTapLogStaticInternal(@"AES-GCM Encryption failed: %@", encryptError.localizedDescription ?: @"Unknown error");
                        return nil;
                    }
                    return encryptedString;
                }

                // Fallback to AES if iOS < 13
                CleverTapLogStaticInternal(@"AES-GCM not supported, falling back to AES encryption.");
                // Intentional fallthrough to AES case
            }
            case AES: {
                NSData *encryptedData = [self processData:data operation:kCCEncrypt];
                return encryptedData ? [encryptedData base64EncodedStringWithOptions:0] : nil;
            }
            default:
                CleverTapLogStaticInternal(@"Unsupported encryption algorithm: %ld", (long)algorithm);
                return nil;
        }
    } @catch (NSException *exception) {
        CleverTapLogStaticInternal(@"Object encryption error: %@", exception.debugDescription);
        return nil;
    }
}


- (id)decryptObject:(NSString *)ciphertext {
    return [self decryptObject:ciphertext encryptionAlgorithm:AES_GCM];
}

- (id)decryptObject:(NSString *)ciphertext encryptionAlgorithm:(CleverTapEncryptionAlgorithm)algorithm {
    if (!ciphertext) {
        return nil; // Return nil if ciphertext is null
    }

    @try {
        switch (algorithm) {
            case AES_GCM: {
                if (@available(iOS 13.0, tvOS 13.0, *)) {
                    NSError *decryptError = nil;
                    NSData *decryptedData = [_ctaesgcm decryptData:ciphertext error:&decryptError];

                    if (decryptError) {
                        CleverTapLogStaticInternal(@"AES-GCM Decryption failed: %@", decryptError.localizedDescription ?: @"Unknown error");
                        return nil;
                    }
                    
                    if (decryptedData) {
                        if (@available(iOS 11.0, tvOS 11.0, *)) {
                            NSError *unarchiveError = nil;
                            id unarchived = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[NSArray.class, NSDictionary.class, NSString.class, NSNumber.class, NSData.class, NSDate.class, NSNull.class]] fromData:decryptedData error:&unarchiveError];
                            
                            if (unarchiveError) {
                                CleverTapLogStaticInternal(@"Unarchiving failed: %@", unarchiveError);
                                return nil;
                            }
                            return unarchived;
                        } else {
                            // Fallback for iOS/tvOS versions below 11.0
                            return [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
                        }
                    }
                    return nil;
                }

                // Fallback to AES if iOS < 13
                CleverTapLogStaticInternal(@"AES-GCM not supported, falling back to AES decryption.");
                // Intentional fallthrough to AES case
            }
            case AES: {
                NSData *data = [[NSData alloc] initWithBase64EncodedString:ciphertext options:0];
                NSData *decryptedData = [self processData:data operation:kCCDecrypt];
                
                if (decryptedData) {
                    if (@available(iOS 11.0, tvOS 11.0, *)) {
                        NSError *unarchiveError = nil;
                        id unarchived = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[NSArray.class, NSDictionary.class, NSString.class, NSNumber.class, NSData.class, NSDate.class, NSNull.class]] fromData:decryptedData error:&unarchiveError];
                        
                        if (unarchiveError) {
                            CleverTapLogStaticInternal(@"Unarchiving failed: %@", unarchiveError);
                            return nil;
                        }
                        return unarchived;
                    } else {
                        // Fallback for iOS/tvOS versions below 11.0
                        return [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
                    }
                }
                return nil;
            }
            default:
                CleverTapLogStaticInternal(@"Unsupported decryption algorithm: %ld", (long)algorithm);
                return nil;
        }
    } @catch (NSException *exception) {
        CleverTapLogStaticInternal(@"Object decryption error: %@", exception.debugDescription);
        return nil;
    }
}

#pragma mark - Private Methods

- (void)updateCachedGUIDS {
    NSString *cacheKey = [CTUtils getKeyWithSuffix:CLTAP_CachedGUIDSKey accountID:_accountID];
    NSDictionary *cachedGUIDS = [CTPreferences getObjectForKey:cacheKey];
    if (!cachedGUIDS) return;
    
    NSMutableDictionary *newCache = [NSMutableDictionary new];
    [cachedGUIDS enumerateKeysAndObjectsUsingBlock:^(NSString* cachedKey,
                                                    NSString* value,
                                                    BOOL* stop) {
        NSArray *components = [cachedKey componentsSeparatedByString:@"_"];
        if (components.count != 2) return;
        
        NSString *key = components[0];
        NSString *identifier = components[1];
        NSString *processedIdentifier = self->_encryptionLevel == CleverTapEncryptionMedium ?
        [self encryptString:identifier] : [self decryptString:identifier];
        
        if (processedIdentifier) {
            newCache[[NSString stringWithFormat:@"%@_%@", key, processedIdentifier]] = value;
        }
    }];
    
    [CTPreferences putObject:newCache forKey:cacheKey];
}

- (NSData *)processData:(NSData *)data operation:(CCOperation)operation {
    if (!data) return nil;
    
    NSString *key = [NSString stringWithFormat:@"%@%@%@",
                     kCRYPT_KEY_PREFIX, _accountID, kCRYPT_KEY_SUFFIX];
    
    char keyCString[kCCKeySizeAES128 + 1];
    char ivCString[kCCBlockSizeAES128 + 1];
    memset(keyCString, 0, sizeof(keyCString));
    memset(ivCString, 0, sizeof(ivCString));
    
    [key getCString:keyCString maxLength:sizeof(keyCString) encoding:NSUTF8StringEncoding];
    [CLTAP_ENCRYPTION_IV getCString:ivCString maxLength:sizeof(ivCString)
                          encoding:NSUTF8StringEncoding];
    
    size_t outputSize = data.length + kCCBlockSizeAES128;
    void *output = malloc(outputSize);
    size_t outputMovedSize = 0;
    
    CCCryptorStatus status = CCCrypt(operation,
                                    kCCAlgorithmAES128,
                                    kCCOptionPKCS7Padding,
                                    keyCString,
                                    kCCBlockSizeAES128,
                                    ivCString,
                                    data.bytes,
                                    data.length,
                                    output,
                                    outputSize,
                                    &outputMovedSize);
    
    if (status != kCCSuccess) {
        free(output);
        return nil;
    }
    
    return [NSData dataWithBytesNoCopy:output length:outputMovedSize];
}

- (BOOL)isTextAESGCMEncrypted:(NSString *)encryptedText {
    return [encryptedText hasPrefix:AES_GCM_PREFIX] && [encryptedText hasSuffix:AES_GCM_SUFFIX];
}

@end

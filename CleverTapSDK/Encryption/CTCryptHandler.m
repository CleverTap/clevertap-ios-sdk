#import "CTCryptHandler.h"
#import <CommonCrypto/CommonCryptor.h>
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTUtils.h"
#import "CTAESCrypt.h"
#if __has_include(<CleverTapSDK/CleverTapSDK-Swift.h>)
#import <CleverTapSDK/CleverTapSDK-Swift.h>
#else
#import "CleverTapSDK-Swift.h"
#endif

NSString *const kENCRYPTION_KEY = @"CLTAP_ENCRYPTION_KEY";
NSString *const kCRYPT_KEY_PREFIX = @"Lq3fz";
NSString *const kCRYPT_KEY_SUFFIX = @"bLti2";
NSString *const kCacheGUIDS = @"CachedGUIDS";

@interface CTCryptHandler () {}
@property (nonatomic, strong) NSString *accountID;
@property (nonatomic, assign) CleverTapEncryptionLevel encryptionLevel;
@property (nonatomic, assign) BOOL isDefaultInstance;
@end

@implementation CTCryptHandler

- (instancetype)initWithAccountID:(NSString *)accountID
                  encryptionLevel:(CleverTapEncryptionLevel)encryptionLevel
                isDefaultInstance:(BOOL)isDefaultInstance {
    if (self = [super init]) {
        _accountID = accountID;
        _isDefaultInstance = isDefaultInstance;
        [self updateEncryptionLevel:encryptionLevel];
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

- (void)updateEncryptionLevel:(CleverTapEncryptionLevel)encryptionLevel {
    _encryptionLevel = encryptionLevel;
    long lastEncryptionLevel = [CTPreferences getIntForKey:[CTUtils getKeyWithSuffix:kENCRYPTION_KEY accountID:_accountID] withResetValue:0];
    if (lastEncryptionLevel != _encryptionLevel) {
        CleverTapLogStaticInternal(@"CleverTap Encryption level changed for account: %@ to: %d", _accountID, _encryptionLevel);
        [self updatePreferencesValues];
        if (!_isDefaultInstance) {
            // For Default instance, we are updating this after updating Local DB values on App Launch.
            [CTPreferences putInt:_encryptionLevel forKey:[CTUtils getKeyWithSuffix:kENCRYPTION_KEY accountID:_accountID]];
        }
    }
}

- (void)updatePreferencesValues {
    NSDictionary *cachedGUIDS = [CTPreferences getObjectForKey:[CTUtils getKeyWithSuffix:kCacheGUIDS accountID:_accountID]];
    if (cachedGUIDS) {
        NSMutableDictionary *newCache = [NSMutableDictionary new];
        if (_encryptionLevel == CleverTapEncryptionNone) {
            [cachedGUIDS enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull cachedKey, NSString*  _Nonnull value, BOOL * _Nonnull stopp) {
                NSString *key = [self getCachedKey:cachedKey];
                NSString *identifier = [self getCachedIdentifier:cachedKey];
                NSString *decryptedString = [self getDecryptedString:identifier];
                NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", key, decryptedString];
                newCache[cacheKey] = value;
            }];
        } else if (_encryptionLevel == CleverTapEncryptionMedium) {
            [cachedGUIDS enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull cachedKey, NSString*  _Nonnull value, BOOL * _Nonnull stopp) {
                NSString *key = [self getCachedKey:cachedKey];
                NSString *identifier = [self getCachedIdentifier:cachedKey];
                NSString *encryptedString = [self getEncryptedString:identifier];
                NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", key, encryptedString];
                newCache[cacheKey] = value;
            }];
        }
        [CTPreferences putObject:newCache forKey:[CTUtils getKeyWithSuffix:kCacheGUIDS accountID:_accountID]];
    }
}

- (NSString *)getEncryptedString:(NSString *)identifier {
    NSString *encryptedString = identifier;
    if (_encryptionLevel == CleverTapEncryptionMedium) {
        @try {
            NSData *dataValue = [identifier dataUsingEncoding:NSUTF8StringEncoding];
            NSData *encryptedData = [self convertData:dataValue withOperation:kCCEncrypt];
            if (encryptedData) {
                encryptedString = [encryptedData base64EncodedStringWithOptions:kNilOptions];
            }
        } @catch (NSException *e) {
            CleverTapLogStaticInternal(@"Error: %@ while encrypting the string: %@", e.debugDescription, identifier);
            return identifier;
        }
    }
    return encryptedString;
}

- (NSString *)getDecryptedString:(NSString *)identifier {
    NSString *decryptedString = identifier;
    @try {
        NSData *dataValue = [[NSData alloc] initWithBase64EncodedString:identifier options:kNilOptions];
        NSData *decryptedData = [self convertData:dataValue withOperation:kCCDecrypt];
        if (decryptedData && decryptedData.length > 0) {
            NSString *utf8EncodedString = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
            if (utf8EncodedString) {
                decryptedString = utf8EncodedString;
            }
        }
    } @catch (NSException *e) {
        CleverTapLogStaticInternal(@"Error: %@ while decrypting the string: %@", e.debugDescription, identifier);
        return identifier;
    }
    return decryptedString;
}

- (NSData *)convertData:(NSData *)data
          withOperation:(CCOperation)operation {
    if (@available(iOS 13.0, *)) {
        CTEncryptionManager *encryptionManager = [[CTEncryptionManager alloc] initWithKeychainTag:@"EncryptionKey"];
        NSError *error = nil;
        NSData *processedData = nil;
        
        switch (operation) {
            case kCCEncrypt:
                processedData = [encryptionManager encryptData:data error:&error];
                break;
            case kCCDecrypt:
                processedData = [encryptionManager decryptData:data error:&error];
                break;
            default:
                NSLog(@"Unsupported operation");
                break;
        }
        
        if (error) {
            NSLog(@"Encryption/Decryption error: %@", error);
            return nil;
        }
        
        return processedData;
    } else {
        CTAESCrypt *aesCrypt = [[CTAESCrypt alloc] init];
        NSData *outputData = [aesCrypt
                            AES128WithOperation:operation
                            key:[aesCrypt generateKeyPassword]
                            identifier:CLTAP_ENCRYPTION_IV
                            data:data];
        return outputData;
    }
    return nil;
}

- (NSString *)getCachedKey:(NSString *)value {
    if ([value rangeOfString:@"_"].length > 0) {
        NSUInteger index = [value rangeOfString:@"_"].location;
        return [value substringToIndex:index];
    } else {
        return nil;
    }
}

- (NSString *)getCachedIdentifier:(NSString *)value {
    if ([value rangeOfString:@"_"].length > 0) {
        NSUInteger index = [value rangeOfString:@"_"].location;
        return [value substringFromIndex:index+1];
    } else {
        return nil;
    }
}

- (NSString *)generateKeyPassword {
    NSString *keyPassword = [NSString stringWithFormat:@"%@%@%@",kCRYPT_KEY_PREFIX, _accountID, kCRYPT_KEY_SUFFIX];
    return keyPassword;
}

- (NSString *)getEncryptedBase64String:(id)objectToEncrypt {
    @try {
        NSData *dataValue = [NSKeyedArchiver archivedDataWithRootObject:objectToEncrypt];
        NSData *encryptedData = [self convertData:dataValue withOperation:kCCEncrypt];
        if (encryptedData) {
            return [encryptedData base64EncodedStringWithOptions:kNilOptions];
        }
    } @catch (NSException *e) {
        CleverTapLogStaticInternal(@"Error: %@ while encrypting object: %@", e.debugDescription, objectToEncrypt);
        return nil;
    }
    return nil;
}

- (id)getDecryptedObject:(NSString *)encryptedString {
    if (!encryptedString) return nil;
    @try {
        NSData *dataValue = [[NSData alloc] initWithBase64EncodedString:encryptedString options:kNilOptions];
        NSData *decryptedData = [self convertData:dataValue withOperation:kCCDecrypt];
        if (decryptedData && decryptedData.length > 0) {
            return [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData];
        }
    } @catch (NSException *e) {
        CleverTapLogStaticInternal(@"Error: %@ while decrypting string: %@", e.debugDescription, encryptedString);
        return nil;
    }
    return nil;
}

@end

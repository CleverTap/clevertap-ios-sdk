#import <CommonCrypto/CommonCryptor.h>
#import "CTAES.h"
#import "CTPreferences.h"

NSString *const kENCRYPTION_KEY = @"CLTAP_ENCRYPTION_KEY";
NSString *const kCacheGUIDS = @"CachedGUIDS";

@interface CTAES () {}
@property (nonatomic, strong) NSString *accountID;
@property (nonatomic, assign) CleverTapEncryptionLevel encryptionLevel;
@end

@implementation CTAES

- (instancetype)initWithAccountID:(NSString *)accountID
                  encryptionLevel:(CleverTapEncryptionLevel)encryptionLevel {
    if (self = [super init]) {
        _accountID = accountID;
        [self updateEncryptionLevel:encryptionLevel];
    }
    return self;
}

- (void)updateEncryptionLevel:(CleverTapEncryptionLevel)encryptionLevel {
    _encryptionLevel = encryptionLevel;
    long lastEncryptionLevel = [CTPreferences getIntForKey:[self getKeyWithSuffix:kENCRYPTION_KEY accountID:_accountID] withResetValue:0];
    if (lastEncryptionLevel != _encryptionLevel) {
        [CTPreferences putInt:_encryptionLevel forKey:[self getKeyWithSuffix:kENCRYPTION_KEY accountID:_accountID]];
        [self updateValues];
    }
}

- (void)updateValues {
    NSDictionary *cachedGUIDS = [CTPreferences getObjectForKey:[self getKeyWithSuffix:kCacheGUIDS accountID:_accountID]];
    if (!cachedGUIDS) cachedGUIDS = @{};
    NSMutableDictionary *newCache = [NSMutableDictionary new];
    if (_encryptionLevel == CleverTapEncryptionOff) {
        [cachedGUIDS enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull cachedKey, NSString*  _Nonnull value, BOOL * _Nonnull stopp) {
            NSString *key = [self getCachedKey:cachedKey];
            NSString *identifier = [self getCachedIdentifier:cachedKey];
            NSString *decryptedString = [self getDecryptedString:identifier];
            NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", key, decryptedString];
            newCache[cacheKey] = value;
        }];
        [CTPreferences putObject:newCache forKey:[self getKeyWithSuffix:kCacheGUIDS accountID:_accountID]];
    } else if (_encryptionLevel == CleverTapEncryptionOn) {
        [cachedGUIDS enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull cachedKey, NSString*  _Nonnull value, BOOL * _Nonnull stopp) {
            NSString *key = [self getCachedKey:cachedKey];
            NSString *identifier = [self getCachedIdentifier:cachedKey];
            NSString *encryptedString = [self getEncryptedString:identifier];
            NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", key, encryptedString];
            newCache[cacheKey] = value;
        }];
        [CTPreferences putObject:newCache forKey:[self getKeyWithSuffix:kCacheGUIDS accountID:_accountID]];
    }
}

- (NSString *)getEncryptedString:(NSString *)identifier {
    NSString *encryptedString = identifier;
    if (_encryptionLevel == CleverTapEncryptionOn) {
        NSData *dataValue = [identifier dataUsingEncoding:NSUTF8StringEncoding];
        NSData *encryptedData = [self convertData:dataValue withOperation:kCCEncrypt];
        encryptedString = [encryptedData base64EncodedStringWithOptions:kNilOptions];
    }
    return encryptedString;
}

- (NSString *)getDecryptedString:(NSString *)identifier {
    NSData *dataValue = [[NSData alloc] initWithBase64EncodedString:identifier options:kNilOptions];
    NSData *decryptedData = [self convertData:dataValue withOperation:kCCDecrypt];
    NSString *decryptedString = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
    return decryptedString;
}

- (NSData *)convertData:(NSData *)data
          withOperation:(CCOperation)operation {
    // TODO: will update key and identifier.
    NSData *outputData = [self AES128WithOperation:operation
                                               key:@"TestKey"
                                        identifier:@"TestIdentifier"
                                              data:data];
    return outputData;
}

- (NSData *)AES128WithOperation:(CCOperation)operation
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
        free(output);
        return nil;
    }
    
    return [NSData dataWithBytesNoCopy:output length:outputMovedSize];
}

- (NSString *)getKeyWithSuffix:(NSString *)suffix
                     accountID:(NSString *)accountID {
    return [NSString stringWithFormat:@"%@:%@", accountID, suffix];
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

@end

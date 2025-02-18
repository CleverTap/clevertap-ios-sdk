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

static NSString *const kENCRYPTION_KEY = @"CLTAP_ENCRYPTION_KEY";
static NSString *const kCRYPT_KEY_PREFIX = @"Lq3fz";
static NSString *const kCRYPT_KEY_SUFFIX = @"bLti2";
static NSString *const kCacheGUIDS = @"CachedGUIDS";

@interface CTEncryptionManager () {}
@property (nonatomic, strong) NSString *accountID;
@property (nonatomic, assign) CleverTapEncryptionLevel encryptionLevel;
@property (nonatomic, assign) BOOL isDefaultInstance;
@end

@implementation CTEncryptionManager

#pragma mark - Initialization & Coding

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

- (NSString *)encryptString:(NSString *)plaintext {
    if (_encryptionLevel != CleverTapEncryptionMedium || !plaintext) return plaintext;
    
    @try {
        NSData *data = [plaintext dataUsingEncoding:NSUTF8StringEncoding];
        NSData *encryptedData = [self processData:data operation:kCCEncrypt];
        return encryptedData ? [encryptedData base64EncodedStringWithOptions:0] : plaintext;
    } @catch (NSException *e) {
        CleverTapLogStaticInternal(@"Encryption error: %@", e.debugDescription);
        return plaintext;
    }
}

- (NSString *)decryptString:(NSString *)ciphertext {
    if (!ciphertext) return nil;
        
        @try {
            NSData *data = [[NSData alloc] initWithBase64EncodedString:ciphertext options:0];
            NSData *decryptedData = [self processData:data operation:kCCDecrypt];
            return decryptedData ? [[NSString alloc] initWithData:decryptedData
                                                       encoding:NSUTF8StringEncoding] : ciphertext;
        } @catch (NSException *e) {
            CleverTapLogStaticInternal(@"Decryption error: %@", e.debugDescription);
            return ciphertext;
        }
}

- (NSString *)encryptObject:(id)object {
    if (!object) return nil;
        
        @try {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
            NSData *encryptedData = [self processData:data operation:kCCEncrypt];
            return encryptedData ? [encryptedData base64EncodedStringWithOptions:0] : nil;
        } @catch (NSException *e) {
            CleverTapLogStaticInternal(@"Object encryption error: %@", e.debugDescription);
            return nil;
        }
}

- (id)decryptObject:(NSString *)ciphertext {
    if (!ciphertext) return nil;
        
        @try {
            NSData *data = [[NSData alloc] initWithBase64EncodedString:ciphertext options:0];
            NSData *decryptedData = [self processData:data operation:kCCDecrypt];
            return decryptedData ? [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData] : nil;
        } @catch (NSException *e) {
            CleverTapLogStaticInternal(@"Object decryption error: %@", e.debugDescription);
            return nil;
        }
}

#pragma mark - AES-GCM Methods

- (NSString *)encryptStringWithAESGCM:(NSString *)plaintext{
    if (_encryptionLevel != CleverTapEncryptionMedium || !plaintext) return plaintext;
    if (@available(iOS 13.0, *)) {
        CTAESGCMCrypt *ctaesgcm = [[CTAESGCMCrypt alloc] initWithKeychainTag:@"EncryptionKey"];
        NSError *encryptError = nil;
        NSString *encryptedString = [ctaesgcm encryptString:plaintext error:&encryptError];
        if (!encryptedString) {
            NSLog(@"Encryption failed: %@", encryptError.localizedDescription ?: @"Unknown error");
            return plaintext;
        }
        return encryptedString;
    }
    else {
        return [self encryptString:plaintext];
    }
}

- (NSString *)encryptObjectWithAESGCM:(id)object{
    if (!object) return nil;
    if (@available(iOS 13.0, *)) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
        CTAESGCMCrypt *ctaesgcm = [[CTAESGCMCrypt alloc] initWithKeychainTag:@"EncryptionKey"];
        NSError *encryptError = nil;
        NSString *encryptedData = [ctaesgcm encryptData:data error:&encryptError];
        if (!encryptedData) {
            NSLog(@"Encryption failed: %@", encryptError.localizedDescription ?: @"Unknown error");
            return object;
        }
        return encryptedData;
    }
    else {
        return [self encryptObject:object];
    }
}

- (NSString *)decryptStringWithAESGCM:(NSString *)ciphertext{
    if (!ciphertext) return nil;
    
    if (@available(iOS 13.0, *)) {
        CTAESGCMCrypt *ctaesgcm = [[CTAESGCMCrypt alloc] initWithKeychainTag:@"EncryptionKey"];

        NSError *encryptError = nil;
        NSString *decryptedString = [ctaesgcm decryptString:ciphertext error:&encryptError];
        
        if (!decryptedString) {
            NSLog(@"Decryption failed: %@", encryptError.localizedDescription ?: @"Unknown error");
            return ciphertext;
        }
        return decryptedString;
    }
    else {
        return [self decryptString:ciphertext];
    }
}

- (id)decryptObjectWithAESGCM:(NSString *)ciphertext {
    if (!ciphertext) return nil;
    
    if (@available(iOS 13.0, *)) {
        CTAESGCMCrypt *ctaesgcm = [[CTAESGCMCrypt alloc] initWithKeychainTag:@"EncryptionKey"];

        NSError *encryptError = nil;
        NSData *decryptedData = [ctaesgcm decryptData:ciphertext error:&encryptError];
        
        if (!decryptedData) {
            NSLog(@"Decryption failed: %@", encryptError.localizedDescription ?: @"Unknown error");
            return ciphertext;
        }
        return decryptedData ? [NSKeyedUnarchiver unarchiveObjectWithData:decryptedData] : nil;
    }
    else {
        return [self decryptObject:ciphertext];
    }
}

#pragma mark - Private Methods

- (void)updateCachedGUIDS {
    NSString *cacheKey = [CTUtils getKeyWithSuffix:kCacheGUIDS accountID:_accountID];
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
        [self encryptStringWithAESGCM:identifier] : [self decryptStringWithAESGCM:identifier];
        
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

@end

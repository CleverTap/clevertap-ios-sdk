#import <UIKit/UIKit.h>
#import "CTLocalDataStore.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTLoginInfoProvider.h"
#import "CTEncryptionManager.h"
#import "CTPreferences.h"
#import "CTUtils.h"
#import "CTCryptMigrator.h"

NSString *const CT_DECRYPTION_KEY = @"CLTAP_ENCRYPTION_KEY";
NSString *const kCachedGUIDSKey = @"CachedGUIDS";

@interface CTCryptMigrator() {
}

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTDeviceInfo *deviceInfo;
@property (nonatomic, strong) NSArray *piiKeys;
@property (nonatomic, strong) CTEncryptionManager *cryptManager;

@end

@implementation CTCryptMigrator

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
                 andDeviceInfo:(CTDeviceInfo*)deviceInfo {
    if (self = [super init]) {
        _config = config;
        _deviceInfo = deviceInfo;
        _piiKeys = CLTAP_ENCRYPTION_PII_DATA;
        _cryptManager = [[CTEncryptionManager alloc] initWithAccountID:_config.accountId];
        if ([self isMigrationNeeded]){
            [self performMigration];
        }
    }
    return self;
}

- (BOOL)isMigrationNeeded {
    return (BOOL) [CTPreferences getIntForKey:CLTAP_ENCRYPTION_MIGRATION_REQUIRED withResetValue:YES];
}

- (void)performMigration {
    BOOL migratedGUIDSuccesfully = NO;
    BOOL migratedUserProfileDataSuccesfully = NO;
    BOOL migratedInAppDataSuccesfully = NO;
    
    if (_config.encryptionLevel == CleverTapEncryptionMedium){
        migratedGUIDSuccesfully = [self migrateGUIDS];
        migratedUserProfileDataSuccesfully = [self migrateUserProfileData];
    }
    migratedInAppDataSuccesfully = [self migrateInAppData];
    
    if (migratedGUIDSuccesfully && migratedUserProfileDataSuccesfully && migratedInAppDataSuccesfully){
        [CTPreferences putInt:0 forKey:CLTAP_ENCRYPTION_MIGRATION_REQUIRED];
    } else {
        [CTPreferences putInt:1 forKey:CLTAP_ENCRYPTION_MIGRATION_REQUIRED];
    }
}

#pragma mark - CGK Migration

- (BOOL)migrateGUIDS {
    NSString *cacheKey = [CTUtils getKeyWithSuffix:kCachedGUIDSKey accountID:_config.accountId];
    NSDictionary *cachedGUIDS = [CTPreferences getObjectForKey:cacheKey];
    if (!cachedGUIDS) return NO;
    
    NSMutableDictionary *newCache = [NSMutableDictionary new];
    [cachedGUIDS enumerateKeysAndObjectsUsingBlock:^(NSString* cachedKey,
                                                    NSString* value,
                                                    BOOL* stop) {
        NSArray *components = [cachedKey componentsSeparatedByString:@"_"];
        if (components.count != 2) return;
        
        NSString *key = components[0];
        NSString *identifier = components[1];
        BOOL isCryptAESGCMEncrypted = NO;
        if (identifier != nil && [identifier isKindOfClass:[NSString class]]) {
            isCryptAESGCMEncrypted = [_cryptManager isTextAESGCMEncrypted:identifier];
            if (!isCryptAESGCMEncrypted) {
                NSString *decryptedString = [_cryptManager decryptString:identifier encryptionAlgorithm:AES];
                if (decryptedString) {
                    NSString *migratedEncryptedString = [_cryptManager encryptString:decryptedString];
                    newCache[[NSString stringWithFormat:@"%@_%@", key, migratedEncryptedString]] = value;
                }
            }
        }
    }];
    
    [CTPreferences putObject:newCache forKey:cacheKey];
    return YES;
}

#pragma mark - In-app Migration

- (BOOL) migrateInAppData {
   return ([self migrateInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY] &&
    [self migrateInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY_CS] &&
           [self migrateInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY_SS]);
}

- (BOOL)migrateInAppsWithKeySuffix:(NSString *)keySuffix {
    NSString *key = [self storageKeyWithSuffix:keySuffix];
    NSString *encryptedString = [CTPreferences getObjectForKey:key];
    BOOL isCryptAESGCMEncrypted = NO;
    if (encryptedString != nil && [encryptedString isKindOfClass:[NSString class]]) {
        isCryptAESGCMEncrypted = [_cryptManager isTextAESGCMEncrypted:encryptedString];
        if (!isCryptAESGCMEncrypted) {
            NSArray *arr = [_cryptManager decryptObject:encryptedString encryptionAlgorithm:AES];
            if (arr) {
                NSString *migratedEncryptedString = [_cryptManager encryptObject:arr];
                [CTPreferences putString:migratedEncryptedString forKey:keySuffix];
            }
        }
    }
    return YES;
}

- (NSString *)storageKeyWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@:%@", _config.accountId, _deviceInfo.deviceId, suffix];
}

#pragma mark - User Profile Cache migration

- (BOOL)migrateUserProfileData {
    NSSet *allowedClasses = [NSSet setWithObjects:[NSArray class], [NSString class], [NSDictionary class], [NSNumber class], nil];
    NSMutableDictionary *_profile = (NSMutableDictionary *)[CTPreferences unarchiveFromFile:[self profileFileName] ofTypes:allowedClasses removeFile:NO];
    if (!_profile) {
        _profile = [NSMutableDictionary dictionary];
    }
    NSMutableDictionary *updatedProfile = [self decryptOldPIIData:_profile];
    [CTPreferences archiveObject:updatedProfile forFileName:[self profileFileName] config:self->_config];
    return YES;
}

- (NSMutableDictionary *)decryptOldPIIData:(NSMutableDictionary *)profile {
    long lastEncryptionLevel = [CTPreferences getIntForKey:[CTUtils getKeyWithSuffix:CT_DECRYPTION_KEY accountID:self.config.accountId] withResetValue:0];
    if (lastEncryptionLevel == CleverTapEncryptionMedium && _cryptManager) {
        // Always store the local profile data in decrypted values.
        NSMutableDictionary *updatedProfile = [NSMutableDictionary new];
        for (NSString *key in profile) {
            if ([_piiKeys containsObject:key]) {
                NSString *value = [NSString stringWithFormat:@"%@",profile[key]];
                BOOL isCryptAESGCMEncrypted = NO;
                if (value != nil && [value isKindOfClass:[NSString class]]) {
                    isCryptAESGCMEncrypted = [_cryptManager isTextAESGCMEncrypted:value];
                    if (!isCryptAESGCMEncrypted) {
                        NSString *decryptedString = [_cryptManager decryptString:value encryptionAlgorithm:AES];
                        NSString *encryptedAESGCMString = [_cryptManager encryptString:decryptedString];
                        updatedProfile[key] = encryptedAESGCMString;
                    }
                }
            } else {
                updatedProfile[key] = profile[key];
            }
        }
        return updatedProfile;
    }
    return profile;
}

- (NSString *)profileFileName {
    return [NSString stringWithFormat:@"clevertap-%@-%@-userprofile.plist", self.config.accountId, _deviceInfo.deviceId];
}

@end

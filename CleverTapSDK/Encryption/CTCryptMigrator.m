#import <UIKit/UIKit.h>
#import "CTLocalDataStore.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CleverTapInstanceConfig.h"
#import "CleverTapInstanceConfigPrivate.h"
#import "CTLoginInfoProvider.h"
#import "CTEncryptionManager.h"
#import "CTPreferences.h"
#import "CTUtils.h"
#import "CTUIUtils.h"
#import "CTCryptMigrator.h"

static const void *const kProfileBackgroundQueueKey = &kProfileBackgroundQueueKey;
NSString *const CT_DECRYPTION_KEY = @"CLTAP_ENCRYPTION_KEY";
NSString *const kCachedGUIDSKey = @"CachedGUIDS";

@interface CTCryptMigrator() {
    NSMutableDictionary *localProfileForSession;
    dispatch_queue_t _backgroundQueue;
}

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTDeviceInfo *deviceInfo;
@property (nonatomic, strong) NSArray *piiKeys;
@property (nonatomic, strong) CTDispatchQueueManager *dispatchQueueManager;
@property (nonatomic, strong) CTEncryptionManager *cryptManager;

@end

@implementation CTCryptMigrator

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
                 andDeviceInfo:(CTDeviceInfo*)deviceInfo
                 profileValues:(NSDictionary*)profileValues {
    if (self = [super init]) {
        _config = config;
        _deviceInfo = deviceInfo;
        _piiKeys = CLTAP_ENCRYPTION_PII_DATA;
        _cryptManager = [[CTEncryptionManager alloc] initWithAccountID:_config.accountId];
        if (config.encryptionLevel == CleverTapEncryptionMedium){
            [self migrateUserProfileData];
            [self migrateGUIDS];
        }
        [self migrateInAppData];

    }
    return self;
}

#pragma mark - CGK Migration

- (void)migrateGUIDS {
    NSString *cacheKey = [CTUtils getKeyWithSuffix:kCachedGUIDSKey accountID:_config.accountId];
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
        NSString *decryptedString = [_cryptManager decryptString:identifier];
        if (decryptedString) {
            NSString *migratedEncryptedString = [_cryptManager encryptStringWithAESGCM:decryptedString];
            newCache[[NSString stringWithFormat:@"%@_%@", key, migratedEncryptedString]] = value;
        }
    }];
    
    [CTPreferences putObject:newCache forKey:cacheKey];
}

#pragma mark - In-app Migration

- (NSString *)storageKeyWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@:%@", _config.accountId, _deviceInfo.deviceId, suffix];
}

- (void)migrateInAppsWithKeySuffix:(NSString *)keySuffix {
    NSString *key = [self storageKeyWithSuffix:keySuffix];
    NSString *encryptedString = [CTPreferences getObjectForKey:key];
    if (encryptedString) {
        NSArray *arr = [_cryptManager decryptObject:encryptedString];
        if (arr) {
            NSString *migratedEncryptedString = [_cryptManager encryptObjectWithAESGCM:arr];
            [CTPreferences putString:migratedEncryptedString forKey:keySuffix];
        }
    }
}

- (void) migrateInAppData {
    [self migrateInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY];
    [self migrateInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY_CS];
    [self migrateInAppsWithKeySuffix:CLTAP_PREFS_INAPP_KEY_SS];
}

#pragma mark - User Profile Cache migration

- (NSString *)profileFileName {
    return [NSString stringWithFormat:@"clevertap-%@-%@-userprofile.plist", self.config.accountId, _deviceInfo.deviceId];
}

- (void)migrateUserProfileData {
    NSSet *allowedClasses = [NSSet setWithObjects:[NSArray class], [NSString class], [NSDictionary class], [NSNumber class], nil];
    NSMutableDictionary *_profile = (NSMutableDictionary *)[CTPreferences unarchiveFromFile:[self profileFileName] ofTypes:allowedClasses removeFile:NO];
    if (!_profile) {
        _profile = [NSMutableDictionary dictionary];
    }
    NSMutableDictionary *updatedProfile = [self decryptOldPIIData:_profile];
    [CTPreferences archiveObject:updatedProfile forFileName:[self profileFileName] config:self->_config];
}

- (NSMutableDictionary *)decryptOldPIIData:(NSMutableDictionary *)profile {
    long lastEncryptionLevel = [CTPreferences getIntForKey:[CTUtils getKeyWithSuffix:CT_DECRYPTION_KEY accountID:self.config.accountId] withResetValue:0];
    if (lastEncryptionLevel == CleverTapEncryptionMedium && _cryptManager) {
        // Always store the local profile data in decrypted values.
        NSMutableDictionary *updatedProfile = [NSMutableDictionary new];
        for (NSString *key in profile) {
            if ([_piiKeys containsObject:key]) {
                NSString *value = [NSString stringWithFormat:@"%@",profile[key]];
                NSString *decryptedString = [_cryptManager decryptString:value];
                NSString *encryptedAESGCMString = [_cryptManager encryptStringWithAESGCM:decryptedString];
                updatedProfile[key] = encryptedAESGCMString;
            } else {
                updatedProfile[key] = profile[key];
            }
        }
        return updatedProfile;
    }
    return profile;
}

#pragma mark - Utility Methods

- (BOOL)inBackgroundQueue {
    CTCryptMigrator *currentQueue = (__bridge id) dispatch_get_specific(kProfileBackgroundQueueKey);
    return currentQueue == self;
}

- (void)runOnBackgroundQueue:(void (^)(void))taskBlock {
    if ([self inBackgroundQueue]) {
        taskBlock();
    } else {
        dispatch_async(_backgroundQueue, taskBlock);
    }
}

@end

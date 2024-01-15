//
//  CTInAppFCManager+Legacy.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 19.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTInAppFCManager+Legacy.h"
#import "CTPreferences.h"
#import "CTConstants.h"

@implementation CTInAppFCManager(Legacy)

- (NSString *)oldStorageKeyWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@", self.config.accountId, suffix];
}

- (void)migratePreferenceKeys {
    //Move old key value pair data to new keys and delete old keys
    [self lastUpdateKeyChanges];
    [self countShownTodayKeyChanges];
    [self countPerInAppKeyChanges];
    [self countPerInAppKeyChangesForDefaultConfig];
}

- (void)lastUpdateKeyChanges {
    // Last update key changes
    NSString *localLastUpdateKey = [self oldStorageKeyWithSuffix:CLTAP_PREFS_INAPP_LAST_DATE_KEY];
    NSString *localLastUpdateTime = [CTPreferences getStringForKey:localLastUpdateKey withResetValue:nil];
    
    // Store value in new key and delete old key
    if (localLastUpdateTime != nil) {
        [CTPreferences putString:localLastUpdateTime forKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_LAST_DATE_KEY]];
        [CTPreferences removeObjectForKey: localLastUpdateKey];
    }
    
}

- (void)countShownTodayKeyChanges {
    NSString *localCountShownKey = [self oldStorageKeyWithSuffix:CLTAP_PREFS_INAPP_COUNTS_SHOWN_TODAY_KEY];
    //Check value exist otherwise fetch call will reset it reset value
    if ([CTPreferences getObjectForKey:localCountShownKey] == nil || ![[CTPreferences getObjectForKey:localCountShownKey] isKindOfClass:[NSNumber class]]) {
        return;
    }
    
    int localCountShown = (int) [CTPreferences getIntForKey:localCountShownKey withResetValue:0] ;
    //Store value in new key and delete old key
    [CTPreferences putInt:localCountShown forKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_COUNTS_SHOWN_TODAY_KEY]];
    [CTPreferences removeObjectForKey: localCountShownKey];
}

- (void)countPerInAppKeyChanges {
    // Count For InApp key changes
    NSString *localInAppKey = [self oldStorageKeyWithSuffix:CLTAP_PREFS_INAPP_COUNTS_PER_INAPP_KEY];
    NSDictionary *localInApp = [CTPreferences getObjectForKey: localInAppKey];
    
    //Store value in new key and delete Old key
    if (localInApp != nil) {
        [CTPreferences putObject:localInApp forKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_COUNTS_PER_INAPP_KEY]];
        [CTPreferences removeObjectForKey: localInAppKey];
    }
}

- (void)countPerInAppKeyChangesForDefaultConfig {
    // Count For InApp key changes
    NSDictionary *defaultDictionary = [CTPreferences getObjectForKey:CLTAP_PREFS_INAPP_COUNTS_PER_INAPP_KEY];
    
    //Store value in new key and delete old key
    if (defaultDictionary != nil) {
        [CTPreferences putObject:defaultDictionary forKey:[NSString stringWithFormat:@"%@:%@", CLTAP_PREFS_INAPP_COUNTS_PER_INAPP_KEY, self.deviceId]];
        [CTPreferences removeObjectForKey:CLTAP_PREFS_INAPP_COUNTS_PER_INAPP_KEY];
    }
}

@end

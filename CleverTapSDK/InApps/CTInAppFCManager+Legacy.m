//
//  CTInAppFCManager+Legacy.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 19.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTInAppFCManager+Legacy.h"
#import "CTPreferences.h"

// TODO: move to one place only
// Storage keys
//NSString* const kKEY_COUNTS_PER_INAPP = @"counts_per_inapp";
//NSString* const kKEY_COUNTS_SHOWN_TODAY = @"istc_inapp";
//NSString* const kKEY_MAX_PER_DAY = @"istmcd_inapp";

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
    NSString *localLastUpdateKey = [self oldStorageKeyWithSuffix:@"ict_date"];
    NSString *localLastUpdateTime = [CTPreferences getStringForKey:localLastUpdateKey withResetValue:nil];
    
    // Store value in new key and delete old key
    if (localLastUpdateTime != nil) {
        [CTPreferences putString:localLastUpdateTime forKey:[self storageKeyWithSuffix:@"ict_date"]];
        [CTPreferences removeObjectForKey: localLastUpdateKey];
    }
    
}

- (void)countShownTodayKeyChanges {
    NSString *localCountShownKey = [self oldStorageKeyWithSuffix:kKEY_COUNTS_SHOWN_TODAY];
    //Check value exist otherwise fetch call will reset it reset value
    if ([CTPreferences getObjectForKey:localCountShownKey] == nil || ![[CTPreferences getObjectForKey:localCountShownKey] isKindOfClass:[NSNumber class]]) {
        return;
    }
    
    int localCountShown = (int) [CTPreferences getIntForKey:localCountShownKey withResetValue:0] ;
    //Store value in new key and delete old key
    [CTPreferences putInt:localCountShown forKey:[self storageKeyWithSuffix:kKEY_COUNTS_SHOWN_TODAY]];
    [CTPreferences removeObjectForKey: localCountShownKey];
}

- (void)countPerInAppKeyChanges {
    // Count For InApp key changes
    NSString *localInAppKey = [self oldStorageKeyWithSuffix:kKEY_COUNTS_PER_INAPP];
    NSDictionary *localInApp = [CTPreferences getObjectForKey: localInAppKey];
    
    //Store value in new key and delete Old key
    if (localInApp != nil) {
        [CTPreferences putObject:localInApp forKey:[self storageKeyWithSuffix:kKEY_COUNTS_PER_INAPP]];
        [CTPreferences removeObjectForKey: localInAppKey];
    }
}

- (void)countPerInAppKeyChangesForDefaultConfig {
    // Count For InApp key changes
    NSDictionary *defaultDictionary = [CTPreferences getObjectForKey:kKEY_COUNTS_PER_INAPP];
    
    //Store value in new key and delete old key
    if (defaultDictionary != nil) {
        [CTPreferences putObject:defaultDictionary forKey:[NSString stringWithFormat:@"%@:%@", kKEY_COUNTS_PER_INAPP, self.deviceId]];
        [CTPreferences removeObjectForKey:kKEY_COUNTS_PER_INAPP];
    }
}

@end

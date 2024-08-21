#import "CTUserInfoMigrator.h"
#import "CTConstants.h"
#import "CTPreferences.h"

@implementation CTUserInfoMigrator

+ (void)migrateUserInfoFileForDeviceID:(NSString *)device_id config:(CleverTapInstanceConfig *) config {
    NSString *acc_id = config.accountId;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryPath = [paths objectAtIndex:0];
    NSString *userProfileWithAccountID = [NSString stringWithFormat:@"clevertap-%@-userprofile.plist", acc_id];
    NSString *userProfileWithAccountIDPath = [libraryPath stringByAppendingPathComponent:userProfileWithAccountID];
    NSString *userProfileWithAccountIDAndDeviceID = [NSString stringWithFormat:@"clevertap-%@-%@-userprofile.plist", acc_id, device_id];
    NSString *userProfileWithAccountIDAndDeviceIDPath = [libraryPath stringByAppendingPathComponent:userProfileWithAccountIDAndDeviceID];
    NSError *error = nil;
    
    // migration from 5.x and 6.x
    if ([fileManager fileExistsAtPath:userProfileWithAccountIDPath]) {
        // unarchive, remove user prefix, copy to new deviceid path
        NSSet *allowedClasses = [NSSet setWithObjects:[NSArray class], [NSString class], [NSDictionary class], [NSNumber class], nil];
        NSMutableDictionary *userProfile = [CTPreferences unarchiveFromFile:userProfileWithAccountID ofTypes:allowedClasses removeFile:NO];
        // remove prefixes from only the system fields
        [self removeUserPrefixInDictionary:userProfile];
        // store this new clean file at userProfileWithAccountIDAndDeviceIDPath
        [CTPreferences archiveObject:userProfile forFileName:userProfileWithAccountID config:config];
        [fileManager copyItemAtPath:userProfileWithAccountIDPath toPath:userProfileWithAccountIDAndDeviceIDPath error:&error];
        CleverTapLogStaticInternal(@"[CTUserInfo]: Local file copied successfully to %@", userProfileWithAccountIDAndDeviceIDPath);
        [fileManager removeItemAtPath:userProfileWithAccountIDPath error:&error];
        return;
    }
    
    // migration from 7.0.0
    else if ([fileManager fileExistsAtPath:userProfileWithAccountIDAndDeviceIDPath]) {
        // unarchive the file at this path
        NSSet *allowedClasses = [NSSet setWithObjects:[NSArray class], [NSString class], [NSDictionary class], [NSNumber class], nil];
        NSMutableDictionary *userProfile = [CTPreferences unarchiveFromFile:userProfileWithAccountIDAndDeviceID ofTypes:allowedClasses removeFile:NO];
        // remove prefixes from only the system fields
        [self removeUserPrefixInDictionary:userProfile];
        // update the new file at userProfileWithAccountIDAndDeviceIDPath
        [CTPreferences archiveObject:userProfile forFileName:userProfileWithAccountIDAndDeviceID config:config];
        return;
    } else {
        CleverTapLogStaticInternal(@"[CTUserInfo]: Failed to copy local file: %@", error.localizedDescription);
    }
}

+ (void)removeUserPrefixInDictionary:(NSMutableDictionary *)dictionary {
    // List of known profile fields
    NSArray *knownProfileFields = @[
        @"userName", @"userEmail", @"userEducation", @"userMarried",
        @"userDOB", @"userBirthday", @"userEmployed", @"userGender",
        @"userPhone", @"userAge"
    ];

    // Iterate through the original dictionary's keys
    for (NSString *key in [dictionary allKeys]) {
        if ([knownProfileFields containsObject:key]) {
            NSString *newKey = [key substringFromIndex:[@"user" length]];

            // Update the dictionary with the new key
            id value = dictionary[key];
            [dictionary removeObjectForKey:key];
            [dictionary setObject:value forKey:newKey];
        }
    }
}
@end

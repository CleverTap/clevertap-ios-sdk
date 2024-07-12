#import "CTUserInfoMigrator.h"
#import "CTConstants.h"

@implementation CTUserInfoMigrator

+ (void)migrateUserInfoFileForAccountID:(NSString *)acc_id deviceID:(NSString *)device_id {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryPath = [paths objectAtIndex:0];
    NSString *userProfileWithAccountID = [NSString stringWithFormat:@"clevertap-%@-userprofile.plist", acc_id];
    NSString *userProfileWithAccountIDPath = [libraryPath stringByAppendingPathComponent:userProfileWithAccountID];
    NSString *userProfileWithAccountIDAndDeviceID = [NSString stringWithFormat:@"clevertap-%@-%@-userprofile.plist", acc_id, device_id];
    NSString *userProfileWithAccountIDAndDeviceIDPath = [libraryPath stringByAppendingPathComponent:userProfileWithAccountIDAndDeviceID];
    
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:userProfileWithAccountIDPath]) {
        [fileManager copyItemAtPath:userProfileWithAccountIDPath toPath:userProfileWithAccountIDAndDeviceIDPath error:&error];
        CleverTapLogStaticInternal(@"[CTUserInfo]: Local file copied successfully to %@", userProfileWithAccountIDAndDeviceIDPath);
        [fileManager removeItemAtPath:userProfileWithAccountIDPath error:&error];
        return;
    } else {
        CleverTapLogStaticInternal(@"[CTUserInfo]: Failed to copy local file: %@", error.localizedDescription);
    }
}

@end

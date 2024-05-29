//
//  CTUserInfoMigrator.m
//
//  Created by Kushagra Mishra on 29/05/24.
//

#import "CTUserInfoMigrator.h"

@implementation CTUserInfoMigrator

+ (void)migrateUserInfoFileForAccountID:(NSString *)acc_id deviceID:(NSString *)device_id {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Get the path to the Documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryPath = [paths objectAtIndex:0];
    
    // Construct the old plist file name and path
    NSString *userProfileWithDeviceID = [NSString stringWithFormat:@"clevertap-%@-userprofile.plist", acc_id];
    NSString *userProfileWithDeviceIDPath = [libraryPath stringByAppendingPathComponent:userProfileWithDeviceID];
        
    // Construct the new plist file name and path
    NSString *userProfileWithDeviceIDAndGUID = [NSString stringWithFormat:@"clevertap-%@-%@-userprofile.plist", acc_id, device_id];
    NSString *userProfileWithDeviceIDAndGUIDPath = [libraryPath stringByAppendingPathComponent:userProfileWithDeviceIDAndGUID];
    
    NSError *error = nil;
    if ([fileManager fileExistsAtPath:userProfileWithDeviceIDAndGUIDPath]) {
        NSLog(@"[CTUserInfo]: new Plist file exists %@", userProfileWithDeviceIDAndGUIDPath);
        if ([fileManager fileExistsAtPath:userProfileWithDeviceIDAndGUIDPath]) {
            [fileManager removeItemAtPath:userProfileWithDeviceIDPath error:&error];
            return;
        }
    }
  
    // Copy the plist file to the new location with the new name
    if ([fileManager copyItemAtPath:userProfileWithDeviceIDPath toPath:userProfileWithDeviceIDAndGUIDPath error:&error]) {
        NSLog(@"[CTUserInfo]: Plist file copied successfully to %@", userProfileWithDeviceIDAndGUIDPath);
        [fileManager removeItemAtPath:userProfileWithDeviceIDPath error:&error];
    } else {
        NSLog(@"[CTUserInfo]: Failed to copy plist file: %@", error.localizedDescription);
    }
}



@end

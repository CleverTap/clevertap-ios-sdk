//
//  CTUserInfoMigratorTests.m
//  CleverTapSDKTests
//
//  Created by Kushagra Mishra on 21/06/24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTUserInfoMigrator.h"
#import "XCTestCase+XCTestCase_Tests.h"
#import "CleverTapInstanceConfig.h"

@interface CTUserInfoMigratorTest : XCTestCase

@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) NSString *libraryPath;
@property (nonatomic, strong) CleverTapInstanceConfig *config;

@end

@implementation CTUserInfoMigratorTest


- (void)setUp {
    [super setUp];
    self.fileManager = [NSFileManager defaultManager];
    
    // Get the path to the Library directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    self.libraryPath = [paths objectAtIndex:0];
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccID" accountToken:@"testToken" accountRegion:@"testRegion"];
}

- (void)tearDown {
    // Clean up any files created during the test
    NSError *error = nil;
    NSArray *contents = [self.fileManager contentsOfDirectoryAtPath:self.libraryPath error:&error];
    for (NSString *file in contents) {
        if ([file containsString:@"clevertap-"]) {
            NSString *filePath = [self.libraryPath stringByAppendingPathComponent:file];
            [self.fileManager removeItemAtPath:filePath error:&error];
        }
    }
    [super tearDown];
}

- (void)testMigrateUserInfoFileForAccountID_WhenOldFileExists_ShouldCopyToNewLocation {
    NSString *acc_id = @"testAccID";
    NSString *device_id = @"testDeviceID";
    
    // Create the old plist file
    NSString *oldFileName = [NSString stringWithFormat:@"clevertap-%@-userprofile.plist", acc_id];
    NSString *oldFilePath = [self.libraryPath stringByAppendingPathComponent:oldFileName];
    [self.fileManager createFileAtPath:oldFilePath contents:[@"old content" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    
    // Call the method to migrate the user info file
    [CTUserInfoMigrator migrateUserInfoFileForDeviceID:device_id config:self.config];
    
    // Check that the old file has been copied to the new location
    NSString *newFileName = [NSString stringWithFormat:@"clevertap-%@-%@-userprofile.plist", acc_id, device_id];
    NSString *newFilePath = [self.libraryPath stringByAppendingPathComponent:newFileName];
    XCTAssertTrue([self.fileManager fileExistsAtPath:newFilePath], @"New plist file should exist");
    
    // Check that the old file has been deleted
    XCTAssertFalse([self.fileManager fileExistsAtPath:oldFilePath], @"Old plist file should be deleted");
}

- (void)testMigrateUserInfoFileForAccountID_WhenNewFileExists_ShouldNotCopyAndDeleteOldFile {
    NSString *acc_id = @"testAccID";
    NSString *device_id = @"testDeviceID";
    
    // Create both old and new plist files
    NSString *oldFileName = [NSString stringWithFormat:@"clevertap-%@-userprofile.plist", acc_id];
    NSString *oldFilePath = [self.libraryPath stringByAppendingPathComponent:oldFileName];
    [self.fileManager createFileAtPath:oldFilePath contents:[@"old content" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    
    NSString *newFileName = [NSString stringWithFormat:@"clevertap-%@-%@-userprofile.plist", acc_id, device_id];
    NSString *newFilePath = [self.libraryPath stringByAppendingPathComponent:newFileName];
    [self.fileManager createFileAtPath:newFilePath contents:[@"new content" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    
    // Call the method to migrate the user info file
    [CTUserInfoMigrator migrateUserInfoFileForDeviceID:device_id config:self.config];
    
    // Check that the new file still exists
    XCTAssertTrue([self.fileManager fileExistsAtPath:newFilePath], @"New plist file should exist");
    
    // Check that the old file has been deleted
    XCTAssertFalse([self.fileManager fileExistsAtPath:oldFilePath], @"Old plist file should be deleted");
}

- (void)testMigrateUserInfoFileForAccountID_WhenOldFileDoesNotExist_ShouldNotCreateNewFile {
    NSString *acc_id = @"testAccID";
    NSString *device_id = @"testDeviceID";
    
    // Ensure the old plist file does not exist
    NSString *oldFileName = [NSString stringWithFormat:@"clevertap-%@-userprofile.plist", acc_id];
    NSString *oldFilePath = [self.libraryPath stringByAppendingPathComponent:oldFileName];
    [self.fileManager removeItemAtPath:oldFilePath error:nil];
    
    // Call the method to migrate the user info file
    [CTUserInfoMigrator migrateUserInfoFileForDeviceID:device_id config:self.config];
    
    // Check that the new file does not exist
    NSString *newFileName = [NSString stringWithFormat:@"clevertap-%@-%@-userprofile.plist", acc_id, device_id];
    NSString *newFilePath = [self.libraryPath stringByAppendingPathComponent:newFileName];
    XCTAssertFalse([self.fileManager fileExistsAtPath:newFilePath], @"New plist file should not be created");
}

@end

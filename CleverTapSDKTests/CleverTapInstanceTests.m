//
//  CleverTapInstanceTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 15/12/21.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BaseTestCase.h"
#import "CTPlistInfo.h"
#import "CTPreferences.h"

@interface CleverTapInstanceTests : BaseTestCase

@end

@implementation CleverTapInstanceTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_clevertap_shared_instance_exists {
    XCTAssertNotNil(self.cleverTapInstance);
}

//- (void)test_clevertap_addtional_instance_exists {
//    XCTAssertNotNil(self.additionalInstance);
//}

- (void)test_clevertap_instance_has_guid {
    NSString *ctguid = [self.cleverTapInstance profileGetCleverTapID];
    XCTAssertNotNil(ctguid);
}

- (void)test_clevertap_instance_sets_creds_in_info_plist{
    CTPlistInfo *plistInfo = [CTPlistInfo sharedInstance];
    XCTAssertEqualObjects(plistInfo.accountId, @"test");
    XCTAssertEqualObjects(plistInfo.accountToken, @"test");
    XCTAssertEqualObjects(plistInfo.accountRegion, @"eu1");
}

- (void)test_clevertap_instance_personalization_enabled{
    [CleverTap enablePersonalization];
    BOOL result = [CTPreferences getIntForKey:@"boolPersonalisationEnabled" withResetValue:0];
    XCTAssertTrue(result);
}

- (void)test_clevertap_instance_personalization_disabled {
    [CleverTap disablePersonalization];
    BOOL result = [CTPreferences getIntForKey:@"boolPersonalisationEnabled" withResetValue:0];
    XCTAssertFalse(result);
}

- (void)test_clevertap_shared_get_global_instance {
    CleverTap *shared = [CleverTap sharedInstance];
    CleverTap *instance = [CleverTap getGlobalInstance:[shared getAccountID]];
    XCTAssertEqualObjects(instance, shared);
}

- (void)test_clevertap_get_global_instance {
    CleverTap *instance = [CleverTap getGlobalInstance:@"test"];
    XCTAssertNotNil(instance);
    XCTAssertEqualObjects([[instance config] accountId], @"test");
    XCTAssertEqualObjects([[instance config] accountToken], @"test");
}

@end

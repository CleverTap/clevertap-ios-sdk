//
//  CTDeviceInfoTest.m
//  CleverTapSDKTests
//
//  Created by Aishwarya Nanna on 17/02/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTDeviceInfo.h"
#import "CleverTapInstanceConfig.h"

@interface CTDeviceInfoTest : XCTestCase
@property (nonatomic, strong) CTDeviceInfo *classObject;
@end

@implementation CTDeviceInfoTest

- (void)setUp {
    self.classObject = [[CTDeviceInfo alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_initialize {
//    [CTDeviceInfo initialize];
    
//    XCTAssertNotNil([_classObject _idfv]);

}

- (void)test_initWithConfig{
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccount" accountToken:@"testToken"];
    _classObject = [_classObject initWithConfig:config andCleverTapID:@"testAccount"];
    
    XCTAssertNotNil([_classObject deviceId]);
}

- (void)test_forceUpdateDeviceID{
    [_classObject forceUpdateDeviceID:@"test_device_id"];
    
    XCTAssertNotNil([_classObject deviceId]);
    XCTAssertEqualObjects([_classObject deviceId], @"test_device_id");
}

- (void)test_forceNewDeviceID{
    [_classObject forceNewDeviceID];
    
    XCTAssertNotNil([_classObject deviceId]);
    XCTAssertEqual([[[_classObject deviceId] componentsSeparatedByString:@"-"] count]-1, 1);
    XCTAssertTrue([[_classObject deviceId] hasPrefix:@"-"]);
}

- (void)test_forceUpdateCustomDeviceID{
    [_classObject forceUpdateCustomDeviceID:@"test_custom_ctID"];
    
    XCTAssertNotNil([_classObject deviceId]);
    XCTAssertEqualObjects([_classObject deviceId], @"-htest_custom_ctID");
    XCTAssertTrue([[_classObject deviceId] hasPrefix:@"-h"]);
}

- (void)test_forceUpdateCustomDeviceID_withInvalidCTid{
    [_classObject forceUpdateCustomDeviceID:@"#test_custom_ctID"];
    
    XCTAssertNotNil([_classObject deviceId]);
    XCTAssertNotNil([_classObject fallbackDeviceId]);
    XCTAssertEqualObjects([_classObject deviceId], [_classObject fallbackDeviceId]);
}

- (void)test_isErrorDeviceID_withErrorID{
    [_classObject forceUpdateDeviceID:@"-itest_error_device_id"];
    
    XCTAssertNotNil([_classObject deviceId]);
    XCTAssertTrue([_classObject isErrorDeviceID]);
}

- (void)test_isErrorDeviceID_withoutErrorID{
    [_classObject forceUpdateDeviceID:@"test_error_device_id"];
    
    XCTAssertNotNil([_classObject deviceId]);
    XCTAssertFalse([_classObject isErrorDeviceID]);
}

@end

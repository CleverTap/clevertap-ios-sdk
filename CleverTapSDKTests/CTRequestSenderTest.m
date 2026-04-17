//
//  CTRequestSenderTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTRequestSender.h"
#import "CleverTapInstanceConfig.h"

@interface CTRequestSenderTest : XCTestCase
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@end

@implementation CTRequestSenderTest

- (void)setUp {
    [super setUp];
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccount" accountToken:@"testToken"];
}

- (void)tearDown {
    self.config = nil;
    [super tearDown];
}

#pragma mark - init

- (void)test_init_storesRedirectDomain {
    CTRequestSender *sender = [[CTRequestSender alloc] initWithConfig:self.config redirectDomain:@"eu1.clevertap-prod.com"];
    XCTAssertEqualObjects(sender.redirectDomain, @"eu1.clevertap-prod.com");
}

- (void)test_init_nilRedirectDomain_storesNil {
    CTRequestSender *sender = [[CTRequestSender alloc] initWithConfig:self.config redirectDomain:nil];
    XCTAssertNil(sender.redirectDomain);
}

- (void)test_initWithTimeouts_storesRequestTimeout {
    CTRequestSender *sender = [[CTRequestSender alloc] initWithConfig:self.config
                                                       redirectDomain:nil
                                                       requestTimeout:30.0
                                                      resourceTimeout:60.0];
    XCTAssertEqualWithAccuracy(sender.requestTimeout, 30.0, 0.001);
}

- (void)test_initWithTimeouts_storesResourceTimeout {
    CTRequestSender *sender = [[CTRequestSender alloc] initWithConfig:self.config
                                                       redirectDomain:nil
                                                       requestTimeout:30.0
                                                      resourceTimeout:60.0];
    XCTAssertEqualWithAccuracy(sender.resourceTimeout, 60.0, 0.001);
}

- (void)test_initWithTimeouts_differentValues_storedIndependently {
    CTRequestSender *sender = [[CTRequestSender alloc] initWithConfig:self.config
                                                       redirectDomain:nil
                                                       requestTimeout:15.0
                                                      resourceTimeout:45.0];
    XCTAssertNotEqual(sender.requestTimeout, sender.resourceTimeout);
}

#pragma mark - redirectDomain mutation

- (void)test_setRedirectDomain_updatesProperty {
    CTRequestSender *sender = [[CTRequestSender alloc] initWithConfig:self.config redirectDomain:nil];
    sender.redirectDomain = @"custom.example.com";
    XCTAssertEqualObjects(sender.redirectDomain, @"custom.example.com");
}

- (void)test_setRedirectDomain_toNil_clearsProperty {
    CTRequestSender *sender = [[CTRequestSender alloc] initWithConfig:self.config redirectDomain:@"eu1.clevertap-prod.com"];
    sender.redirectDomain = nil;
    XCTAssertNil(sender.redirectDomain);
}

@end

//
//  CleverTapUTMDetailTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CleverTapUTMDetail.h"

@interface CleverTapUTMDetailTest : XCTestCase
@property (nonatomic, strong) CleverTapUTMDetail *detail;
@end

@implementation CleverTapUTMDetailTest

- (void)setUp {
    [super setUp];
    self.detail = [[CleverTapUTMDetail alloc] init];
}

- (void)tearDown {
    self.detail = nil;
    [super tearDown];
}

#pragma mark - default values

- (void)test_defaultValues_sourceIsNil {
    XCTAssertNil(self.detail.source);
}

- (void)test_defaultValues_mediumIsNil {
    XCTAssertNil(self.detail.medium);
}

- (void)test_defaultValues_campaignIsNil {
    XCTAssertNil(self.detail.campaign);
}

#pragma mark - property set and get

- (void)test_setSource_returnsSource {
    self.detail.source = @"google";
    XCTAssertEqualObjects(self.detail.source, @"google");
}

- (void)test_setMedium_returnsMedium {
    self.detail.medium = @"cpc";
    XCTAssertEqualObjects(self.detail.medium, @"cpc");
}

- (void)test_setCampaign_returnsCampaign {
    self.detail.campaign = @"summer_sale";
    XCTAssertEqualObjects(self.detail.campaign, @"summer_sale");
}

- (void)test_setAllProperties_allReturnCorrectValues {
    self.detail.source = @"email";
    self.detail.medium = @"newsletter";
    self.detail.campaign = @"launch";
    XCTAssertEqualObjects(self.detail.source, @"email");
    XCTAssertEqualObjects(self.detail.medium, @"newsletter");
    XCTAssertEqualObjects(self.detail.campaign, @"launch");
}

- (void)test_setNil_clearsProperty {
    self.detail.source = @"google";
    self.detail.source = nil;
    XCTAssertNil(self.detail.source);
}

@end

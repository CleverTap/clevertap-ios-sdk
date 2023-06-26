//
//  LeanplumCTTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 9.06.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "LeanplumCT.h"
#import "CleverTap.h"

@interface LeanplumCTTest : XCTestCase
@property (nonatomic, strong) id mockCleverTap;
@end

@implementation LeanplumCTTest

- (void)setUp {
    [super setUp];
    self.mockCleverTap = OCMClassMock([CleverTap class]);
    [LeanplumCT setInstance:self.mockCleverTap];
}

- (void)tearDown {
    [self.mockCleverTap stopMocking];
    self.mockCleverTap = nil;
    [super tearDown];
}

- (void)testTrackWithParameters {
    NSDictionary *parameters = @{
        @"str": @"str",
        @"arr": @[ @"one", @"two", @3, [NSNull null] ],
        @"dict": @{
            @"test": @123,
            @"null": [NSNull null]
        }
    };
    
    NSDictionary *expectedProps = @{
        @"str": @"str",
        @"arr": @"[one,two,3]",
        @"dict": @{
            @"test": @123,
            @"null": [NSNull null]
        },
        @"value": @0
    };
    [[self.mockCleverTap expect] recordEvent:@"event" withProps:expectedProps];
    
    [LeanplumCT track:@"event" withParameters:parameters];
    
    [self.mockCleverTap verify];
}

- (void)testTrackPurchase {
    NSDictionary<NSString *, id> *parameters = @{ @"key1": @"value1" };
    NSDictionary *expectedProps = @{
        @"key1": @"value1",
        @"event": @"Purchase",
        @"currencyCode": @"USD",
        @"value": @9.89
    };
    [[self.mockCleverTap expect] recordChargedEventWithDetails:expectedProps andItems:@[]];
    [LeanplumCT trackPurchase:@"Purchase" withValue:9.89 andCurrencyCode:@"USD" andParameters:parameters];
    [self.mockCleverTap verify];
}

- (void)testAdvanceToStateWithInfoAndParameters {
    NSString *state = @"state";
    NSString *info = @"info";
    NSDictionary<NSString *, id> *parameters = @{ @"key1": @"value1" };
    NSDictionary<NSString *, id> *expectedParameters = @{ @"key1": @"value1", @"info": @"info", @"value": @0.0 };

    [[self.mockCleverTap expect] recordEvent:@"state_state" withProps:expectedParameters];

    [LeanplumCT advanceTo:state withInfo:info andParameters:parameters];

    [self.mockCleverTap verify];
}

- (void)testSetUserAttributes {
    NSDictionary<NSString *, id> *attributes = @{ @"key1": @"value1",
                                                 @"arr": @[ @"one", @"two", @3, [NSNull null]] };

    [[self.mockCleverTap expect] profilePush:@{ @"key1": @"value1", @"arr": @"[one,two,3]" }];
    [LeanplumCT setUserAttributes:attributes];
    [self.mockCleverTap verify];
}

- (void)testSetUserAttributesRemove {
    NSDictionary<NSString *, id> *attributes = @{ @"key1": @"value1",
                                                 @"key2": [NSNull null] };

    [[self.mockCleverTap expect] profilePush:@{ @"key1": @"value1" }];
    [[self.mockCleverTap expect] profileRemoveValueForKey:@"key2"];
    [LeanplumCT setUserAttributes:attributes];
    [self.mockCleverTap verify];
}

- (void)testSetUserAttributesWithUserId {
    NSDictionary<NSString *, id> *attributes = @{ @"key1": @"value1" };
    
    [[self.mockCleverTap expect] profilePush:@{ @"key1": @"value1" }];
    [[self.mockCleverTap expect] onUserLogin:@{ @"Identity": @"user" }];
    [LeanplumCT setUserId:@"user" withUserAttributes:attributes];
    [self.mockCleverTap verify];
}

- (void)testSetUserId {
    [[self.mockCleverTap expect] onUserLogin:@{ @"Identity": @"user" }];
    [[self.mockCleverTap reject] profilePush:[OCMArg any]];
    [LeanplumCT setUserId:@"user"];
    [self.mockCleverTap verify];
}

- (void)testSetTrafficSourceInfo {
    [[self.mockCleverTap expect] pushInstallReferrerSource:@"source" medium:@"medium" campaign:@"campaign"];
    [LeanplumCT setTrafficSourceInfo:@{
        @"publisherName": @"source",
        @"publisherSubPublisher": @"medium",
        @"publisherSubCampaign": @"campaign"
    }];
    [self.mockCleverTap verify];
}

@end

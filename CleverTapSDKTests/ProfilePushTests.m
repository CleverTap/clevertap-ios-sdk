//
//  ProfilePushTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 15/12/21.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BaseTestCase.h"
#import <OCMock/OCMock.h>
#import "CleverTap+Tests.h"

@interface ProfilePushTests : BaseTestCase

@end

@implementation ProfilePushTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)test_profile_is_pushed {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Profile Push Event"];
    
    NSString *name = @"Jane";
    NSString *email = @"jane@gmail.com";
    
    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    [self.cleverTapInstance profilePush:profile];
    
    [self getLastEvent: ^(NSDictionary* lastEvent) {
        XCTAssertNotNil(lastEvent);
        XCTAssertEqualObjects(lastEvent[@"type"], @"profile");
        
        NSDictionary *profileDetails = lastEvent[@"profile"];
        XCTAssertNotNil(profileDetails);
        XCTAssertEqualObjects(profileDetails[@"Name"], name);
        XCTAssertEqualObjects(profileDetails[@"Email"], email);
        
        NSDictionary *cachedGUIDS = [self.cleverTapInstance getCachedGUIDs];
        XCTAssertNotNil(cachedGUIDS);
        
        NSString *key = [NSString stringWithFormat:@"Email_%@", email];
        XCTAssertNotNil(cachedGUIDS[key]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void)test_profile_push_without_phone_prefix_pushes_error {
    
    NSString *name = @"Jack";
    NSString *phone = @"9876543210";
    NSDictionary *profile = @{
                              @"Name": name,
                              @"Phone": phone
                              };
    id mockInstance = [OCMockObject partialMockForObject:self.cleverTapInstance];
    [[mockInstance expect]pushValidationResults:OCMOCK_ANY];
    [mockInstance profilePush:profile];
    [mockInstance verifyWithDelay: 2];
}

- (void)test_profile_push_fails_with_empty_input {
    
    id mockInstance = [OCMockObject partialMockForObject:self.cleverTapInstance];
    [[mockInstance expect]pushValidationResults:OCMOCK_ANY];
    [mockInstance profilePush: [NSDictionary dictionary]];
    [mockInstance verifyWithDelay: 2];
}

- (void)test_onuserlogin_with_identifier_Key {
    XCTestExpectation *expectation = [self expectationWithDescription:@"On User Login Event"];
    
    NSString *name = @"Jill";
    NSString *email = @"jill@gmail.com";
    
    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    [self.cleverTapInstance onUserLogin: profile];
    
    [self getLastEvent: ^(NSDictionary* lastEvent) {
        XCTAssertNotNil(lastEvent);
        XCTAssertEqualObjects(lastEvent[@"type"], @"profile");
        
        NSDictionary *profileDetails = lastEvent[@"profile"];
        XCTAssertNotNil(profileDetails);
        XCTAssertEqualObjects(profileDetails[@"Name"], name);
        XCTAssertEqualObjects(profileDetails[@"Email"], email);
        
        NSDictionary *cachedGUIDS = [self.cleverTapInstance getCachedGUIDs];
        XCTAssertNotNil(cachedGUIDS);
        
        NSString *key = [NSString stringWithFormat:@"Email_%@", email];
        XCTAssertNotNil(cachedGUIDS[key]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void)test_onuserlogin_with_non_identifier_Key {
    XCTestExpectation *expectation = [self expectationWithDescription:@"On User Login Event"];
    
    NSString *name = @"Jill";
    
    NSDictionary *profile = @{
                              @"Name": name
                              };
    [self.cleverTapInstance onUserLogin: profile];
    
    [self getLastEvent: ^(NSDictionary* lastEvent) {
        XCTAssertNotNil(lastEvent);
        XCTAssertEqualObjects(lastEvent[@"type"], @"profile");
        
        NSDictionary *profileDetails = lastEvent[@"profile"];
        XCTAssertNotNil(profileDetails);
        XCTAssertEqualObjects(profileDetails[@"Name"], name);
        
        NSDictionary *cachedGUIDS = [self.cleverTapInstance getCachedGUIDs];
        if (cachedGUIDS) {
            NSString *key = [NSString stringWithFormat:@"Name_%@", name];
            XCTAssertNil(cachedGUIDS[key]);
        }
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}
@end

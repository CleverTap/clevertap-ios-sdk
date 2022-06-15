//
//  IdentityManagementTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 09/01/22.
//  Copyright © 2022 CleverTap. All rights reserved.
//

#import "BaseTestCase.h"
#import "CleverTap+Tests.h"
#import "CTLoginInfoProvider.h"
#import "CTDeviceInfo.h"
#import <OCMock/OCMock.h>
@interface IdentityManagementTests : BaseTestCase

@end


@implementation IdentityManagementTests

- (void)resetUserDefaults {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
}

- (void)setUp {
    [super setUp];
    [self resetUserDefaults];
    self.additionalInstance.config.identityKeys = @[@"Email"];
}

- (void)test_onuserlogin_legacy_profile_created_when_no_plist_entry {
    // GIVEN: No User logged in/ No identity Cached

    // WHEN: No plist/ Setter entry, New user logs in via OnUserLogin
    // MOCK THE PLIST DICTIONARY VALUE FOR IDENTIFIERS TO RETURN Nil
    id bundleMock = OCMPartialMock([NSBundle mainBundle].infoDictionary);
    OCMStub([bundleMock objectForKey:@"CleverTapIdentifiers"]).andReturn(nil);

    NSString *stubName = NSStringFromSelector(_cmd);
    [self stubRequestsWithName:stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    NSString *eventType = @"profile";
    NSString *name = [self randomString];
    NSString *email = [NSString stringWithFormat:@"%@@gmail.com",name];

    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    [self.cleverTapInstance onUserLogin: profile];

    [self getLastEventWithStubName:stubName eventName:nil eventType:eventType handler:^(NSDictionary* lastEvent) {

        // THEN: "New Legacy Profile Created In Cache.
        // Identity set -> Email,Identity
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

- (void)test_onuserlogin_identity_set_from_plist_keys {
    // GIVEN: No User logged in/ No identity Cached

    // WHEN: Any plist entry
    // MOCK THE PLIST DICTIONARY VALUE FOR IDENTIFIERS TO RETURN EMAIL
    id bundleMock = OCMPartialMock([NSBundle mainBundle].infoDictionary);
    OCMStub([bundleMock objectForKey:@"CleverTapIdentifiers"]).andReturn(@[@"Email"]);

    NSString *stubName = NSStringFromSelector(_cmd);
    [self stubRequestsWithName:stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    NSString *eventType = @"profile";
    NSString *name = [self randomString];
    NSString *email = [NSString stringWithFormat:@"%@@gmail.com",name];

    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    [self.cleverTapInstance onUserLogin: profile];

    [self getLastEventWithStubName:stubName eventName:nil eventType:eventType handler:^(NSDictionary* lastEvent) {

        // THEN: Identity set from plist keys
        XCTAssertNotNil(lastEvent);
        XCTAssertEqualObjects(lastEvent[@"type"], @"profile");

        NSDictionary *profileDetails = lastEvent[@"profile"];
        XCTAssertNotNil(profileDetails);
        XCTAssertEqualObjects(profileDetails[@"Name"], name);
        XCTAssertEqualObjects(profileDetails[@"Email"], email);

        NSString *cachedIdentities = [self.cleverTapInstance getCachedIdentitiesForConfig:self.cleverTapInstance.config];
        XCTAssertNotNil(cachedIdentities);

        NSArray *cachedIdentitiesArray = [cachedIdentities componentsSeparatedByString:@","];
        XCTAssertTrue([cachedIdentitiesArray containsObject: @"Email"]);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void)test_onuserlogin_legacy_profile_created_when_config_setter_entry {
    // GIVEN: No User logged in/ No identity Cached

    // WHEN: Any value Set via setter. nothing in plist. New user logs in via OnUserLogin
    // MOCK THE PLIST DICTIONARY VALUE FOR IDENTIFIERS TO RETURN Nil
    id bundleMock = OCMPartialMock([NSBundle mainBundle].infoDictionary);
    OCMStub([bundleMock objectForKey:@"CleverTapIdentifiers"]).andReturn(nil);

    NSString *stubName = NSStringFromSelector(_cmd);
    [self stubRequestsWithName:stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    NSString *eventType = @"profile";
    NSString *name = [self randomString];
    NSString *email = [NSString stringWithFormat:@"%@@gmail.com",name];

    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    self.cleverTapInstance.config.identityKeys = @[@"Email"];
    [self.cleverTapInstance onUserLogin: profile];

    [self getLastEventWithStubName:stubName eventName:nil eventType:eventType handler:^(NSDictionary* lastEvent) {

        // THEN: "New Legacy Profile Created In Cache.
        // Identity set -> Email,Identity
        // default instance only reads from plist
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

- (void)test_onuserlogin_legacy_profile_merged_no_plist_no_setter_entry {
    // GIVEN: Legacy user logged in

    CTLoginInfoProvider *loginInfoProvider = [[CTLoginInfoProvider alloc]initWithDeviceInfo:[[CTDeviceInfo alloc] initWithConfig:self.cleverTapInstance.config andCleverTapID:nil] config:self.cleverTapInstance.config];
    [loginInfoProvider cacheGUID:@"-a31a9c0c056142b7bb24941cf9c0a706" forKey:@"Email" andIdentifier:@"jack@gmail.com"];

    // WHEN: No plist/ Setter
    // New data(e.g. phone) for the logged in user via OnUserLogin
    // MOCK THE PLIST DICTIONARY VALUE FOR IDENTIFIERS TO RETURN Nil
    id bundleMock = OCMPartialMock([NSBundle mainBundle].infoDictionary);
    OCMStub([bundleMock objectForKey:@"CleverTapIdentifiers"]).andReturn(nil);

    NSString *stubName = NSStringFromSelector(_cmd);
    [self stubRequestsWithName:stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    NSString *eventType = @"profile";
    NSString *name = [self randomString];
    NSString *email = [NSString stringWithFormat:@"%@@gmail.com",name];

    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    [self.cleverTapInstance onUserLogin: profile];

    [self getLastEventWithStubName:stubName eventName:nil eventType:eventType handler:^(NSDictionary* lastEvent) {

        // Identity set -> Email,Identity
        // Merge Profile
        XCTAssertNotNil(lastEvent);
        XCTAssertEqualObjects(lastEvent[@"type"], @"profile");

        NSDictionary *profileDetails = lastEvent[@"profile"];
        XCTAssertNotNil(profileDetails);
        XCTAssertTrue([profileDetails[@"Name"]isEqualToString:name]);
        XCTAssertTrue([profileDetails[@"Email"]isEqualToString:email]);

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

- (void)test_onuserlogin_legacy_profile_merged_with_plist_entry {
    // GIVEN: Legacy user logged in

    CTLoginInfoProvider *loginInfoProvider = [[CTLoginInfoProvider alloc]initWithDeviceInfo:[[CTDeviceInfo alloc] initWithConfig:self.cleverTapInstance.config andCleverTapID:nil] config:self.cleverTapInstance.config];
    [loginInfoProvider cacheGUID:@"-a31a9c0c056142b7bb24941cf9c0a706" forKey:@"Email" andIdentifier:@"jack@gmail.com"];

    // WHEN: Any plist entry
    // New data(e.g. phone) for the logged in user via OnUserLogin
    // MOCK THE PLIST DICTIONARY VALUE FOR IDENTIFIERS TO RETURN EMAIL
    id bundleMock = OCMPartialMock([NSBundle mainBundle].infoDictionary);
    OCMStub([bundleMock objectForKey:@"CleverTapIdentifiers"]).andReturn(@[@"Email"]);

    NSString *stubName = NSStringFromSelector(_cmd);
    [self stubRequestsWithName:stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    NSString *eventType = @"profile";
    NSString *name = [self randomString];
    NSString *email = [NSString stringWithFormat:@"%@@gmail.com",name];

    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    [self.cleverTapInstance onUserLogin: profile];

    [self getLastEventWithStubName:stubName eventName:nil eventType:eventType handler:^(NSDictionary* lastEvent) {

        // Identity set -> Email,Identity
        // Merge Profile
        XCTAssertNotNil(lastEvent);
        XCTAssertEqualObjects(lastEvent[@"type"], @"profile");

        NSDictionary *profileDetails = lastEvent[@"profile"];
        XCTAssertNotNil(profileDetails);
        XCTAssertTrue([profileDetails[@"Name"]isEqualToString:name]);
        XCTAssertTrue([profileDetails[@"Email"]isEqualToString:email]);

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

- (void)test_onuserlogin_legacy_profile_merged_with_config_setter {
    // GIVEN: Legacy user logged in

    CTLoginInfoProvider *loginInfoProvider = [[CTLoginInfoProvider alloc]initWithDeviceInfo:[[CTDeviceInfo alloc] initWithConfig:self.cleverTapInstance.config andCleverTapID:nil] config:self.cleverTapInstance.config];
    [loginInfoProvider cacheGUID:@"-a31a9c0c056142b7bb24941cf9c0a706" forKey:@"Email" andIdentifier:@"jack@gmail.com"];

    // WHEN: Any value Set via setter. nothing in plist.
    // New data(e.g. phone) for the logged in user via OnUserLogin
    // MOCK THE PLIST DICTIONARY VALUE FOR IDENTIFIERS TO RETURN Nil
    id bundleMock = OCMPartialMock([NSBundle mainBundle].infoDictionary);
    OCMStub([bundleMock objectForKey:@"CleverTapIdentifiers"]).andReturn(nil);

    NSString *stubName = NSStringFromSelector(_cmd);
    [self stubRequestsWithName:stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    NSString *eventType = @"profile";
    NSString *name = [self randomString];
    NSString *email = [NSString stringWithFormat:@"%@@gmail.com",name];

    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    self.cleverTapInstance.config.identityKeys = @[@"Email"];
    [self.cleverTapInstance onUserLogin: profile];

    [self getLastEventWithStubName:stubName eventName:nil eventType:eventType handler:^(NSDictionary* lastEvent) {

        // THEN: Idenity set -> Email,Identity
        // Merge Profile
        // default instance only reads from plist
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

- (void)test_onuserlogin_legacy_profile_switched_no_plist_no_setter_entry {
    // GIVEN: Legacy user logged in

    CTLoginInfoProvider *loginInfoProvider = [[CTLoginInfoProvider alloc]initWithDeviceInfo:[[CTDeviceInfo alloc] initWithConfig:self.cleverTapInstance.config andCleverTapID:nil] config:self.cleverTapInstance.config];
    [loginInfoProvider cacheGUID:@"-a31a9c0c056142b7bb24941cf9c0a706" forKey:@"Email" andIdentifier:@"jack@gmail.com"];

    // WHEN: No plist/ Setter
    // New user logs in via OnUserLogin
    // MOCK THE PLIST DICTIONARY VALUE FOR IDENTIFIERS TO RETURN Nil
    id bundleMock = OCMPartialMock([NSBundle mainBundle].infoDictionary);
    OCMStub([bundleMock objectForKey:@"CleverTapIdentifiers"]).andReturn(nil);

    NSString *stubName = NSStringFromSelector(_cmd);
    [self stubRequestsWithName:stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    NSString *eventType = @"profile";
    NSString *name = [self randomString];
    NSString *email = [NSString stringWithFormat:@"%@@gmail.com",name];

    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    [self.cleverTapInstance onUserLogin: profile];

    [self getLastEventWithStubName:stubName eventName:nil eventType:eventType handler:^(NSDictionary* lastEvent) {

        // THEN: Switch User
        XCTAssertNotNil(lastEvent);
        XCTAssertEqualObjects(lastEvent[@"type"], @"profile");

        NSDictionary *profileDetails = lastEvent[@"profile"];
        XCTAssertNotNil(profileDetails);
        XCTAssertTrue([profileDetails[@"Name"]isEqualToString:name]);
        XCTAssertTrue([profileDetails[@"Email"]isEqualToString:email]);

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

- (void)test_onuserlogin_legacy_profile_switched_with_plist_entry {
    // GIVEN: Legacy user logged in
    
    CTLoginInfoProvider *loginInfoProvider = [[CTLoginInfoProvider alloc]initWithDeviceInfo:[[CTDeviceInfo alloc] initWithConfig:self.cleverTapInstance.config andCleverTapID:nil] config:self.cleverTapInstance.config];
    [loginInfoProvider cacheGUID:@"-a31a9c0c056142b7bb24941cf9c0a706" forKey:@"Email" andIdentifier:@"jack@gmail.com"];
    
    // WHEN: Any plist entry
    // New user logs in via OnUserLogin
    // MOCK THE PLIST DICTIONARY VALUE FOR IDENTIFIERS TO RETURN EMAIL
    id bundleMock = OCMPartialMock([NSBundle mainBundle].infoDictionary);
    OCMStub([bundleMock objectForKey:@"CleverTapIdentifiers"]).andReturn(@[@"Email"]);
    
    NSString *stubName = NSStringFromSelector(_cmd);
    [self stubRequestsWithName:stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    NSString *eventType = @"profile";
    NSString *name = [self randomString];
    NSString *email = [NSString stringWithFormat:@"%@@gmail.com",name];
    
    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    [self.cleverTapInstance onUserLogin: profile];
    
    [self getLastEventWithStubName:stubName eventName:nil eventType:eventType handler:^(NSDictionary* lastEvent) {
        
        // Switch User
        XCTAssertNotNil(lastEvent);
        XCTAssertEqualObjects(lastEvent[@"type"], @"profile");
        
        NSDictionary *profileDetails = lastEvent[@"profile"];
        XCTAssertNotNil(profileDetails);
        XCTAssertTrue([profileDetails[@"Name"]isEqualToString:name]);
        XCTAssertTrue([profileDetails[@"Email"]isEqualToString:email]);
        
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

- (void)test_onuserlogin_legacy_profile_switched_with_config_setter {
    // GIVEN: Legacy user logged in
    
    CTLoginInfoProvider *loginInfoProvider = [[CTLoginInfoProvider alloc]initWithDeviceInfo:[[CTDeviceInfo alloc] initWithConfig:self.cleverTapInstance.config andCleverTapID:nil] config:self.cleverTapInstance.config];
    [loginInfoProvider cacheGUID:@"-a31a9c0c056142b7bb24941cf9c0a706" forKey:@"Email" andIdentifier:@"jack@gmail.com"];
    
    // WHEN: Any value Set via setter. nothing in plist.
    // New user logs in via OnUserLogin
    // MOCK THE PLIST DICTIONARY VALUE FOR IDENTIFIERS TO RETURN Nil
    id bundleMock = OCMPartialMock([NSBundle mainBundle].infoDictionary);
    OCMStub([bundleMock objectForKey:@"CleverTapIdentifiers"]).andReturn(nil);
    
    NSString *stubName = NSStringFromSelector(_cmd);
    [self stubRequestsWithName:stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    NSString *eventType = @"profile";
    NSString *name = [self randomString];
    NSString *email = [NSString stringWithFormat:@"%@@gmail.com",name];
    
    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    self.cleverTapInstance.config.identityKeys = @[@"Email"];
    [self.cleverTapInstance onUserLogin: profile];
    
    [self getLastEventWithStubName:stubName eventName:nil eventType:eventType handler:^(NSDictionary* lastEvent) {
        
        // THEN: Switch User
        // default instance only reads from plist
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

- (void)test_onuserlogin_new_identity_profile_merged_with_no_change_in_plist {
    // GIVEN: New Identity Management User Logged in

    CTLoginInfoProvider *loginInfoProvider = [[CTLoginInfoProvider alloc]initWithDeviceInfo:[[CTDeviceInfo alloc] initWithConfig:self.cleverTapInstance.config andCleverTapID:nil] config:self.cleverTapInstance.config];
    [loginInfoProvider setCachedIdentities:@"Email"];
    NSString *name = [self randomString];
    NSString *email = [NSString stringWithFormat:@"%@@gmail.com",name];
    [loginInfoProvider cacheGUID:@"-a31a9c0c056142b7bb24941cf9c0a706" forKey:@"Email" andIdentifier:email];

    // WHEN: No change in plist/setter
    // New data(e.g. phone) for the logged in user via OnUserLogin
    // MOCK THE PLIST DICTIONARY VALUE FOR IDENTIFIERS TO RETURN Email
    id bundleMock = OCMPartialMock([NSBundle mainBundle].infoDictionary);
    OCMStub([bundleMock objectForKey:@"CleverTapIdentifiers"]).andReturn(@[@"Email"]);

    NSString *stubName = NSStringFromSelector(_cmd);
    [self stubRequestsWithName:stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    NSString *eventType = @"profile";

    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    self.cleverTapInstance.config.identityKeys = @[@"Email"];
    [self.cleverTapInstance onUserLogin: profile];

    [self getLastEventWithStubName:stubName eventName:nil eventType:eventType handler:^(NSDictionary* lastEvent) {

        // THEN: Merge Profile
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

- (void)test_onuserlogin_plist_changed_error_raised_to_lc {
    // GIVEN: New Identity Management User Logged in

    CTLoginInfoProvider *loginInfoProvider = [[CTLoginInfoProvider alloc]initWithDeviceInfo:[[CTDeviceInfo alloc] initWithConfig:self.cleverTapInstance.config andCleverTapID:nil] config:self.cleverTapInstance.config];
    NSString *name = [self randomString];
    NSString *email = [NSString stringWithFormat:@"%@@gmail.com",name];
    [loginInfoProvider setCachedIdentities:@"Email"];
    [loginInfoProvider cacheGUID:@"-a31a9c0c056142b7bb24941cf9c0a706" forKey:@"Email" andIdentifier:email];

    // WHEN: plist value changed
    // New data(e.g. phone) for the logged in user via OnUserLogin
    // MOCK THE PLIST DICTIONARY VALUE FOR IDENTIFIERS TO RETURN Phone
    id bundleMock = OCMPartialMock([NSBundle mainBundle].infoDictionary);
    OCMStub([bundleMock objectForKey:@"CleverTapIdentifiers"]).andReturn(@[@"Phone"]);

    NSString *stubName = NSStringFromSelector(_cmd);
    [self stubRequestsWithName:stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    NSString *eventType = @"profile";

    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    self.cleverTapInstance.config.identityKeys = @[@"Email"];
    [self.cleverTapInstance onUserLogin: profile];

    [self getLastEventWithStubName:stubName eventName:nil eventType:eventType handler:^(NSDictionary* lastEvent) {

        // THEN: Raise error to stream and use cached keys
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
        
        NSDictionary *wzrk_error = lastEvent[@"wzrk_error"];
        XCTAssertNotNil(wzrk_error);
        XCTAssertEqualObjects(wzrk_error[@"c"], @531);
        NSString *errorMessage = @"Profile Identifiers mismatch with the previously saved ones";
        XCTAssertEqualObjects(wzrk_error[@"d"], errorMessage);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void)test_profile_is_pushed {
    NSString *stubName = @"Profile Push Event";
    [self stubRequestsWithName:stubName];
    
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    
    NSString *eventType = @"profile";
    NSString *name = [self randomString];
    NSString *email = [NSString stringWithFormat:@"%@@gmail.com",name];
    
    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    [self.cleverTapInstance profilePush:profile];
    
    [self getLastEventWithStubName:stubName eventName:nil eventType:eventType handler:^(NSDictionary* lastEvent) {
        XCTAssertNotNil(lastEvent);
        XCTAssertEqualObjects(lastEvent[@"type"], eventType);
        
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
    
    NSString *stubName = @"Profile Push Event Phone Prefix";
    [self stubRequestsWithName:stubName];
    
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    
    NSString *eventType = @"profile";
    NSString *phone = @"976543210";
    
    NSDictionary *profile = @{
                            @"Phone": phone
                            };
    [self.cleverTapInstance profilePush:profile];
    
    [self getLastEventWithStubName:stubName eventName:nil eventType:eventType handler:^(NSDictionary* lastEvent) {
        XCTAssertNotNil(lastEvent);
        XCTAssertEqualObjects(lastEvent[@"type"], eventType);
        
        NSDictionary *wzrk_error = lastEvent[@"wzrk_error"];
        XCTAssertNotNil(wzrk_error);
        XCTAssertEqualObjects(wzrk_error[@"c"], @512);
        NSString *errorMessage = [NSString stringWithFormat:@"Device country code not available and profile phone: %@ does not appear to start with country code", phone];
        XCTAssertEqualObjects(wzrk_error[@"d"], errorMessage);
        
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void)test_onuserlogin_addtional_instance_legacy_profile_created_when_no_plist_entry {
    // GIVEN: No User logged in/ No identity Cached

    // WHEN: No plist/ Setter entry, New user logs in via OnUserLogin
    // MOCK THE PLIST DICTIONARY VALUE FOR IDENTIFIERS TO RETURN Nil
    id bundleMock = OCMPartialMock([NSBundle mainBundle].infoDictionary);
    OCMStub([bundleMock objectForKey:@"CleverTapIdentifiers"]).andReturn(nil);

    NSString *stubName = NSStringFromSelector(_cmd);
    [self stubRequestsWithName:stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    NSString *eventType = @"profile";
    NSString *name = [self randomString];
    NSString *email = [NSString stringWithFormat:@"%@@gmail.com",name];

    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    [self.additionalInstance onUserLogin: profile];

    [self getLastEventWithStubName:stubName eventName:nil eventType:eventType handler:^(NSDictionary* lastEvent) {

        // THEN: "New Legacy Profile Created In Cache.
        // Identity set -> Email,Identity
        XCTAssertNotNil(lastEvent);
        XCTAssertEqualObjects(lastEvent[@"type"], @"profile");

        NSDictionary *profileDetails = lastEvent[@"profile"];
        XCTAssertNotNil(profileDetails);
        XCTAssertEqualObjects(profileDetails[@"Name"], name);
        XCTAssertEqualObjects(profileDetails[@"Email"], email);

        NSDictionary *cachedGUIDS = [self.additionalInstance getCachedGUIDs];
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

- (void)test_onuserlogin_addtional_instance_legacy_profile_created_when_plist_entry {
    // GIVEN: No User logged in/ No identity Cached

    // WHEN: Any value Set via plist. New user logs in via OnUserLogin
    // MOCK THE PLIST DICTIONARY VALUE FOR IDENTIFIERS TO RETURN Nil
    id bundleMock = OCMPartialMock([NSBundle mainBundle].infoDictionary);
    OCMStub([bundleMock objectForKey:@"CleverTapIdentifiers"]).andReturn(@[@"Email"]);

    NSString *stubName = NSStringFromSelector(_cmd);
    [self stubRequestsWithName:stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    NSString *eventType = @"profile";
    NSString *name = [self randomString];
    NSString *email = [NSString stringWithFormat:@"%@@gmail.com",name];

    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    [self.additionalInstance onUserLogin: profile];

    [self getLastEventWithStubName:stubName eventName:nil eventType:eventType handler:^(NSDictionary* lastEvent) {

        // THEN: "New Legacy Profile Created In Cache.
        // Identity set -> Email,Identity
        // default instance only reads from plist
        XCTAssertNotNil(lastEvent);
        XCTAssertEqualObjects(lastEvent[@"type"], @"profile");

        NSDictionary *profileDetails = lastEvent[@"profile"];
        XCTAssertNotNil(profileDetails);
        XCTAssertEqualObjects(profileDetails[@"Name"], name);
        XCTAssertEqualObjects(profileDetails[@"Email"], email);

        NSDictionary *cachedGUIDS = [self.additionalInstance getCachedGUIDs];
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

- (void)test_onuserlogin_additional_instance_identity_set_from_config_setter {
    // GIVEN: No User logged in/ No identity Cached

    // WHEN: Any value Set via config setter
    // MOCK THE PLIST DICTIONARY VALUE FOR IDENTIFIERS TO RETURN Nil
    id bundleMock = OCMPartialMock([NSBundle mainBundle].infoDictionary);
    OCMStub([bundleMock objectForKey:@"CleverTapIdentifiers"]).andReturn(nil);

    NSString *stubName = NSStringFromSelector(_cmd);
    [self stubRequestsWithName:stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    NSString *eventType = @"profile";
    NSString *name = [self randomString];
    NSString *email = [NSString stringWithFormat:@"%@@gmail.com",name];

    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    [self.additionalInstance onUserLogin: profile];

    [self getLastEventWithStubName:stubName eventName:nil eventType:eventType handler:^(NSDictionary* lastEvent) {

        // THEN: Identity set from config setter
        XCTAssertNotNil(lastEvent);
        XCTAssertEqualObjects(lastEvent[@"type"], @"profile");

        NSDictionary *profileDetails = lastEvent[@"profile"];
        XCTAssertNotNil(profileDetails);
        XCTAssertEqualObjects(profileDetails[@"Name"], name);
        XCTAssertEqualObjects(profileDetails[@"Email"], email);

        NSString *cachedIdentities = [self.additionalInstance getCachedIdentitiesForConfig:self.additionalInstance.config];
        XCTAssertNotNil(cachedIdentities);

        NSArray *cachedIdentitiesArray = [cachedIdentities componentsSeparatedByString:@","];
        XCTAssertTrue([cachedIdentitiesArray containsObject: @"Email"]);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void)test_onuserlogin_additional_instance_profile_merged_with_no_change_in_config_setter {
    // GIVEN: New Identity Management User Logged in
    CTLoginInfoProvider *loginInfoProvider = [[CTLoginInfoProvider alloc]initWithDeviceInfo:[[CTDeviceInfo alloc] initWithConfig:self.additionalInstance.config andCleverTapID:nil] config:self.additionalInstance.config];
    [loginInfoProvider setCachedIdentities:@"Email"];
    NSString *name = [self randomString];
    NSString *email = [NSString stringWithFormat:@"%@@gmail.com",name];
    [loginInfoProvider cacheGUID:@"-a31a9c0c056142b7bb24941cf9c0a706" forKey:@"Email" andIdentifier:email];
    
    // WHEN: No change in plist/setter
    // New data(e.g. phone) for the logged in user via OnUserLogin
    // MOCK THE PLIST DICTIONARY VALUE FOR IDENTIFIERS TO RETURN Nil
    id bundleMock = OCMPartialMock([NSBundle mainBundle].infoDictionary);
    OCMStub([bundleMock objectForKey:@"CleverTapIdentifiers"]).andReturn(nil);

    NSString *stubName = NSStringFromSelector(_cmd);
    [self stubRequestsWithName:stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    NSString *eventType = @"profile";

    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    [self.additionalInstance onUserLogin: profile];

    [self getLastEventWithStubName:stubName eventName:nil eventType:eventType handler:^(NSDictionary* lastEvent) {

        // THEN: Merge Profile
        XCTAssertNotNil(lastEvent);
        XCTAssertEqualObjects(lastEvent[@"type"], @"profile");

        NSDictionary *profileDetails = lastEvent[@"profile"];
        XCTAssertNotNil(profileDetails);
        XCTAssertEqualObjects(profileDetails[@"Name"], name);
        XCTAssertEqualObjects(profileDetails[@"Email"], email);

        NSString *cachedIdentities = [self.additionalInstance getCachedIdentitiesForConfig:self.additionalInstance.config];
        XCTAssertNotNil(cachedIdentities);

        NSArray *cachedIdentitiesArray = [cachedIdentities componentsSeparatedByString:@","];
        XCTAssertTrue([cachedIdentitiesArray containsObject: @"Email"]);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void)test_onuserlogin_additional_instance_config_setter_changed_error_raised_to_lc {
    // GIVEN: New Identity Management User Logged in

    CTLoginInfoProvider *loginInfoProvider = [[CTLoginInfoProvider alloc]initWithDeviceInfo:[[CTDeviceInfo alloc] initWithConfig:self.additionalInstance.config andCleverTapID:nil] config:self.additionalInstance.config];
    NSString *name = [self randomString];
    NSString *email = [NSString stringWithFormat:@"%@@gmail.com",name];
    [loginInfoProvider setCachedIdentities:@"Email"];
    [loginInfoProvider cacheGUID:@"-a31a9c0c056142b7bb24941cf9c0a706" forKey:@"Email" andIdentifier:email];

    // WHEN: config setter value changed
    // New data(e.g. phone) for the logged in user via OnUserLogin
    // MOCK THE PLIST DICTIONARY VALUE FOR IDENTIFIERS TO RETURN Nil
    id bundleMock = OCMPartialMock([NSBundle mainBundle].infoDictionary);
    OCMStub([bundleMock objectForKey:@"CleverTapIdentifiers"]).andReturn(nil);

    NSString *stubName = NSStringFromSelector(_cmd);
    [self stubRequestsWithName:stubName];
    XCTestExpectation *expectation = [self expectationWithDescription:stubName];
    NSString *eventType = @"profile";

    NSDictionary *profile = @{
                              @"Name": name,
                              @"Email": email
                              };
    self.additionalInstance.config.identityKeys = @[@"Phone"];
    [self.additionalInstance onUserLogin: profile];

    [self getLastEventWithStubName:stubName eventName:nil eventType:eventType handler:^(NSDictionary* lastEvent) {

        // THEN: Raise error to stream and use cached keys
        XCTAssertNotNil(lastEvent);
        XCTAssertEqualObjects(lastEvent[@"type"], @"profile");

        NSDictionary *profileDetails = lastEvent[@"profile"];
        XCTAssertNotNil(profileDetails);
        XCTAssertEqualObjects(profileDetails[@"Name"], name);
        XCTAssertEqualObjects(profileDetails[@"Email"], email);

        NSDictionary *cachedGUIDS = [self.additionalInstance getCachedGUIDs];
        XCTAssertNotNil(cachedGUIDS);

        NSString *key = [NSString stringWithFormat:@"Email_%@", email];
        XCTAssertNotNil(cachedGUIDS[key]);
        
        NSDictionary *wzrk_error = lastEvent[@"wzrk_error"];
        XCTAssertNotNil(wzrk_error);
        XCTAssertEqualObjects(wzrk_error[@"c"], @531);
        NSString *errorMessage = @"Profile Identifiers mismatch with the previously saved ones";
        XCTAssertEqualObjects(wzrk_error[@"d"], errorMessage);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.5 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}
@end

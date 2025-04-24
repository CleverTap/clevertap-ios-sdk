//
//  CTInAppStoreTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 3.11.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTInAppStore.h"
#import "CTPreferences.h"
#import "CTConstants.h"
#import "CleverTapInstanceConfig.h"
#import "CTInAppStore+Tests.h"
#import "InAppHelper.h"
#import "CTEncryptionManager.h"
#import "CTMultiDelegateManager+Tests.h"

@interface CTInAppStoreTest : XCTestCase

@property (nonatomic, weak) CTInAppStore *store;
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTEncryptionManager *ctCryptManager;
@property (nonatomic, strong) NSArray *inApps;
@property (nonatomic, strong) InAppHelper *helper;

@end

@implementation CTInAppStoreTest

#pragma mark Setup
- (void)setUp {
    [super setUp];

    InAppHelper *helper = [[InAppHelper alloc] init];
    self.helper = helper;
    self.config = helper.config;
    self.store = helper.inAppStore;
    self.ctCryptManager = [[CTEncryptionManager alloc] initWithAccountID:helper.accountId];

    self.inApps = @[
        @{
            @"ti": @1698073146,
            @"wzrk_id": @"1698073146_20231024",
            @"wzrk_pivot": @"wzrk_default",
            @"priority": @1,
            @"whenTriggers": @[
                @{
                    @"eventName": @"Lina tests",
                    @"eventProperties": @[]
                }
            ],
            @"frequencyLimits": @[
                @{
                    @"type": @"days",
                    @"limit": @1,
                    @"frequency": @1
                }
            ],
            @"excludeGlobalFCaps": @0,
            @"occurrenceLimits": @[
                @{
                    @"type": @"onExactly",
                    @"limit": @2
                }
            ]
        },
        @{
            @"ti": @1698067016,
            @"wzrk_id": @"1698067016_20231024",
            @"wzrk_pivot": @"wzrk_default",
            @"priority": @1,
            @"whenTriggers": @[
                @{
                    @"eventName": @"Home Screen",
                    @"eventProperties": @[]
                }
            ],
            @"frequencyLimits": @[],
            @"excludeGlobalFCaps": @1,
            @"occurrenceLimits": @[]
        }];
}

- (void)tearDown {
    [super tearDown];
    [self.store removeClientSideInApps];
    [self.store removeServerSideInApps];
    [self.store clearInApps];
}

- (void)setClientSideInAppsPropToNil {
    // Setting to nil leads to loading from persistent storage when accessed
    self.store.clientSideInApps = nil;
}

- (void)setServerSideInAppsPropToNil {
    // Setting to nil leads to loading from persistent storage when accessed
    self.store.serverSideInApps = nil;
}

- (NSArray *)inAppsFromStorage:(NSString *)key {
    NSString *encryptedString = [CTPreferences getObjectForKey:key];
    if (encryptedString) {
        NSArray *arr = [self.ctCryptManager decryptObject:encryptedString];
        if (arr) {
            return arr;
        }
    }
    return nil;
}

- (NSString *)storageKeyInAppNotifs {
    return [self.store storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY];
}

- (NSString *)storageKeyCS {
    return [self.store storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY_CS];
}

- (NSString *)storageKeySS {
    return [self.store storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY_SS];
}

#pragma mark Tests
- (void)testStoreClientSideInApps {
    XCTAssertNil([CTPreferences getObjectForKey:[self storageKeyCS]]);
    [self.store storeClientSideInApps:self.inApps];
    XCTAssertEqualObjects([self inAppsFromStorage:[self storageKeyCS]], self.inApps);
    
    XCTAssertEqualObjects([self.store clientSideInApps], self.inApps);
    XCTAssertEqualObjects([self.store serverSideInApps], @[]);
    
    // Force load from persistent storage
    [self setClientSideInAppsPropToNil];
    XCTAssertEqualObjects([self.store clientSideInApps], self.inApps);
    
    // Update
    NSMutableArray *newInApps = [self.inApps mutableCopy];
    [newInApps addObjectsFromArray:self.inApps];
    [self.store storeClientSideInApps:newInApps];
    XCTAssertEqualObjects([self.store clientSideInApps], newInApps);
    XCTAssertEqualObjects([self inAppsFromStorage:[self storageKeyCS]], newInApps);
    
    // Force load from persistent storage
    [self setClientSideInAppsPropToNil];
    XCTAssertEqualObjects([self.store clientSideInApps], newInApps);
}

- (void)testStoreServerSideInApps {
    XCTAssertNil([CTPreferences getObjectForKey:[self storageKeySS]]);
    [self.store storeServerSideInApps:self.inApps];
    
    XCTAssertEqualObjects([self inAppsFromStorage:[self storageKeySS]], self.inApps);
    XCTAssertEqualObjects([self.store serverSideInApps], self.inApps);
    
    XCTAssertEqualObjects([self.store clientSideInApps], @[]);
    
    // Force load from persistent storage
    [self setServerSideInAppsPropToNil];
    XCTAssertEqualObjects([self.store serverSideInApps], self.inApps);
    
    // Update
    NSMutableArray *newInApps = [self.inApps mutableCopy];
    [newInApps addObjectsFromArray:self.inApps];
    [self.store storeServerSideInApps:newInApps];
    XCTAssertEqualObjects([self.store serverSideInApps], newInApps);
    XCTAssertEqualObjects([self inAppsFromStorage:[self storageKeySS]], newInApps);
    
    // Force load from persistent storage
    [self setServerSideInAppsPropToNil];
    XCTAssertEqualObjects([self.store serverSideInApps], newInApps);
}

- (void)testRemoveClientSideInApps {
    [self.store storeClientSideInApps:self.inApps];
    XCTAssertEqualObjects([self.store clientSideInApps], self.inApps);
    XCTAssertNotNil([CTPreferences getObjectForKey:[self storageKeyCS]]);
    
    [self.store removeClientSideInApps];
    XCTAssertNil([CTPreferences getObjectForKey:[self storageKeyCS]]);
    XCTAssertEqualObjects([self.store clientSideInApps], @[]);
    // Force load from persistent storage
    [self setClientSideInAppsPropToNil];
    XCTAssertEqualObjects([self.store clientSideInApps], @[]);
}

- (void)testRemoveServerSideInApps {
    [self.store storeServerSideInApps:self.inApps];
    XCTAssertNotNil([CTPreferences getObjectForKey:[self storageKeySS]]);
    XCTAssertEqualObjects([self.store serverSideInApps], self.inApps);
    
    [self.store removeServerSideInApps];
    XCTAssertNil([CTPreferences getObjectForKey:[self storageKeySS]]);
    XCTAssertEqualObjects([self.store serverSideInApps], @[]);
    // Force load from persistent storage
    [self setServerSideInAppsPropToNil];
    XCTAssertEqualObjects([self.store serverSideInApps], @[]);
}

- (void)testStoreClientSideInAppsEncrypted {
    // Store the in-apps
    [self.store storeClientSideInApps:self.inApps];
    
    // Get the stored encrypted string
    NSString *storedString = [CTPreferences getObjectForKey:[self storageKeyCS]];
    
    // Verify encryption occurred
    XCTAssertNotNil(storedString, @"Stored string should not be nil");
    XCTAssertGreaterThan(storedString.length, 0, @"Stored string should not be empty");
    
    // Decrypt the stored string and verify it matches the original inApps
    NSArray *decryptedInApps = [self.ctCryptManager decryptObject:storedString];
    XCTAssertNotNil(decryptedInApps, @"Decrypted in-apps should not be nil");
    XCTAssertEqualObjects(decryptedInApps, self.inApps, @"Decrypted in-apps should match original");
}

- (void)testStoreServerSideInAppsEncrypted {
    // Store the in-apps
    [self.store storeServerSideInApps:self.inApps];
    
    // Get the stored encrypted string
    NSString *storedString = [CTPreferences getObjectForKey:[self storageKeySS]];
    
    // Verify encryption occurred
    XCTAssertNotNil(storedString, @"Stored string should not be nil");
    XCTAssertGreaterThan(storedString.length, 0, @"Stored string should not be empty");
    
    // Decrypt the stored string and verify it matches the original inApps
    NSArray *decryptedInApps = [self.ctCryptManager decryptObject:storedString];
    XCTAssertNotNil(decryptedInApps, @"Decrypted in-apps should not be nil");
    XCTAssertEqualObjects(decryptedInApps, self.inApps, @"Decrypted in-apps should match original");
}

- (void)testStoreClientSideEmptyArray {
    [self.store storeClientSideInApps:@[]];
    XCTAssertEqualObjects([self.store clientSideInApps], @[]);
    
    [self.store storeClientSideInApps:self.inApps];
    XCTAssertEqualObjects([self.store clientSideInApps], self.inApps);
    
    [self.store storeClientSideInApps:@[]];
    XCTAssertEqualObjects([self.store clientSideInApps], @[]);
}

- (void)testStoreServerSideEmptyArray {
    [self.store storeServerSideInApps:@[]];
    XCTAssertEqualObjects([self.store serverSideInApps], @[]);
    
    [self.store storeServerSideInApps:self.inApps];
    XCTAssertEqualObjects([self.store serverSideInApps], self.inApps);
    
    [self.store storeServerSideInApps:@[]];
    XCTAssertEqualObjects([self.store serverSideInApps], @[]);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
- (void)testStoreClientSideInAppsNil {
    // Method requires non-null argument
    [self.store storeClientSideInApps:nil];
    XCTAssertEqualObjects([self.store clientSideInApps], @[]);
    
    [self.store storeClientSideInApps:self.inApps];
    XCTAssertEqualObjects([self.store clientSideInApps], self.inApps);
    
    [self.store storeClientSideInApps:nil];
    XCTAssertEqualObjects([self.store clientSideInApps], self.inApps);
}

- (void)testStoreServerSideInAppsNil {
    // Method requires non-null argument
    [self.store storeServerSideInApps:nil];
    XCTAssertEqualObjects([self.store serverSideInApps], @[]);
    
    [self.store storeServerSideInApps:self.inApps];
    XCTAssertEqualObjects([self.store serverSideInApps], self.inApps);
    
    [self.store storeServerSideInApps:nil];
    XCTAssertEqualObjects([self.store serverSideInApps], self.inApps);
}
#pragma clang diagnostic pop

- (void)testSetModeRemovesInApps {
    [self.store storeServerSideInApps:self.inApps];
    [self.store storeClientSideInApps:self.inApps];
    [self.store setMode:@"CS"];
    XCTAssertNil([CTPreferences getObjectForKey:[self storageKeySS]]);
    XCTAssertNotNil([CTPreferences getObjectForKey:[self storageKeyCS]]);
    
    [self.store storeServerSideInApps:self.inApps];
    [self.store storeClientSideInApps:self.inApps];
    [self.store setMode:@"SS"];
    XCTAssertNotNil([CTPreferences getObjectForKey:[self storageKeySS]]);
    XCTAssertNil([CTPreferences getObjectForKey:[self storageKeyCS]]);
    
    [self.store storeServerSideInApps:self.inApps];
    [self.store storeClientSideInApps:self.inApps];
    [self.store setMode:nil];
    XCTAssertNil([CTPreferences getObjectForKey:[self storageKeySS]]);
    XCTAssertNil([CTPreferences getObjectForKey:[self storageKeyCS]]);
    
    [self.store storeServerSideInApps:self.inApps];
    [self.store storeClientSideInApps:self.inApps];
    [self.store setMode:@"Invalid"];
    XCTAssertNil([CTPreferences getObjectForKey:[self storageKeySS]]);
    XCTAssertNil([CTPreferences getObjectForKey:[self storageKeyCS]]);
}

- (void)testInAppsQueue {
    NSArray *inApps = @[
        @{
            @"ti": @1
        },
        @{
            @"ti": @2
        },
        @{
            @"ti": @3
        }
    ];
    
    XCTAssertEqual([[self.store inAppsQueue] count], 0);
    XCTAssertNil([CTPreferences getObjectForKey:[self storageKeyInAppNotifs]]);
    
    [self.store enqueueInApps:inApps];
    XCTAssertEqual([[self.store inAppsQueue] count], 3);
    NSArray *inAppsFromStorage = [self inAppsFromStorage:[self storageKeyInAppNotifs]];
    XCTAssertEqual([inAppsFromStorage count], 3);
    
    NSDictionary *dequed = [self.store dequeueInApp];
    XCTAssertEqualObjects(dequed, inApps[0]);
    XCTAssertEqual([[self.store inAppsQueue] count], 2);
    
    NSDictionary *peeked = [self.store peekInApp];
    XCTAssertEqualObjects(peeked, inApps[1]);
    XCTAssertEqual([[self.store inAppsQueue] count], 2);
    
    inAppsFromStorage = [self inAppsFromStorage:[self storageKeyInAppNotifs]];
    XCTAssertEqual([inAppsFromStorage count], 2);
    
    [self.store dequeueInApp];
    [self.store dequeueInApp];
    XCTAssertEqual([[self.store inAppsQueue] count], 0);
    inAppsFromStorage = [self inAppsFromStorage:[self storageKeyInAppNotifs]];
    XCTAssertEqual([inAppsFromStorage count], 0);
}

- (void)testSwitchUserDelegateAdded {
    CTMultiDelegateManager *delegateManager = [[CTMultiDelegateManager alloc] init];
    NSUInteger count = [[delegateManager switchUserDelegates] count];
    __unused CTInAppStore *store = [[CTInAppStore alloc] initWithConfig:self.helper.config delegateManager:delegateManager deviceId:self.helper.deviceId];
    
    XCTAssertEqual([[delegateManager switchUserDelegates] count], count + 1);
}

- (void)testSwitchUser {
    NSString *firstDeviceId = self.helper.deviceId;
    NSString *secondDeviceId = [NSString stringWithFormat:@"%@_2", firstDeviceId];
    // Enqueue in-apps to first user
    [self.store enqueueInApps:self.inApps];
    // Switch to second user
    [self.store deviceIdDidChange:secondDeviceId];
    XCTAssertEqual([[self.store inAppsQueue] count], 0);
    [self.store enqueueInApps:@[self.inApps[0]]];
    XCTAssertEqual([[self.store inAppsQueue] count], 1);
    
    // Switch to first user to ensure cached in-apps for first user are loaded
    [self.store deviceIdDidChange:firstDeviceId];
    XCTAssertEqual([[self.store inAppsQueue] count], [self.inApps count]);
    
    // Switch to second user to ensure cached in-apps for second user are loaded
    [self.store deviceIdDidChange:secondDeviceId];
    XCTAssertEqual([[self.store inAppsQueue] count], 1);
    
    // Clear in-apps for the second user
    [self.store clearInApps];
    // Switch back to first user to tear down
    [self.store deviceIdDidChange:firstDeviceId];
}

- (void)testInAppsQueueMigration {
    NSArray *inApps = @[
        @{
            @"ti": @1
        },
        @{
            @"ti": @2
        },
        @{
            @"ti": @3
        }
    ];

    XCTAssertEqual([[self.store inAppsQueue] count], 0);
    NSString *oldKey = [CTPreferences storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY config: self.config];
    [CTPreferences putObject:inApps forKey:oldKey];

    [self.store migrateInAppQueueKeys];
    XCTAssertEqual([[self.store inAppsQueue] count], 3);
    NSArray *inAppsFromStorage = [self inAppsFromStorage:[self storageKeyInAppNotifs]];
    XCTAssertEqual([inAppsFromStorage count], 3);
    
    NSArray *inAppsFromStorageUsingOldKey = [CTPreferences getObjectForKey:oldKey];
    XCTAssertNil(inAppsFromStorageUsingOldKey);
}

@end

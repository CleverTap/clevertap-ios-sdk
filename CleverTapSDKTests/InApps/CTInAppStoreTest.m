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

@interface CTInAppStore(Tests)
@property (nonatomic, strong) NSArray *serverSideInApps;
@property (nonatomic, strong) NSArray *clientSideInApps;

- (void)removeClientSideInApps;
- (void)removeServerSideInApps;
@end

@interface CTInAppStoreTest : XCTestCase
@property (nonatomic, strong) CTInAppStore *store;
@property (nonatomic, strong) CTAES *ctAES;
@property (nonatomic, strong) NSArray *inApps;
@end

@implementation CTInAppStoreTest

- (void)setUp {
    [super setUp];
    self.store = [[CTInAppStore alloc] initWithAccountId:@"testAccountID" deviceId:@"testDeviceID"];
    self.ctAES = [[CTAES alloc] initWithAccountID:@"testAccountID"];
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
}

- (void)forceLoadFromPersistentStorageCS {
    self.store.clientSideInApps = nil;
}

- (void)forceLoadFromPersistentStorageSS {
    self.store.serverSideInApps = nil;
}

- (NSString *)storageKeyCS {
    return [NSString stringWithFormat:@"%@_%@_%@", @"testAccountID", @"testDeviceID", @"inapp_notifs_cs"];
}

- (NSString *)storageKeySS {
    return [NSString stringWithFormat:@"%@_%@_%@", @"testAccountID", @"testDeviceID", @"inapp_notifs_ss"];
}

- (void)testStoreClientSideInApps {
    XCTAssertNil([CTPreferences getObjectForKey:[self storageKeyCS]]);
    [self.store storeClientSideInApps:self.inApps];
    XCTAssertNotNil([CTPreferences getObjectForKey:[self storageKeyCS]]);
    
    XCTAssertEqualObjects([self.store clientSideInApps], self.inApps);
    XCTAssertEqualObjects([self.store serverSideInApps], @[]);
    
    // Force load from persistent storage
    [self forceLoadFromPersistentStorageCS];
    XCTAssertEqualObjects([self.store clientSideInApps], self.inApps);
    
    // Update again
    NSMutableArray *newInApps = [self.inApps mutableCopy];
    [newInApps addObjectsFromArray:self.inApps];
    [self.store storeClientSideInApps:newInApps];
    XCTAssertEqualObjects([self.store clientSideInApps], newInApps);
    
    // Force load again
    [self forceLoadFromPersistentStorageCS];
    XCTAssertEqualObjects([self.store clientSideInApps], newInApps);
}

- (void)testStoreServerSideInApps {
    XCTAssertNil([CTPreferences getObjectForKey:[self storageKeySS]]);
    [self.store storeServerSideInApps:self.inApps];
    XCTAssertNotNil([CTPreferences getObjectForKey:[self storageKeySS]]);
    
    XCTAssertEqualObjects([self.store serverSideInApps], self.inApps);
    XCTAssertEqualObjects([self.store clientSideInApps], @[]);
    
    // Force load from persistent storage
    [self forceLoadFromPersistentStorageSS];
    XCTAssertEqualObjects([self.store serverSideInApps], self.inApps);
    
    // Update again
    NSMutableArray *newInApps = [self.inApps mutableCopy];
    [newInApps addObjectsFromArray:self.inApps];
    [self.store storeServerSideInApps:newInApps];
    XCTAssertEqualObjects([self.store serverSideInApps], newInApps);
    
    // Force load again
    [self forceLoadFromPersistentStorageSS];
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
    [self forceLoadFromPersistentStorageCS];
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
    [self forceLoadFromPersistentStorageSS];
    XCTAssertEqualObjects([self.store serverSideInApps], @[]);
}

- (void)testStoreClientSideInAppsEncrypted {
    [self.store storeClientSideInApps:self.inApps];
    NSString *storedString = [CTPreferences getObjectForKey:[self storageKeyCS]];
    NSString *encrypted = [self.ctAES getEncryptedBase64String:self.inApps];
    XCTAssertEqualObjects(storedString, encrypted);
}

- (void)testStoreServerSideInAppsEncrypted {
    [self.store storeServerSideInApps:self.inApps];
    NSString *storedString = [CTPreferences getObjectForKey:[self storageKeySS]];
    NSString *encrypted = [self.ctAES getEncryptedBase64String:self.inApps];
    XCTAssertEqualObjects(storedString, encrypted);
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

@end

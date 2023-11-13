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

@interface CTInAppStore(Tests)
@property (nonatomic, strong) NSArray *serverSideInApps;
@property (nonatomic, strong) NSArray *clientSideInApps;

- (void)removeClientSideInApps;
- (void)removeServerSideInApps;
@end

@interface CTInAppStoreTest : XCTestCase
@property (nonatomic, strong) CTInAppStore *store;
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTAES *ctAES;
@property (nonatomic, strong) NSArray *inApps;
@end

@implementation CTInAppStoreTest

- (void)setUp {
    [super setUp];
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccountID" accountToken:@"testAccountToken"];
    self.config = config;
    self.store = [[CTInAppStore alloc] initWithConfig:config deviceId:@"testDeviceID"];
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
        NSArray *arr = [self.ctAES getDecryptedObject:encryptedString];
        if (arr) {
            return arr;
        }
    }
    return nil;
}

- (NSString *)storageKeyInAppNotifs {
    return [CTPreferences storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY config: self.config];
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

- (void)test1 {
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
    
    NSDictionary *dequed = [self.store dequeInApp];
    XCTAssertEqualObjects(dequed, inApps[0]);
    XCTAssertEqual([[self.store inAppsQueue] count], 2);
    
    NSDictionary *peeked = [self.store peekInApp];
    XCTAssertEqualObjects(peeked, inApps[1]);
    XCTAssertEqual([[self.store inAppsQueue] count], 2);
    
    inAppsFromStorage = [self inAppsFromStorage:[self storageKeyInAppNotifs]];
    XCTAssertEqual([inAppsFromStorage count], 2);

    [self.store dequeInApp];
    [self.store dequeInApp];
    XCTAssertEqual([[self.store inAppsQueue] count], 0);
    inAppsFromStorage = [self inAppsFromStorage:[self storageKeyInAppNotifs]];
    XCTAssertEqual([inAppsFromStorage count], 0);
}

@end

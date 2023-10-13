//
//  CTInAppFCManagerTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 9.10.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTInAppFCManager.h"
#import "CleverTapInstanceConfig.h"
#import "CTImpressionManager.h"
#import "CTInAppFCManager.h"

@interface CTInAppFCManagerTest : XCTestCase
@property (nonatomic, strong) CTInAppFCManager *inAppFCManager;
@end

@implementation CTInAppFCManagerTest

- (void)setUp {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"accountId" accountToken:@"accountToken"];
    CTImpressionManager *im = [[CTImpressionManager alloc] initWithAccountId:config.accountId deviceId:@"device" delegateManager:[CTDelegateManager new]];
    self.inAppFCManager = [[CTInAppFCManager alloc] initWithConfig:config delegateManager:[CTDelegateManager new] deviceId:@"device" impressionManager:im];
}

- (void)test_localInAppCount {
    int inAppCount = [self.inAppFCManager localInAppCount];
    [self.inAppFCManager incrementLocalInAppCount];

    XCTAssertEqual(inAppCount + 1, [self.inAppFCManager localInAppCount]);
}

@end

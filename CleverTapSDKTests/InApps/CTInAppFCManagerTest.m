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
#import "CTInAppTriggerManager.h"
#import "InAppHelper.h"

@interface CTInAppFCManagerTest : XCTestCase
@property (nonatomic, strong) CTInAppFCManager *inAppFCManager;
@end

@implementation CTInAppFCManagerTest

- (void)setUp {
    InAppHelper *helper = [InAppHelper new];
    self.inAppFCManager = helper.inAppFCManager;
}

- (void)test_localInAppCount {
    int inAppCount = [self.inAppFCManager localInAppCount];
    [self.inAppFCManager incrementLocalInAppCount];

    XCTAssertEqual(inAppCount + 1, [self.inAppFCManager localInAppCount]);
}

@end

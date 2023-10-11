//
//  CTInAppFCManagerTests.m
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 11/10/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTInAppFCManager.h"

@interface CTInAppFCManagerTests : XCTestCase
@property (nonatomic, strong) CTInAppFCManager *classObject;
@end

@implementation CTInAppFCManagerTests

- (void)setUp {
    self.classObject = [[CTInAppFCManager alloc] init];
}

- (void)test_getAndIncrementLocalInAppCount {
    int inAppCount = [_classObject getLocalInAppCount];
    [_classObject incrementLocalInAppCount];

    XCTAssertEqual(inAppCount + 1, [_classObject getLocalInAppCount]);
}

@end

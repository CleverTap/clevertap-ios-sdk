//
//  CTDisplayUnitControllerTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTDisplayUnitController.h"
#import "CleverTap+DisplayUnit.h"

@interface CTDisplayUnitDelegateSpy : NSObject <CTDisplayUnitDelegate>
@property (nonatomic, assign) NSUInteger updateCallCount;
@end

@implementation CTDisplayUnitDelegateSpy
- (void)displayUnitsDidUpdate {
    self.updateCallCount++;
}
@end

@interface CTDisplayUnitControllerTest : XCTestCase
@property (nonatomic, strong) CTDisplayUnitController *controller;
@property (nonatomic, strong) CTDisplayUnitDelegateSpy *delegate;
@end

@implementation CTDisplayUnitControllerTest

- (void)setUp {
    [super setUp];
    self.delegate = [[CTDisplayUnitDelegateSpy alloc] init];
    self.controller = [[CTDisplayUnitController alloc] initWithAccountId:@"dispUnitCtrlTestAcct"
                                                                    guid:@"testGuid"];
    self.controller.delegate = self.delegate;
}

- (void)tearDown {
    self.controller = nil;
    self.delegate = nil;
    [super tearDown];
}

#pragma mark - init

- (void)test_init_returnsNonNil {
    XCTAssertNotNil(self.controller);
}

- (void)test_init_isInitializedIsYes {
    XCTAssertTrue(self.controller.isInitialized);
}

- (void)test_displayUnits_beforeUpdate_isNil {
    XCTAssertNil(self.controller.displayUnits);
}

#pragma mark - updateDisplayUnits:

- (void)test_updateDisplayUnits_withTwoDicts_countIsTwo {
    NSDictionary *unit1 = @{@"wzrk_id": @"u1", @"type": @"banner"};
    NSDictionary *unit2 = @{@"wzrk_id": @"u2", @"type": @"banner"};
    NSArray *units = @[unit1, unit2];
    [self.controller updateDisplayUnits:units];
    XCTAssertEqual(self.controller.displayUnits.count, 2u);
}

- (void)test_updateDisplayUnits_emptyArray_countIsZero {
    [self.controller updateDisplayUnits:@[]];
    XCTAssertEqual(self.controller.displayUnits.count, 0u);
}

- (void)test_updateDisplayUnits_setsDisplayUnitId {
    NSDictionary *unitDict = @{@"wzrk_id": @"abc123", @"type": @"banner"};
    [self.controller updateDisplayUnits:@[unitDict]];
    CleverTapDisplayUnit *unit = self.controller.displayUnits.firstObject;
    XCTAssertEqualObjects(unit.unitID, @"abc123");
}

- (void)test_updateDisplayUnits_notifiesDelegate {
    [self.controller updateDisplayUnits:@[@{@"wzrk_id": @"u1"}]];
    XCTAssertGreaterThan(self.delegate.updateCallCount, 0u);
}

- (void)test_updateDisplayUnits_replacesPreviousUnits {
    [self.controller updateDisplayUnits:@[@{@"wzrk_id": @"u1"}]];
    NSDictionary *u2 = @{@"wzrk_id": @"u2"};
    NSDictionary *u3 = @{@"wzrk_id": @"u3"};
    NSArray *secondBatch = @[u2, u3];
    [self.controller updateDisplayUnits:secondBatch];
    XCTAssertEqual(self.controller.displayUnits.count, 2u);
}

@end

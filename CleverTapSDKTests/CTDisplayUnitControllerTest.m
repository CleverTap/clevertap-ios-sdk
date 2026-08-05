//
//  CTDisplayUnitControllerTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTDisplayUnitController.h"
#import "CleverTap+DisplayUnit.h"

@interface CTDisplayUnitDelegateSpy : NSObject <CleverTapDisplayUnitDelegate>
@property (nonatomic, assign) NSUInteger updateCallCount;
@end

@implementation CTDisplayUnitDelegateSpy
- (void)displayUnitsDidUpdate {
    self.updateCallCount++;
}
@end

@interface CTDisplayUnitControllerTest : XCTestCase
@property (nonatomic, strong) CTDisplayUnitController *controller;
@end

@implementation CTDisplayUnitControllerTest

- (void)setUp {
    [super setUp];
    self.controller = [[CTDisplayUnitController alloc] initWithAccountId:@"dispUnitCtrlTestAcct"
                                                                    guid:@"testGuid"];
}

- (void)tearDown {
    self.controller = nil;
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

- (void)test_updateDisplayUnits_withTwoUnits_countIsTwo {
    CleverTapDisplayUnit *unit1 = [[CleverTapDisplayUnit alloc] initWithJSON:@{@"wzrk_id": @"u1", @"type": @"banner"}];
    CleverTapDisplayUnit *unit2 = [[CleverTapDisplayUnit alloc] initWithJSON:@{@"wzrk_id": @"u2", @"type": @"banner"}];
    [self.controller updateDisplayUnits:@[unit1, unit2]];
    XCTAssertEqual(self.controller.displayUnits.count, 2u);
}

- (void)test_updateDisplayUnits_emptyArray_countIsZero {
    [self.controller updateDisplayUnits:@[]];
    XCTAssertEqual(self.controller.displayUnits.count, 0u);
}

- (void)test_updateDisplayUnits_nilArray_displayUnitsIsNil {
    [self.controller updateDisplayUnits:nil];
    XCTAssertNil(self.controller.displayUnits);
}

- (void)test_updateDisplayUnits_setsDisplayUnitId {
    CleverTapDisplayUnit *unit = [[CleverTapDisplayUnit alloc] initWithJSON:@{@"wzrk_id": @"abc123", @"type": @"banner"}];
    [self.controller updateDisplayUnits:@[unit]];
    XCTAssertEqualObjects(self.controller.displayUnits.firstObject.unitID, @"abc123");
}

- (void)test_updateDisplayUnits_replacesPreviousUnits {
    CleverTapDisplayUnit *u1 = [[CleverTapDisplayUnit alloc] initWithJSON:@{@"wzrk_id": @"u1"}];
    [self.controller updateDisplayUnits:@[u1]];
    CleverTapDisplayUnit *u2 = [[CleverTapDisplayUnit alloc] initWithJSON:@{@"wzrk_id": @"u2"}];
    CleverTapDisplayUnit *u3 = [[CleverTapDisplayUnit alloc] initWithJSON:@{@"wzrk_id": @"u3"}];
    [self.controller updateDisplayUnits:@[u2, u3]];
    XCTAssertEqual(self.controller.displayUnits.count, 2u);
}

@end

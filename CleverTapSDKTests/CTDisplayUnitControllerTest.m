//
//  CTDisplayUnitControllerTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTDisplayUnitController.h"
#import "CleverTap+DisplayUnit.h"
#import "CleverTap+Tests.h"
#import "BaseTestCase.h"

@interface CTDisplayUnitControllerTest : BaseTestCase
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

#pragma mark - Content fetch merge

/*
 updateDisplayUnits: replaces, which is correct for /a1 but would drop everything already
 cached if applied to a /content response — that carries only the personalized subset. The
 merge runs in CleverTap before the cache call, so a host-supplied CleverTapDisplayUnitCache
 keeps its documented replace contract.
 */

- (CleverTapDisplayUnit *)unitWithId:(NSString *)unitId type:(NSString *)type {
    return [[CleverTapDisplayUnit alloc] initWithJSON:@{ @"wzrk_id": unitId, @"type": type }];
}

- (NSArray<NSString *> *)unitIdsOf:(NSArray<CleverTapDisplayUnit *> *)units {
    NSMutableArray *ids = [NSMutableArray array];
    for (CleverTapDisplayUnit *unit in units) {
        [ids addObject:unit.unitID ?: @"<nil>"];
    }
    return ids;
}

- (void)test_mergeDisplayUnits_appendsNewUnitsAndKeepsExisting {
    CleverTap *ct = self.cleverTapInstance;
    NSArray *existing = @[[self unitWithId:@"a" type:@"banner"], [self unitWithId:@"b" type:@"banner"]];
    NSArray *incoming = @[[self unitWithId:@"c" type:@"banner"]];

    NSArray *merged = [ct mergeDisplayUnits:incoming into:existing];

    // The whole point: /a1's units must survive a content fetch response.
    XCTAssertEqualObjects([self unitIdsOf:merged], (@[@"a", @"b", @"c"]));
}

- (void)test_mergeDisplayUnits_replacesMatchingUnitInPlace {
    CleverTap *ct = self.cleverTapInstance;
    NSArray *existing = @[[self unitWithId:@"a" type:@"banner"],
                          [self unitWithId:@"b" type:@"banner"],
                          [self unitWithId:@"c" type:@"banner"]];
    NSArray *incoming = @[[self unitWithId:@"b" type:@"personalized"]];

    NSArray *merged = [ct mergeDisplayUnits:incoming into:existing];

    // Position preserved, so a personalized unit does not jump to the end of a carousel.
    XCTAssertEqualObjects([self unitIdsOf:merged], (@[@"a", @"b", @"c"]));
    XCTAssertEqualObjects(((CleverTapDisplayUnit *)merged[1]).type, @"personalized");
}

- (void)test_mergeDisplayUnits_withEmptyExisting_returnsIncoming {
    CleverTap *ct = self.cleverTapInstance;
    NSArray *incoming = @[[self unitWithId:@"a" type:@"banner"]];

    XCTAssertEqualObjects([self unitIdsOf:[ct mergeDisplayUnits:incoming into:@[]]], (@[@"a"]));
    XCTAssertEqualObjects([self unitIdsOf:[ct mergeDisplayUnits:incoming into:nil]], (@[@"a"]));
}

- (void)test_mergeDisplayUnits_mixedReplaceAndAppend {
    CleverTap *ct = self.cleverTapInstance;
    NSArray *existing = @[[self unitWithId:@"a" type:@"banner"], [self unitWithId:@"b" type:@"banner"]];
    NSArray *incoming = @[[self unitWithId:@"b" type:@"personalized"],
                          [self unitWithId:@"c" type:@"personalized"]];

    NSArray *merged = [ct mergeDisplayUnits:incoming into:existing];

    XCTAssertEqualObjects([self unitIdsOf:merged], (@[@"a", @"b", @"c"]));
    XCTAssertEqual(merged.count, 3u);
}

/*
 A payload with no wzrk_id gets the sentinel unitID "0_0" from CleverTapDisplayUnit, so several
 such units share an id and collapse to the last seen. Documenting the real behaviour rather
 than asserting an invented one — matching them by object identity instead would grow the cache
 without bound across responses.
 */
- (void)test_mergeDisplayUnits_unitsWithoutWzrkIdShareSentinelAndCollapse {
    CleverTap *ct = self.cleverTapInstance;
    CleverTapDisplayUnit *noId1 = [[CleverTapDisplayUnit alloc] initWithJSON:@{ @"type": @"banner" }];
    CleverTapDisplayUnit *noId2 = [[CleverTapDisplayUnit alloc] initWithJSON:@{ @"type": @"personalized" }];
    XCTAssertEqualObjects(noId1.unitID, @"0_0");
    XCTAssertEqualObjects(noId2.unitID, @"0_0");

    NSArray *merged = [ct mergeDisplayUnits:@[noId2] into:@[[self unitWithId:@"a" type:@"banner"], noId1]];

    XCTAssertEqual(merged.count, 2u);
    XCTAssertEqualObjects([self unitIdsOf:merged], (@[@"a", @"0_0"]));
    XCTAssertEqualObjects(((CleverTapDisplayUnit *)merged[1]).type, @"personalized",
                          @"the later unit replaces the earlier one sharing the sentinel id");
}

- (void)test_mergeDisplayUnits_repeatedMergesDoNotDuplicate {
    CleverTap *ct = self.cleverTapInstance;
    NSArray *existing = @[[self unitWithId:@"a" type:@"banner"]];
    NSArray *incoming = @[[self unitWithId:@"b" type:@"banner"]];

    NSArray *once = [ct mergeDisplayUnits:incoming into:existing];
    NSArray *twice = [ct mergeDisplayUnits:incoming into:once];

    XCTAssertEqualObjects([self unitIdsOf:twice], (@[@"a", @"b"]));
}

@end

//
//  CTInboxUtilsTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTInboxUtils.h"

@interface CTInboxUtilsTest : XCTestCase
@end

@implementation CTInboxUtilsTest

#pragma mark - inboxMessageTypeFromString:

- (void)test_inboxMessageTypeFromString_simple {
    CTInboxMessageType type = [CTInboxUtils inboxMessageTypeFromString:@"simple"];
    XCTAssertEqual(type, CTInboxMessageTypeSimple);
}

- (void)test_inboxMessageTypeFromString_messageIcon {
    CTInboxMessageType type = [CTInboxUtils inboxMessageTypeFromString:@"message-icon"];
    XCTAssertEqual(type, CTInboxMessageTypeMessageIcon);
}

- (void)test_inboxMessageTypeFromString_carousel {
    CTInboxMessageType type = [CTInboxUtils inboxMessageTypeFromString:@"carousel"];
    XCTAssertEqual(type, CTInboxMessageTypeCarousel);
}

- (void)test_inboxMessageTypeFromString_carouselImage {
    CTInboxMessageType type = [CTInboxUtils inboxMessageTypeFromString:@"carousel-image"];
    XCTAssertEqual(type, CTInboxMessageTypeCarouselImage);
}

- (void)test_inboxMessageTypeFromString_nil_returnsUnknown {
    CTInboxMessageType type = [CTInboxUtils inboxMessageTypeFromString:(NSString * _Nonnull)nil];
    XCTAssertEqual(type, CTInboxMessageTypeUnknown);
}

- (void)test_inboxMessageTypeFromString_emptyString_returnsUnknown {
    CTInboxMessageType type = [CTInboxUtils inboxMessageTypeFromString:@""];
    XCTAssertEqual(type, CTInboxMessageTypeUnknown);
}

- (void)test_inboxMessageTypeFromString_unknownString_returnsUnknown {
    CTInboxMessageType type = [CTInboxUtils inboxMessageTypeFromString:@"some-unknown-type"];
    XCTAssertEqual(type, CTInboxMessageTypeUnknown);
}

- (void)test_inboxMessageTypeFromString_caseSensitive_returnsUnknown {
    // Type map keys are lowercase; "Simple" (capitalized) is not a known key
    CTInboxMessageType type = [CTInboxUtils inboxMessageTypeFromString:@"Simple"];
    XCTAssertEqual(type, CTInboxMessageTypeUnknown);
}

#pragma mark - getXibNameForControllerName:

- (void)test_getXibNameForControllerName_containsControllerNameAndOrientationSuffix {
    NSString *controllerName = @"CTInboxSimpleMessageCell";
    NSString *xib = [CTInboxUtils getXibNameForControllerName:controllerName];
    XCTAssertNotNil(xib);
    XCTAssertTrue([xib hasPrefix:controllerName]);
    BOOL hasPortraitSuffix = [xib hasSuffix:@"~port"];
    BOOL hasLandscapeSuffix = [xib hasSuffix:@"~land"];
    XCTAssertTrue(hasPortraitSuffix || hasLandscapeSuffix);
}

@end

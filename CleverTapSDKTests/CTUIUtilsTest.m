//
//  CTUIUtilsTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTUIUtils.h"

@interface CTUIUtilsTest : XCTestCase
@end

@implementation CTUIUtilsTest

// Helper: extract RGBA components from a UIColor
- (void)getR:(CGFloat *)r g:(CGFloat *)g b:(CGFloat *)b a:(CGFloat *)a fromColor:(UIColor *)color {
    BOOL success = [color getRed:r green:g blue:b alpha:a];
    if (!success) {
        // Fallback for device-RGB colors
        *r = *g = *b = *a = 0;
    }
}

#pragma mark - ct_colorWithHexString: (no alpha param)

- (void)test_colorWithHexString_nilInput_returnsBlack {
    UIColor *color = [CTUIUtils ct_colorWithHexString:nil];
    CGFloat r, g, b, a;
    [self getR:&r g:&g b:&b a:&a fromColor:color];
    XCTAssertEqualWithAccuracy(r, 0.0, 0.001);
    XCTAssertEqualWithAccuracy(g, 0.0, 0.001);
    XCTAssertEqualWithAccuracy(b, 0.0, 0.001);
    XCTAssertEqualWithAccuracy(a, 1.0, 0.001);
}

- (void)test_colorWithHexString_emptyString_returnsBlack {
    UIColor *color = [CTUIUtils ct_colorWithHexString:@""];
    CGFloat r, g, b, a;
    [self getR:&r g:&g b:&b a:&a fromColor:color];
    XCTAssertEqualWithAccuracy(r, 0.0, 0.001);
    XCTAssertEqualWithAccuracy(g, 0.0, 0.001);
    XCTAssertEqualWithAccuracy(b, 0.0, 0.001);
    XCTAssertEqualWithAccuracy(a, 1.0, 0.001);
}

- (void)test_colorWithHexString_defaultAlphaIsOne {
    UIColor *color = [CTUIUtils ct_colorWithHexString:@"FF0000"];
    CGFloat r, g, b, a;
    [self getR:&r g:&g b:&b a:&a fromColor:color];
    XCTAssertEqualWithAccuracy(a, 1.0, 0.001);
}

#pragma mark - ct_colorWithHexString:withAlpha:

- (void)test_colorWithHexString_red_parsesCorrectly {
    UIColor *color = [CTUIUtils ct_colorWithHexString:@"FF0000" withAlpha:1.0];
    CGFloat r, g, b, a;
    [self getR:&r g:&g b:&b a:&a fromColor:color];
    XCTAssertEqualWithAccuracy(r, 1.0, 0.001);
    XCTAssertEqualWithAccuracy(g, 0.0, 0.001);
    XCTAssertEqualWithAccuracy(b, 0.0, 0.001);
}

- (void)test_colorWithHexString_green_parsesCorrectly {
    UIColor *color = [CTUIUtils ct_colorWithHexString:@"00FF00" withAlpha:1.0];
    CGFloat r, g, b, a;
    [self getR:&r g:&g b:&b a:&a fromColor:color];
    XCTAssertEqualWithAccuracy(r, 0.0, 0.001);
    XCTAssertEqualWithAccuracy(g, 1.0, 0.001);
    XCTAssertEqualWithAccuracy(b, 0.0, 0.001);
}

- (void)test_colorWithHexString_blue_parsesCorrectly {
    UIColor *color = [CTUIUtils ct_colorWithHexString:@"0000FF" withAlpha:1.0];
    CGFloat r, g, b, a;
    [self getR:&r g:&g b:&b a:&a fromColor:color];
    XCTAssertEqualWithAccuracy(r, 0.0, 0.001);
    XCTAssertEqualWithAccuracy(g, 0.0, 0.001);
    XCTAssertEqualWithAccuracy(b, 1.0, 0.001);
}

- (void)test_colorWithHexString_withHashPrefix_parsesCorrectly {
    UIColor *color = [CTUIUtils ct_colorWithHexString:@"#FF0000" withAlpha:1.0];
    CGFloat r, g, b, a;
    [self getR:&r g:&g b:&b a:&a fromColor:color];
    XCTAssertEqualWithAccuracy(r, 1.0, 0.001);
    XCTAssertEqualWithAccuracy(g, 0.0, 0.001);
    XCTAssertEqualWithAccuracy(b, 0.0, 0.001);
}

- (void)test_colorWithHexString_customAlpha_setsAlpha {
    UIColor *color = [CTUIUtils ct_colorWithHexString:@"FFFFFF" withAlpha:0.5];
    CGFloat r, g, b, a;
    [self getR:&r g:&g b:&b a:&a fromColor:color];
    XCTAssertEqualWithAccuracy(a, 0.5, 0.001);
}

- (void)test_colorWithHexString_white_parsesCorrectly {
    UIColor *color = [CTUIUtils ct_colorWithHexString:@"FFFFFF" withAlpha:1.0];
    CGFloat r, g, b, a;
    [self getR:&r g:&g b:&b a:&a fromColor:color];
    XCTAssertEqualWithAccuracy(r, 1.0, 0.001);
    XCTAssertEqualWithAccuracy(g, 1.0, 0.001);
    XCTAssertEqualWithAccuracy(b, 1.0, 0.001);
}

- (void)test_colorWithHexString_midGray_parsesCorrectly {
    // 0x80 / 255 ≈ 0.502
    UIColor *color = [CTUIUtils ct_colorWithHexString:@"808080" withAlpha:1.0];
    CGFloat r, g, b, a;
    [self getR:&r g:&g b:&b a:&a fromColor:color];
    XCTAssertEqualWithAccuracy(r, 0x80 / 255.0, 0.005);
    XCTAssertEqualWithAccuracy(g, 0x80 / 255.0, 0.005);
    XCTAssertEqualWithAccuracy(b, 0x80 / 255.0, 0.005);
}

#pragma mark - runningInsideAppExtension

- (void)test_runningInsideAppExtension_returnsFalseInTestEnvironment {
    // In a unit test host app, UIApplication.sharedApplication is available → not an extension
    XCTAssertFalse([CTUIUtils runningInsideAppExtension]);
}

@end

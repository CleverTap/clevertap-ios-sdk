//
//  CTInAppUtilsTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTInAppUtils.h"
#import "CTConstants.h"

@interface CTInAppUtilsTest : XCTestCase
@end

@implementation CTInAppUtilsTest

#pragma mark - inAppTypeString:

- (void)test_inAppTypeString_interstitialType {
    NSString *result = [CTInAppUtils inAppTypeString:CTInAppTypeInterstitial];
    XCTAssertEqualObjects(result, @"interstitial");
}

- (void)test_inAppTypeString_htmlType {
    NSString *result = [CTInAppUtils inAppTypeString:CTInAppTypeHTML];
    XCTAssertNotNil(result);
    XCTAssertGreaterThan(result.length, 0u);
}

- (void)test_inAppTypeString_customType {
    NSString *result = [CTInAppUtils inAppTypeString:CTInAppTypeCustom];
    XCTAssertEqualObjects(result, @"custom-code");
}

#pragma mark - inAppActionTypeFromString:

- (void)test_inAppActionTypeFromString_nilInput {
    CTInAppActionType result = [CTInAppUtils inAppActionTypeFromString:nil];
    XCTAssertEqual(result, CTInAppActionTypeUnknown);
}

- (void)test_inAppActionTypeFromString_unknownString {
    CTInAppActionType result = [CTInAppUtils inAppActionTypeFromString:@"not-a-valid-type"];
    XCTAssertEqual(result, CTInAppActionTypeUnknown);
}

#pragma mark - getParametersFromURL:

- (void)test_getParametersFromURL_withDeepLink {
    // URL with wzrk_c2a containing __dl__ separator
    NSString *url = @"https://example.com/page?wzrk_c2a=btn__dl__https%3A%2F%2Fexample.com%2Fdeep";
    NSMutableDictionary *result = [CTInAppUtils getParametersFromURL:url];

    XCTAssertNotNil(result[@"deeplink"]);
    NSDictionary *params = result[@"params"];
    XCTAssertEqualObjects(params[CLTAP_PROP_WZRK_CTA], @"btn");
}

- (void)test_getParametersFromURL_noQueryString {
    NSString *url = @"https://example.com/page";
    NSMutableDictionary *result = [CTInAppUtils getParametersFromURL:url];
    XCTAssertNil(result[@"params"]);
    XCTAssertNil(result[@"deeplink"]);
}

- (void)test_getParametersFromURL_multipleParams_parsesAll {
    NSString *url = @"https://example.com/page?key1=val1&key2=val2";
    NSMutableDictionary *result = [CTInAppUtils getParametersFromURL:url];
    NSDictionary *params = result[@"params"];
    XCTAssertEqualObjects(params[@"key1"], @"val1");
    XCTAssertEqualObjects(params[@"key2"], @"val2");
    XCTAssertNil(result[@"deeplink"]);
}

- (void)test_getParametersFromURL_c2aWithoutDeepLink_noDeeplink {
    // wzrk_c2a present but no __dl__ separator → no deeplink extracted
    NSString *url = @"https://example.com/page?wzrk_c2a=btnLabel";
    NSMutableDictionary *result = [CTInAppUtils getParametersFromURL:url];
    XCTAssertNil(result[@"deeplink"]);
    XCTAssertEqualObjects(result[@"params"][@"wzrk_c2a"], @"btnLabel");
}

#pragma mark - inAppTypeFromString: (not yet tested)

- (void)test_inAppTypeFromString_knownTypes_roundTrip {
    NSArray *typeStrings = @[
        @"interstitial", @"cover", @"header-template", @"footer-template",
        @"half-interstitial", @"alert-template", @"interstitial-image",
        @"half-interstitial-image", @"cover-image", @"custom-code"
    ];
    for (NSString *typeStr in typeStrings) {
        CTInAppType type = [CTInAppUtils inAppTypeFromString:typeStr];
        XCTAssertNotEqual(type, CTInAppTypeUnknown, @"Expected known type for '%@'", typeStr);
        NSString *back = [CTInAppUtils inAppTypeString:type];
        XCTAssertEqualObjects(back, typeStr, @"Round-trip failed for '%@'", typeStr);
    }
}

- (void)test_inAppTypeFromString_unknownString_returnsUnknown {
    CTInAppType type = [CTInAppUtils inAppTypeFromString:@"not-a-type"];
    XCTAssertEqual(type, CTInAppTypeUnknown);
}

- (void)test_inAppTypeFromString_nilInput_returnsUnknown {
    CTInAppType type = [CTInAppUtils inAppTypeFromString:nil];
    XCTAssertEqual(type, CTInAppTypeUnknown);
}

#pragma mark - inAppActionTypeString: / inAppActionTypeFromString: round-trips

- (void)test_inAppActionTypeFromString_close_returnsClose {
    XCTAssertEqual([CTInAppUtils inAppActionTypeFromString:@"close"], CTInAppActionTypeClose);
}

- (void)test_inAppActionTypeFromString_url_returnsOpenURL {
    XCTAssertEqual([CTInAppUtils inAppActionTypeFromString:@"url"], CTInAppActionTypeOpenURL);
}

- (void)test_inAppActionTypeFromString_kv_returnsKeyValues {
    XCTAssertEqual([CTInAppUtils inAppActionTypeFromString:@"kv"], CTInAppActionTypeKeyValues);
}

- (void)test_inAppActionTypeFromString_rfp_returnsRequestForPermission {
    XCTAssertEqual([CTInAppUtils inAppActionTypeFromString:@"rfp"], CTInAppActionTypeRequestForPermission);
}

- (void)test_inAppActionTypeString_roundTrip {
    NSArray *actionTypeStrings = @[@"close", @"url", @"kv", @"custom-code", @"rfp"];
    for (NSString *typeStr in actionTypeStrings) {
        CTInAppActionType t = [CTInAppUtils inAppActionTypeFromString:typeStr];
        NSString *back = [CTInAppUtils inAppActionTypeString:t];
        XCTAssertEqualObjects(back, typeStr, @"Round-trip failed for action type '%@'", typeStr);
    }
}

@end

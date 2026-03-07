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

@end

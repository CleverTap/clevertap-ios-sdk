//
//  CTLocalInAppTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTLocalInApp.h"
#import "CTConstants.h"

@interface CTLocalInAppTest : XCTestCase
@property (nonatomic, strong) CTLocalInApp *inApp;
@end

@implementation CTLocalInAppTest

- (CTLocalInApp *)makeAlertFollowOrientation:(BOOL)follow {
    return [[CTLocalInApp alloc] initWithInAppType:ALERT
                                        titleText:@"Title"
                                      messageText:@"Message"
                          followDeviceOrientation:follow
                                  positiveBtnText:@"Allow"
                                  negativeBtnText:@"Cancel"];
}

#pragma mark - init / type mapping

- (void)test_init_alert_setsTypeAlertTemplate {
    CTLocalInApp *a = [self makeAlertFollowOrientation:NO];
    XCTAssertEqualObjects([a getLocalInAppSettings][@"type"], @"alert-template");
}

- (void)test_init_halfInterstitial_setsTypeHalfInterstitial {
    CTLocalInApp *a = [[CTLocalInApp alloc] initWithInAppType:HALF_INTERSTITIAL
                                                    titleText:@"T"
                                                  messageText:@"M"
                                      followDeviceOrientation:NO
                                              positiveBtnText:@"Yes"
                                              negativeBtnText:@"No"];
    XCTAssertEqualObjects([a getLocalInAppSettings][@"type"], @"half-interstitial");
}

#pragma mark - required properties

- (void)test_init_setsRequiredProperties {
    CTLocalInApp *a = [self makeAlertFollowOrientation:NO];
    NSDictionary *s = [a getLocalInAppSettings];

    XCTAssertEqualObjects(s[@"wzrk_id"], @"");
    XCTAssertEqualObjects(s[@"isLocalInApp"], @1);
    XCTAssertEqualObjects(s[@"close"], @1);
    XCTAssertEqualObjects(s[@"hasPortrait"], @1);
    XCTAssertEqualObjects(s[@"bg"], @"#FFFFFF");

    XCTAssertEqualObjects(s[@"title"][@"text"], @"Title");
    XCTAssertEqualObjects(s[@"message"][@"text"], @"Message");

    NSArray *buttons = s[@"buttons"];
    XCTAssertEqual(buttons.count, 2u);
    XCTAssertEqualObjects(buttons[0][@"text"], @"Allow");
    XCTAssertEqualObjects(buttons[1][@"text"], @"Cancel");
    XCTAssertEqualObjects(buttons[0][@"radius"], @"2");
    XCTAssertEqualObjects(buttons[1][@"radius"], @"2");
    XCTAssertEqualObjects(buttons[0][@"bg"], @"#FFFFFF");
    XCTAssertEqualObjects(buttons[1][@"bg"], @"#FFFFFF");
}

- (void)test_init_followDeviceOrientation_YES_setsHasLandscape1 {
    CTLocalInApp *a = [self makeAlertFollowOrientation:YES];
    XCTAssertEqualObjects([a getLocalInAppSettings][@"hasLandscape"], @1);
}

- (void)test_init_followDeviceOrientation_NO_setsHasLandscape0 {
    CTLocalInApp *a = [self makeAlertFollowOrientation:NO];
    XCTAssertEqualObjects([a getLocalInAppSettings][@"hasLandscape"], @0);
}

#pragma mark - optional setters

- (void)test_setBackgroundColor_updatesDict {
    CTLocalInApp *a = [self makeAlertFollowOrientation:NO];
    [a setBackgroundColor:@"#000000"];
    XCTAssertEqualObjects([a getLocalInAppSettings][@"bg"], @"#000000");
}

- (void)test_setTitleTextColor_updatesDict {
    CTLocalInApp *a = [self makeAlertFollowOrientation:NO];
    [a setTitleTextColor:@"#FF0000"];
    XCTAssertEqualObjects([a getLocalInAppSettings][@"title"][@"color"], @"#FF0000");
}

- (void)test_setMessageTextColor_updatesDict {
    CTLocalInApp *a = [self makeAlertFollowOrientation:NO];
    [a setMessageTextColor:@"#00FF00"];
    XCTAssertEqualObjects([a getLocalInAppSettings][@"message"][@"color"], @"#00FF00");
}

- (void)test_setBtnBorderRadius_updatesBothButtons {
    CTLocalInApp *a = [self makeAlertFollowOrientation:NO];
    [a setBtnBorderRadius:@"8"];
    NSArray *buttons = [a getLocalInAppSettings][@"buttons"];
    XCTAssertEqualObjects(buttons[0][@"radius"], @"8");
    XCTAssertEqualObjects(buttons[1][@"radius"], @"8");
}

- (void)test_setBtnTextColor_updatesBothButtons {
    CTLocalInApp *a = [self makeAlertFollowOrientation:NO];
    [a setBtnTextColor:@"#AABBCC"];
    NSArray *buttons = [a getLocalInAppSettings][@"buttons"];
    XCTAssertEqualObjects(buttons[0][@"color"], @"#AABBCC");
    XCTAssertEqualObjects(buttons[1][@"color"], @"#AABBCC");
}

- (void)test_setBtnBorderColor_updatesBothButtons {
    CTLocalInApp *a = [self makeAlertFollowOrientation:NO];
    [a setBtnBorderColor:@"#112233"];
    NSArray *buttons = [a getLocalInAppSettings][@"buttons"];
    XCTAssertEqualObjects(buttons[0][@"border"], @"#112233");
    XCTAssertEqualObjects(buttons[1][@"border"], @"#112233");
}

- (void)test_setBtnBackgroundColor_updatesBothButtons {
    CTLocalInApp *a = [self makeAlertFollowOrientation:NO];
    [a setBtnBackgroundColor:@"#CCDDEE"];
    NSArray *buttons = [a getLocalInAppSettings][@"buttons"];
    XCTAssertEqualObjects(buttons[0][@"bg"], @"#CCDDEE");
    XCTAssertEqualObjects(buttons[1][@"bg"], @"#CCDDEE");
}

#pragma mark - setImageUrl

- (void)test_setImageUrl_setsMediaDict {
    CTLocalInApp *a = [self makeAlertFollowOrientation:NO];
    [a setImageUrl:@"https://example.com/image.png"];
    NSDictionary *media = [a getLocalInAppSettings][CLTAP_INAPP_MEDIA];
    XCTAssertNotNil(media);
    XCTAssertEqualObjects(media[CLTAP_INAPP_MEDIA_CONTENT_TYPE], @"image");
    XCTAssertEqualObjects(media[CLTAP_INAPP_MEDIA_URL], @"https://example.com/image.png");
}

- (void)test_setImageUrl_withContentDescription_setsAltText {
    CTLocalInApp *a = [self makeAlertFollowOrientation:NO];
    [a setImageUrl:@"https://example.com/img.png" contentDescription:@"A banner"];
    NSDictionary *media = [a getLocalInAppSettings][CLTAP_INAPP_MEDIA];
    XCTAssertEqualObjects(media[CLTAP_INAPP_MEDIA_CONTENT_DESCRIPTION], @"A banner");
}

- (void)test_setImageUrl_withNilContentDescription_noAltTextKey {
    CTLocalInApp *a = [self makeAlertFollowOrientation:NO];
    [a setImageUrl:@"https://example.com/img.png" contentDescription:nil];
    NSDictionary *media = [a getLocalInAppSettings][CLTAP_INAPP_MEDIA];
    XCTAssertNil(media[CLTAP_INAPP_MEDIA_CONTENT_DESCRIPTION]);
}

- (void)test_setImageUrl_followDeviceOrientation_YES_setsLandscapeMedia {
    CTLocalInApp *a = [self makeAlertFollowOrientation:YES];
    [a setImageUrl:@"https://example.com/image.png"];
    NSDictionary *s = [a getLocalInAppSettings];
    XCTAssertNotNil(s[CLTAP_INAPP_MEDIA_LANDSCAPE]);
}

- (void)test_setImageUrl_followDeviceOrientation_NO_noLandscapeMedia {
    CTLocalInApp *a = [self makeAlertFollowOrientation:NO];
    [a setImageUrl:@"https://example.com/image.png"];
    NSDictionary *s = [a getLocalInAppSettings];
    XCTAssertNil(s[CLTAP_INAPP_MEDIA_LANDSCAPE]);
}

#pragma mark - setFallbackToSettings

- (void)test_setFallbackToSettings_YES_sets1 {
    CTLocalInApp *a = [self makeAlertFollowOrientation:NO];
    [a setFallbackToSettings:YES];
    XCTAssertEqualObjects([a getLocalInAppSettings][@"fallbackToNotificationSettings"], @1);
}

- (void)test_setFallbackToSettings_NO_sets0 {
    CTLocalInApp *a = [self makeAlertFollowOrientation:NO];
    [a setFallbackToSettings:NO];
    XCTAssertEqualObjects([a getLocalInAppSettings][@"fallbackToNotificationSettings"], @0);
}

@end

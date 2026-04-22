//
//  CTInAppNotificationTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTInAppNotification.h"
#import "CTConstants.h"
#import "CTInAppUtils.h"

@interface CTInAppNotificationTest : XCTestCase
@end

@implementation CTInAppNotificationTest

#pragma mark - helpers

/// Minimal valid JSON for the non-legacy (configureFromJSON) code path.
- (NSDictionary *)coverJSON {
    return @{
        CLTAP_INAPP_ID:             @"notif_001",
        CLTAP_NOTIFICATION_ID_TAG:  @"camp_99",
        @"type":                    @"cover",
        @"bg":                      @"#FFFFFF",
        @"title":                   @{@"text": @"Hello", @"color": @"#000"},
        @"message":                 @{@"text": @"World", @"color": @"#111"},
        @"close":                   @YES,
        @"tablet":                  @NO,
        @"hasPortrait":             @YES,
        @"hasLandscape":            @YES,
        CLTAP_INAPP_MAX_PER_SESSION:    @3,
        CLTAP_INAPP_TOTAL_LIFETIME_COUNT: @10,
        CLTAP_INAPP_TOTAL_DAILY_COUNT:    @2
    };
}

#pragma mark - inAppId: (class method)

- (void)test_inAppId_nilInput_returnsNil {
    XCTAssertNil([CTInAppNotification inAppId:nil]);
}

- (void)test_inAppId_missingKey_returnsNil {
    XCTAssertNil([CTInAppNotification inAppId:@{}]);
}

- (void)test_inAppId_validKey_returnsString {
    NSDictionary *json = @{CLTAP_INAPP_ID: @"abc123"};
    XCTAssertEqualObjects([CTInAppNotification inAppId:json], @"abc123");
}

- (void)test_inAppId_numericValue_returnsStringRepresentation {
    NSDictionary *json = @{CLTAP_INAPP_ID: @42};
    XCTAssertEqualObjects([CTInAppNotification inAppId:json], @"42");
}

#pragma mark - identifiers

- (void)test_initWithJSON_setsId {
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:[self coverJSON]];
    XCTAssertEqualObjects(n.Id, @"notif_001");
}

- (void)test_initWithJSON_setsCampaignId {
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:[self coverJSON]];
    XCTAssertEqualObjects(n.campaignId, @"camp_99");
}

- (void)test_initWithJSON_storesJsonDescription {
    NSDictionary *json = [self coverJSON];
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:json];
    XCTAssertEqualObjects(n.jsonDescription, json);
}

#pragma mark - frequency caps

- (void)test_initWithJSON_setsMaxPerSession {
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:[self coverJSON]];
    XCTAssertEqual(n.maxPerSession, 3);
}

- (void)test_initWithJSON_missingMaxPerSession_defaultsToMinusOne {
    NSMutableDictionary *json = [[self coverJSON] mutableCopy];
    [json removeObjectForKey:CLTAP_INAPP_MAX_PER_SESSION];
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:json];
    XCTAssertEqual(n.maxPerSession, -1);
}

- (void)test_initWithJSON_setsTotalLifetimeCount {
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:[self coverJSON]];
    XCTAssertEqual(n.totalLifetimeCount, 10);
}

- (void)test_initWithJSON_setsTotalDailyCount {
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:[self coverJSON]];
    XCTAssertEqual(n.totalDailyCount, 2);
}

- (void)test_initWithJSON_excludeGlobalFCaps_true {
    NSMutableDictionary *json = [[self coverJSON] mutableCopy];
    json[CLTAP_INAPP_EXCLUDE_GLOBAL_CAPS] = @YES;
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:json];
    XCTAssertTrue(n.excludeFromCaps);
}

- (void)test_initWithJSON_excludeFromCaps_fallback {
    NSMutableDictionary *json = [[self coverJSON] mutableCopy];
    json[CLTAP_INAPP_EXCLUDE_FROM_CAPS] = @YES;
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:json];
    XCTAssertTrue(n.excludeFromCaps);
}

#pragma mark - boolean flags

- (void)test_initWithJSON_rfp_true {
    NSMutableDictionary *json = [[self coverJSON] mutableCopy];
    json[@"rfp"] = @YES;
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:json];
    XCTAssertTrue(n.isRequestForPushPermission);
}

- (void)test_initWithJSON_rfp_absent_isFalse {
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:[self coverJSON]];
    XCTAssertFalse(n.isRequestForPushPermission);
}

- (void)test_initWithJSON_isLocalInApp_true {
    NSMutableDictionary *json = [[self coverJSON] mutableCopy];
    json[@"isLocalInApp"] = @YES;
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:json];
    XCTAssertTrue(n.isLocalInApp);
}

- (void)test_initWithJSON_isPushSettingsSoftAlert_true {
    NSMutableDictionary *json = [[self coverJSON] mutableCopy];
    json[@"isPushSettingsSoftAlert"] = @YES;
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:json];
    XCTAssertTrue(n.isPushSettingsSoftAlert);
}

- (void)test_initWithJSON_fallbackToNotificationSettings_true {
    NSMutableDictionary *json = [[self coverJSON] mutableCopy];
    json[@"fallbackToNotificationSettings"] = @YES;
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:json];
    XCTAssertTrue(n.fallBackToNotificationSettings);
}

#pragma mark - configureFromJSON — basic fields

- (void)test_initWithJSON_setsInAppType {
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:[self coverJSON]];
    XCTAssertEqual(n.inAppType, CTInAppTypeCover);
}

- (void)test_initWithJSON_setsBackgroundColor {
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:[self coverJSON]];
    XCTAssertEqualObjects(n.backgroundColor, @"#FFFFFF");
}

- (void)test_initWithJSON_setsTitle {
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:[self coverJSON]];
    XCTAssertEqualObjects(n.title, @"Hello");
}

- (void)test_initWithJSON_setsTitleColor {
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:[self coverJSON]];
    XCTAssertEqualObjects(n.titleColor, @"#000");
}

- (void)test_initWithJSON_setsMessage {
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:[self coverJSON]];
    XCTAssertEqualObjects(n.message, @"World");
}

- (void)test_initWithJSON_setsMessageColor {
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:[self coverJSON]];
    XCTAssertEqualObjects(n.messageColor, @"#111");
}

- (void)test_initWithJSON_setsShowCloseButton {
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:[self coverJSON]];
    XCTAssertTrue(n.showCloseButton);
}

- (void)test_initWithJSON_setsHasPortrait {
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:[self coverJSON]];
    XCTAssertTrue(n.hasPortrait);
}

- (void)test_initWithJSON_setsHasLandscape {
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:[self coverJSON]];
    XCTAssertTrue(n.hasLandscape);
}

#pragma mark - configureFromJSON — media

- (void)test_initWithJSON_imageMedia_mediaIsImage {
    NSMutableDictionary *json = [[self coverJSON] mutableCopy];
    json[CLTAP_INAPP_MEDIA] = @{CLTAP_INAPP_MEDIA_URL: @"https://example.com/img.jpg", CLTAP_INAPP_MEDIA_CONTENT_TYPE: @"image/jpeg"};
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:json];
    XCTAssertTrue(n.mediaIsImage);
    XCTAssertFalse(n.mediaIsGif);
}

- (void)test_initWithJSON_gifMedia_mediaIsGif {
    NSMutableDictionary *json = [[self coverJSON] mutableCopy];
    json[CLTAP_INAPP_MEDIA] = @{CLTAP_INAPP_MEDIA_URL: @"https://example.com/a.gif", CLTAP_INAPP_MEDIA_CONTENT_TYPE: @"image/gif"};
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:json];
    XCTAssertTrue(n.mediaIsGif);
    XCTAssertFalse(n.mediaIsImage);
}

- (void)test_initWithJSON_videoMedia_mediaIsVideo {
    NSMutableDictionary *json = [[self coverJSON] mutableCopy];
    json[CLTAP_INAPP_MEDIA] = @{CLTAP_INAPP_MEDIA_URL: @"https://example.com/v.mp4", CLTAP_INAPP_MEDIA_CONTENT_TYPE: @"video/mp4"};
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:json];
    XCTAssertTrue(n.mediaIsVideo);
}

- (void)test_initWithJSON_audioMedia_mediaIsAudio {
    NSMutableDictionary *json = [[self coverJSON] mutableCopy];
    json[CLTAP_INAPP_MEDIA] = @{CLTAP_INAPP_MEDIA_URL: @"https://example.com/a.mp3", CLTAP_INAPP_MEDIA_CONTENT_TYPE: @"audio/mpeg"};
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:json];
    XCTAssertTrue(n.mediaIsAudio);
}

- (void)test_initWithJSON_imageMedia_setsImageURL {
    NSMutableDictionary *json = [[self coverJSON] mutableCopy];
    json[CLTAP_INAPP_MEDIA] = @{CLTAP_INAPP_MEDIA_URL: @"https://example.com/img.jpg", CLTAP_INAPP_MEDIA_CONTENT_TYPE: @"image/jpeg"};
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:json];
    XCTAssertEqualObjects(n.imageURL.absoluteString, @"https://example.com/img.jpg");
}

#pragma mark - configureFromJSON — buttons

- (void)test_initWithJSON_parsesButtons {
    NSMutableDictionary *json = [[self coverJSON] mutableCopy];
    json[@"buttons"] = @[
        @{@"text": @"OK",     @"actions": @{@"type": @"close", @"ios": @"", @"android": @"", @"close": @1, @"kv": @{}}},
        @{@"text": @"Go",     @"actions": @{@"type": @"url",   @"ios": @"https://example.com", @"android": @"", @"close": @1, @"kv": @{}}}
    ];
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:json];
    XCTAssertEqual(n.buttons.count, 2U);
}

- (void)test_initWithJSON_noButtons_emptyArray {
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:[self coverJSON]];
    XCTAssertEqual(n.buttons.count, 0U);
}

#pragma mark - unknown type

- (void)test_initWithJSON_unknownType_setsError {
    NSMutableDictionary *json = [[self coverJSON] mutableCopy];
    json[@"type"] = @"bogus-type";
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:json];
    XCTAssertNotNil(n.error);
}

#pragma mark - setPreparedInAppImage

- (void)test_setPreparedInAppImage_setsError {
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:[self coverJSON]];
    [n setPreparedInAppImage:nil inAppImageData:nil error:@"download failed"];
    XCTAssertEqualObjects(n.error, @"download failed");
}

- (void)test_setPreparedInAppImage_nilError_clearsError {
    CTInAppNotification *n = [[CTInAppNotification alloc] initWithJSON:[self coverJSON]];
    [n setPreparedInAppImage:nil inAppImageData:nil error:nil];
    XCTAssertNil(n.error);
}

@end

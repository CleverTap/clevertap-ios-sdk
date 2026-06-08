//
//  CleverTapDisplayUnitTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CleverTap+DisplayUnit.h"

// ─────────────────────────────────────────────────────────────
#pragma mark - CleverTapDisplayUnitContentTest
// ─────────────────────────────────────────────────────────────

@interface CleverTapDisplayUnitContentTest : XCTestCase
@end

@implementation CleverTapDisplayUnitContentTest

- (NSDictionary *)fullContentJSON {
    return @{
        @"title":   @{@"text": @"Hello", @"color": @"#FFFFFF"},
        @"message": @{@"text": @"World", @"color": @"#000000"},
        @"icon":    @{@"url": @"https://example.com/icon.png"},
        @"media":   @{@"url": @"https://example.com/img.jpg", @"content_type": @"image/jpeg", @"poster": @"https://example.com/poster.jpg"},
        @"action":  @{@"url": @{@"ios": @{@"text": @"https://example.com/action"}}}
    };
}

#pragma mark - text properties

- (void)test_initWithJSON_setsTitle {
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects(content.title, @"Hello");
}

- (void)test_initWithJSON_setsTitleColor {
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects(content.titleColor, @"#FFFFFF");
}

- (void)test_initWithJSON_setsMessage {
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects(content.message, @"World");
}

- (void)test_initWithJSON_setsMessageColor {
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects(content.messageColor, @"#000000");
}

#pragma mark - URL properties

- (void)test_initWithJSON_setsIconUrl {
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects(content.iconUrl, @"https://example.com/icon.png");
}

- (void)test_initWithJSON_setsMediaUrl {
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects(content.mediaUrl, @"https://example.com/img.jpg");
}

- (void)test_initWithJSON_setsVideoPosterUrl {
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects(content.videoPosterUrl, @"https://example.com/poster.jpg");
}

- (void)test_initWithJSON_setsActionUrl {
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects(content.actionUrl, @"https://example.com/action");
}

#pragma mark - media type flags

- (void)test_initWithJSON_imageContentType_mediaIsImage {
    NSDictionary *json = @{@"media": @{@"url": @"https://example.com/img.jpg", @"content_type": @"image/jpeg"}};
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:json];
    XCTAssertTrue(content.mediaIsImage);
    XCTAssertFalse(content.mediaIsGif);
    XCTAssertFalse(content.mediaIsVideo);
    XCTAssertFalse(content.mediaIsAudio);
}

- (void)test_initWithJSON_gifContentType_mediaIsGif {
    NSDictionary *json = @{@"media": @{@"url": @"https://example.com/anim.gif", @"content_type": @"image/gif"}};
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:json];
    XCTAssertTrue(content.mediaIsGif);
    XCTAssertFalse(content.mediaIsImage);
}

- (void)test_initWithJSON_videoContentType_mediaIsVideo {
    NSDictionary *json = @{@"media": @{@"url": @"https://example.com/vid.mp4", @"content_type": @"video/mp4"}};
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:json];
    XCTAssertTrue(content.mediaIsVideo);
    XCTAssertFalse(content.mediaIsImage);
}

- (void)test_initWithJSON_audioContentType_mediaIsAudio {
    NSDictionary *json = @{@"media": @{@"url": @"https://example.com/audio.mp3", @"content_type": @"audio/mpeg"}};
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:json];
    XCTAssertTrue(content.mediaIsAudio);
    XCTAssertFalse(content.mediaIsVideo);
}

- (void)test_initWithJSON_noMedia_allFlagsAreFalse {
    NSDictionary *json = @{@"title": @{@"text": @"Only Title"}};
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:json];
    XCTAssertFalse(content.mediaIsImage);
    XCTAssertFalse(content.mediaIsGif);
    XCTAssertFalse(content.mediaIsVideo);
    XCTAssertFalse(content.mediaIsAudio);
}

@end

// ─────────────────────────────────────────────────────────────
#pragma mark - CleverTapDisplayUnitTest
// ─────────────────────────────────────────────────────────────

@interface CleverTapDisplayUnitTest : XCTestCase
@end

@implementation CleverTapDisplayUnitTest

- (NSDictionary *)baseJSON {
    return @{
        @"wzrk_id":   @"unit_123",
        @"type":      @"banner",
        @"bg":        @"#FF0000",
        @"custom_kv": @{@"promo": @"SAVE10"},
        @"content":   @[
            @{@"title": @{@"text": @"Title1", @"color": @"#FFF"}},
            @{@"title": @{@"text": @"Title2", @"color": @"#000"}}
        ]
    };
}

#pragma mark - unitID

- (void)test_initWithJSON_setsUnitID {
    CleverTapDisplayUnit *unit = [[CleverTapDisplayUnit alloc] initWithJSON:[self baseJSON]];
    XCTAssertEqualObjects(unit.unitID, @"unit_123");
}

- (void)test_initWithJSON_withoutWzrkId_usesDefaultUnitID {
    NSDictionary *json = @{@"type": @"banner"};
    CleverTapDisplayUnit *unit = [[CleverTapDisplayUnit alloc] initWithJSON:json];
    XCTAssertEqualObjects(unit.unitID, @"0_0");
}

#pragma mark - type and bgColor

- (void)test_initWithJSON_setsType {
    CleverTapDisplayUnit *unit = [[CleverTapDisplayUnit alloc] initWithJSON:[self baseJSON]];
    XCTAssertEqualObjects(unit.type, @"banner");
}

- (void)test_initWithJSON_setsBgColor {
    CleverTapDisplayUnit *unit = [[CleverTapDisplayUnit alloc] initWithJSON:[self baseJSON]];
    XCTAssertEqualObjects(unit.bgColor, @"#FF0000");
}

#pragma mark - customExtras

- (void)test_initWithJSON_setsCustomExtras {
    CleverTapDisplayUnit *unit = [[CleverTapDisplayUnit alloc] initWithJSON:[self baseJSON]];
    XCTAssertEqualObjects(unit.customExtras[@"promo"], @"SAVE10");
}

- (void)test_initWithJSON_withoutCustomKV_customExtrasIsEmptyDict {
    NSDictionary *json = @{@"wzrk_id": @"x"};
    CleverTapDisplayUnit *unit = [[CleverTapDisplayUnit alloc] initWithJSON:json];
    XCTAssertNotNil(unit.customExtras);
    XCTAssertEqual(unit.customExtras.count, 0U);
}

#pragma mark - contents

- (void)test_initWithJSON_parsesContentCount {
    CleverTapDisplayUnit *unit = [[CleverTapDisplayUnit alloc] initWithJSON:[self baseJSON]];
    XCTAssertEqual(unit.contents.count, 2U);
}

- (void)test_initWithJSON_contentsAreDisplayUnitContentObjects {
    CleverTapDisplayUnit *unit = [[CleverTapDisplayUnit alloc] initWithJSON:[self baseJSON]];
    XCTAssertTrue([unit.contents.firstObject isKindOfClass:[CleverTapDisplayUnitContent class]]);
}

- (void)test_initWithJSON_noContent_contentsIsEmpty {
    NSDictionary *json = @{@"wzrk_id": @"x"};
    CleverTapDisplayUnit *unit = [[CleverTapDisplayUnit alloc] initWithJSON:json];
    XCTAssertEqual(unit.contents.count, 0U);
}

#pragma mark - json property

- (void)test_initWithJSON_storesOriginalJSON {
    NSDictionary *json = [self baseJSON];
    CleverTapDisplayUnit *unit = [[CleverTapDisplayUnit alloc] initWithJSON:json];
    XCTAssertEqualObjects(unit.json, json);
}

@end

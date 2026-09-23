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

#pragma mark - metaData (per-item wzrk_* attribution)

/// A `content[]` item as the BE sends it for a carousel slide: `metadata` is a
/// sibling of `action`, carrying the identity keys only.
- (NSDictionary *)contentJSONWithMetadata:(NSDictionary *)metadata iosUrl:(id)iosUrl {
    NSMutableDictionary *json = [@{
        @"title": @{@"text": @"Title1", @"color": @"#FFF"}
    } mutableCopy];
    if (iosUrl) {
        json[@"action"] = @{@"url": @{@"ios": @{@"text": iosUrl}}};
    }
    if (metadata) {
        json[@"metadata"] = metadata;
    }
    return json;
}

- (NSDictionary *)serverMetadata {
    return @{
        @"wzrk_element_id": @"1907971814",
        @"wzrk_index": @"0",
        @"wzrk_c2a": @"Title1"
    };
}

- (void)test_initWithJSON_copiesServerMetadataVerbatim {
    NSDictionary *json = [self contentJSONWithMetadata:[self serverMetadata] iosUrl:nil];
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:json];
    XCTAssertEqualObjects(content.metaData[@"wzrk_element_id"], @"1907971814");
    XCTAssertEqualObjects(content.metaData[@"wzrk_index"], @"0");
    XCTAssertEqualObjects(content.metaData[@"wzrk_c2a"], @"Title1");
}

- (void)test_initWithJSON_withIosUrl_derivesActionAndData {
    NSDictionary *json = [self contentJSONWithMetadata:[self serverMetadata]
                                                iosUrl:@"https://example.com/action"];
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:json];
    XCTAssertEqualObjects(content.metaData[@"wzrk_action"], @"url");
    XCTAssertEqualObjects(content.metaData[@"wzrk_data"], @"https://example.com/action");
}

- (void)test_initWithJSON_withoutIosUrl_omitsActionAndData {
    NSDictionary *json = [self contentJSONWithMetadata:[self serverMetadata] iosUrl:nil];
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:json];
    XCTAssertNil(content.metaData[@"wzrk_action"]);
    XCTAssertNil(content.metaData[@"wzrk_data"]);
    XCTAssertEqualObjects(content.metaData[@"wzrk_element_id"], @"1907971814");
}

- (void)test_initWithJSON_whitespaceOnlyIosUrl_omitsActionAndData {
    NSDictionary *json = [self contentJSONWithMetadata:[self serverMetadata] iosUrl:@"   "];
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:json];
    XCTAssertNil(content.metaData[@"wzrk_action"]);
    XCTAssertNil(content.metaData[@"wzrk_data"]);
}

- (void)test_initWithJSON_trimsIosUrlBeforeUsingItAsData {
    NSDictionary *json = [self contentJSONWithMetadata:[self serverMetadata]
                                                iosUrl:@"  https://example.com/action  "];
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:json];
    XCTAssertEqualObjects(content.metaData[@"wzrk_data"], @"https://example.com/action");
}

/// Pins the merge order: the server block is copied in last, so where the BE
/// sends wzrk_action / wzrk_data its values replace the SDK-derived pair.
/// Reordering the two blocks in `-initWithJSON:` must fail this test.
- (void)test_initWithJSON_serverActionAndData_overrideDerivedPair {
    NSMutableDictionary *metadata = [[self serverMetadata] mutableCopy];
    metadata[@"wzrk_action"] = @"none";
    metadata[@"wzrk_data"] = @"";
    NSDictionary *json = [self contentJSONWithMetadata:metadata
                                                iosUrl:@"https://example.com/action"];
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:json];
    XCTAssertEqualObjects(content.metaData[@"wzrk_action"], @"none");
    XCTAssertEqualObjects(content.metaData[@"wzrk_data"], @"");
}

- (void)test_initWithJSON_noMetadata_metaDataIsNil {
    NSDictionary *json = [self contentJSONWithMetadata:nil iosUrl:@"https://example.com/action"];
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:json];
    XCTAssertNil(content.metaData);
}

- (void)test_initWithJSON_emptyMetadata_metaDataIsNil {
    NSDictionary *json = [self contentJSONWithMetadata:@{} iosUrl:@"https://example.com/action"];
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:json];
    XCTAssertNil(content.metaData);
}

- (void)test_initWithJSON_metadataWrongType_metaDataIsNil {
    NSMutableDictionary *json = [[self contentJSONWithMetadata:nil iosUrl:nil] mutableCopy];
    json[@"metadata"] = @"not-a-dictionary";
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:json];
    XCTAssertNil(content.metaData);
}

/// Documents current behaviour, not desired behaviour. `action.url.ios.text` is
/// assumed to be a string; a non-string raises while deriving wzrk_data, the
/// @catch swallows it and the whole content item is lost. Update this test if a
/// type guard is ever added to -initWithJSON:.
- (void)test_initWithJSON_nonStringIosUrl_contentFailsToParse {
    NSDictionary *json = [self contentJSONWithMetadata:[self serverMetadata] iosUrl:@12345];
    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:json];
    XCTAssertNil(content);
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

#pragma mark - metaDataForContentAtIndex:

- (NSDictionary *)carouselJSON {
    return @{
        @"wzrk_id": @"unit_123",
        @"type": @"carousel",
        @"content": @[
            @{
                @"title": @{@"text": @"Title1"},
                @"action": @{@"url": @{@"ios": @{@"text": @"https://example.com/1"}}},
                @"metadata": @{@"wzrk_element_id": @"1907971814", @"wzrk_index": @"0"}
            },
            @{
                @"title": @{@"text": @"Title2"}   // image-only slide, no metadata
            }
        ]
    };
}

- (void)test_metaDataForContentAtIndex_returnsThatItemsAttribution {
    CleverTapDisplayUnit *unit = [[CleverTapDisplayUnit alloc] initWithJSON:[self carouselJSON]];
    NSDictionary *metaData = [unit metaDataForContentAtIndex:0];
    XCTAssertEqualObjects(metaData[@"wzrk_element_id"], @"1907971814");
    XCTAssertEqualObjects(metaData[@"wzrk_index"], @"0");
    XCTAssertEqualObjects(metaData[@"wzrk_data"], @"https://example.com/1");
}

- (void)test_metaDataForContentAtIndex_itemWithoutMetadata_returnsEmptyDictionary {
    CleverTapDisplayUnit *unit = [[CleverTapDisplayUnit alloc] initWithJSON:[self carouselJSON]];
    XCTAssertEqualObjects([unit metaDataForContentAtIndex:1], @{});
}

- (void)test_metaDataForContentAtIndex_indexPastEnd_returnsEmptyDictionary {
    CleverTapDisplayUnit *unit = [[CleverTapDisplayUnit alloc] initWithJSON:[self carouselJSON]];
    XCTAssertEqualObjects([unit metaDataForContentAtIndex:99], @{});
}

- (void)test_metaDataForContentAtIndex_negativeIndex_returnsEmptyDictionary {
    CleverTapDisplayUnit *unit = [[CleverTapDisplayUnit alloc] initWithJSON:[self carouselJSON]];
    XCTAssertEqualObjects([unit metaDataForContentAtIndex:-1], @{});
}

- (void)test_metaDataForContentAtIndex_unitWithNoContent_returnsEmptyDictionary {
    CleverTapDisplayUnit *unit = [[CleverTapDisplayUnit alloc] initWithJSON:@{@"wzrk_id": @"x"}];
    XCTAssertEqualObjects([unit metaDataForContentAtIndex:0], @{});
}

/// Documents current behaviour: because a malformed url makes the content item
/// nil and -initWithJSON: adds it to the list unchecked, one bad slide costs the
/// entire unit. Update this test if that is ever hardened.
- (void)test_initWithJSON_nonStringIosUrlOnASlide_unitFailsToParse {
    NSDictionary *json = @{
        @"wzrk_id": @"unit_123",
        @"content": @[
            @{
                @"title": @{@"text": @"Title1"},
                @"action": @{@"url": @{@"ios": @{@"text": @12345}}},
                @"metadata": @{@"wzrk_element_id": @"1907971814", @"wzrk_index": @"0"}
            }
        ]
    };
    CleverTapDisplayUnit *unit = [[CleverTapDisplayUnit alloc] initWithJSON:json];
    XCTAssertNil(unit);
}

@end

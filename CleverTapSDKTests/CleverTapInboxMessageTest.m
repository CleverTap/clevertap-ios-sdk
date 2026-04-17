//
//  CleverTapInboxMessageTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CleverTap+Inbox.h"

// Expose private initWithJSON: for testing
@interface CleverTapInboxMessage (Test)
- (instancetype)initWithJSON:(NSDictionary *)json;
@end

@interface CleverTapInboxMessageContent (Test)
- (instancetype)initWithJSON:(NSDictionary *)json;
@end

// ─────────────────────────────────────────────────────────────
#pragma mark - CleverTapInboxMessageContentTest
// ─────────────────────────────────────────────────────────────

@interface CleverTapInboxMessageContentTest : XCTestCase
@end

@implementation CleverTapInboxMessageContentTest

- (NSDictionary *)fullContentJSON {
    return @{
        @"title":   @{@"text": @"My Title",   @"color": @"#FFF"},
        @"message": @{@"text": @"My Message", @"color": @"#000"},
        @"icon":    @{@"url": @"https://example.com/icon.png", @"alt_text": @"Icon alt"},
        @"media":   @{
            @"url": @"https://example.com/img.jpg",
            @"alt_text": @"Media alt",
            @"poster": @"https://example.com/poster.jpg",
            @"content_type": @"image/jpeg"
        },
        @"action":  @{
            @"url": @{@"ios": @{@"text": @"https://example.com/action"}},
            @"hasUrl": @YES,
            @"hasLinks": @YES,
            @"links": @[
                @{@"type": @"url", @"url": @{@"ios": @{@"text": @"https://example.com/link1"}}},
                @{@"type": @"kv",  @"kv": @{@"promo": @"SAVE10"}}
            ]
        }
    };
}

#pragma mark - text properties

- (void)test_initWithJSON_setsTitle {
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects(c.title, @"My Title");
}

- (void)test_initWithJSON_setsTitleColor {
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects(c.titleColor, @"#FFF");
}

- (void)test_initWithJSON_setsMessage {
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects(c.message, @"My Message");
}

- (void)test_initWithJSON_setsMessageColor {
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects(c.messageColor, @"#000");
}

#pragma mark - icon and media

- (void)test_initWithJSON_setsIconUrl {
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects(c.iconUrl, @"https://example.com/icon.png");
}

- (void)test_initWithJSON_setsIconDescription {
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects(c.iconDescription, @"Icon alt");
}

- (void)test_initWithJSON_setsMediaUrl {
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects(c.mediaUrl, @"https://example.com/img.jpg");
}

- (void)test_initWithJSON_setsMediaDescription {
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects(c.mediaDescription, @"Media alt");
}

- (void)test_initWithJSON_setsVideoPosterUrl {
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects(c.videoPosterUrl, @"https://example.com/poster.jpg");
}

#pragma mark - action

- (void)test_initWithJSON_setsActionUrl {
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects(c.actionUrl, @"https://example.com/action");
}

- (void)test_initWithJSON_setsActionHasUrl {
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertTrue(c.actionHasUrl);
}

- (void)test_initWithJSON_setsActionHasLinks {
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertTrue(c.actionHasLinks);
}

#pragma mark - media type flags

- (void)test_initWithJSON_imageContentType_mediaIsImage {
    NSDictionary *json = @{@"media": @{@"url": @"https://example.com/img.jpg", @"content_type": @"image/jpeg"}};
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:json];
    XCTAssertTrue(c.mediaIsImage);
    XCTAssertFalse(c.mediaIsGif);
}

- (void)test_initWithJSON_gifContentType_mediaIsGif {
    NSDictionary *json = @{@"media": @{@"url": @"https://example.com/a.gif", @"content_type": @"image/gif"}};
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:json];
    XCTAssertTrue(c.mediaIsGif);
    XCTAssertFalse(c.mediaIsImage);
}

- (void)test_initWithJSON_videoContentType_mediaIsVideo {
    NSDictionary *json = @{@"media": @{@"url": @"https://example.com/v.mp4", @"content_type": @"video/mp4"}};
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:json];
    XCTAssertTrue(c.mediaIsVideo);
}

- (void)test_initWithJSON_audioContentType_mediaIsAudio {
    NSDictionary *json = @{@"media": @{@"url": @"https://example.com/a.mp3", @"content_type": @"audio/mpeg"}};
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:json];
    XCTAssertTrue(c.mediaIsAudio);
}

#pragma mark - links

- (void)test_initWithJSON_setsLinksCount {
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqual(c.links.count, 2U);
}

- (void)test_urlForLinkAtIndex_urlType_returnsURL {
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertEqualObjects([c urlForLinkAtIndex:0], @"https://example.com/link1");
}

- (void)test_urlForLinkAtIndex_kvType_returnsNil {
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertNil([c urlForLinkAtIndex:1]);
}

- (void)test_customDataForLinkAtIndex_kvType_returnsData {
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:[self fullContentJSON]];
    NSDictionary *kv = [c customDataForLinkAtIndex:1];
    XCTAssertEqualObjects(kv[@"promo"], @"SAVE10");
}

- (void)test_customDataForLinkAtIndex_urlType_returnsNil {
    CleverTapInboxMessageContent *c = [[CleverTapInboxMessageContent alloc] initWithJSON:[self fullContentJSON]];
    XCTAssertNil([c customDataForLinkAtIndex:0]);
}

@end

// ─────────────────────────────────────────────────────────────
#pragma mark - CleverTapInboxMessageTest
// ─────────────────────────────────────────────────────────────

@interface CleverTapInboxMessageTest : XCTestCase
@end

@implementation CleverTapInboxMessageTest

- (NSDictionary *)baseMessageJSON {
    return @{
        @"_id":      @"msg_001",
        @"wzrk_id":  @"camp_42",
        @"wzrk_ttl": @(2000000000),
        @"date":     @(1700000000),
        @"isRead":   @NO,
        @"msg": @{
            @"bg":          @"#AABBCC",
            @"orientation": @"l",
            @"type":        @"simple",
            @"tags":        @[@"sale", @"promo"],
            @"content":     @[
                @{@"title": @{@"text": @"T1", @"color": @"#FFF"}},
                @{@"title": @{@"text": @"T2", @"color": @"#000"}}
            ],
            @"custom_kv":   @[
                @{@"key": @"offer", @"value": @{@"text": @"50%"}}
            ]
        }
    };
}

#pragma mark - identifiers

- (void)test_initWithJSON_setsMessageId {
    CleverTapInboxMessage *msg = [[CleverTapInboxMessage alloc] initWithJSON:[self baseMessageJSON]];
    XCTAssertEqualObjects(msg.messageId, @"msg_001");
}

- (void)test_initWithJSON_setsCampaignId {
    CleverTapInboxMessage *msg = [[CleverTapInboxMessage alloc] initWithJSON:[self baseMessageJSON]];
    XCTAssertEqualObjects(msg.campaignId, @"camp_42");
}

#pragma mark - msg fields

- (void)test_initWithJSON_setsBackgroundColor {
    CleverTapInboxMessage *msg = [[CleverTapInboxMessage alloc] initWithJSON:[self baseMessageJSON]];
    XCTAssertEqualObjects(msg.backgroundColor, @"#AABBCC");
}

- (void)test_initWithJSON_setsOrientation {
    CleverTapInboxMessage *msg = [[CleverTapInboxMessage alloc] initWithJSON:[self baseMessageJSON]];
    XCTAssertEqualObjects(msg.orientation, @"l");
}

- (void)test_initWithJSON_setsType {
    CleverTapInboxMessage *msg = [[CleverTapInboxMessage alloc] initWithJSON:[self baseMessageJSON]];
    XCTAssertEqualObjects(msg.type, @"simple");
}

#pragma mark - tags

- (void)test_initWithJSON_setsTags {
    CleverTapInboxMessage *msg = [[CleverTapInboxMessage alloc] initWithJSON:[self baseMessageJSON]];
    XCTAssertEqualObjects(msg.tags, (@[@"sale", @"promo"]));
}

- (void)test_initWithJSON_setsTagString {
    CleverTapInboxMessage *msg = [[CleverTapInboxMessage alloc] initWithJSON:[self baseMessageJSON]];
    XCTAssertEqualObjects(msg.tagString, @"sale,promo");
}

#pragma mark - timestamps

- (void)test_initWithJSON_setsDate {
    CleverTapInboxMessage *msg = [[CleverTapInboxMessage alloc] initWithJSON:[self baseMessageJSON]];
    XCTAssertEqual(msg.date, 1700000000U);
}

- (void)test_initWithJSON_setsExpires {
    CleverTapInboxMessage *msg = [[CleverTapInboxMessage alloc] initWithJSON:[self baseMessageJSON]];
    XCTAssertEqual(msg.expires, 2000000000U);
}

- (void)test_initWithJSON_noExpires_expiresIsZero {
    NSDictionary *json = @{@"_id": @"x", @"msg": @{}};
    CleverTapInboxMessage *msg = [[CleverTapInboxMessage alloc] initWithJSON:json];
    XCTAssertEqual(msg.expires, 0U);
}

#pragma mark - isRead / setRead

- (void)test_initWithJSON_isReadFalse {
    CleverTapInboxMessage *msg = [[CleverTapInboxMessage alloc] initWithJSON:[self baseMessageJSON]];
    XCTAssertFalse(msg.isRead);
}

- (void)test_initWithJSON_isReadTrue {
    NSMutableDictionary *json = [[self baseMessageJSON] mutableCopy];
    json[@"isRead"] = @YES;
    CleverTapInboxMessage *msg = [[CleverTapInboxMessage alloc] initWithJSON:json];
    XCTAssertTrue(msg.isRead);
}

- (void)test_setRead_updatesIsRead {
    CleverTapInboxMessage *msg = [[CleverTapInboxMessage alloc] initWithJSON:[self baseMessageJSON]];
    [msg setRead:YES];
    XCTAssertTrue(msg.isRead);
}

#pragma mark - customData

- (void)test_initWithJSON_parsesCustomData {
    CleverTapInboxMessage *msg = [[CleverTapInboxMessage alloc] initWithJSON:[self baseMessageJSON]];
    XCTAssertEqualObjects(msg.customData[@"offer"], @"50%");
}

#pragma mark - content

- (void)test_initWithJSON_parsesContentCount {
    CleverTapInboxMessage *msg = [[CleverTapInboxMessage alloc] initWithJSON:[self baseMessageJSON]];
    XCTAssertEqual(msg.content.count, 2U);
}

- (void)test_initWithJSON_contentAreInboxMessageContentObjects {
    CleverTapInboxMessage *msg = [[CleverTapInboxMessage alloc] initWithJSON:[self baseMessageJSON]];
    XCTAssertTrue([msg.content.firstObject isKindOfClass:[CleverTapInboxMessageContent class]]);
}

#pragma mark - description

- (void)test_description_containsMessageId {
    CleverTapInboxMessage *msg = [[CleverTapInboxMessage alloc] initWithJSON:[self baseMessageJSON]];
    XCTAssertTrue([msg.description containsString:@"msg_001"]);
}

@end

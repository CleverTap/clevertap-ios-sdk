//
//  CTNotificationButtonTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTNotificationButton.h"
#import "CTConstants.h"

@interface CTNotificationButtonTest : XCTestCase
@end

@implementation CTNotificationButtonTest

- (NSDictionary *)openURLActionJSON {
    return @{
        @"type": @"url",
        @"ios": @"https://example.com/",
        @"android": @"",
        @"close": @1,
        @"kv": @{}
    };
}

- (NSDictionary *)kvActionJSON {
    return @{
        @"type": @"kv",
        @"ios": @"",
        @"android": @"",
        @"close": @1,
        @"kv": @{@"key": @"val"}
    };
}

#pragma mark - initWithJSON: properties

- (void)test_initWithJSON_setsTextProperties {
    NSDictionary *json = @{
        @"text": @"Click Me",
        @"color": @"#FFFFFF",
        @"radius": @"5",
        @"border": @"#000000",
        @"bg": @"#FF0000"
    };
    CTNotificationButton *button = [[CTNotificationButton alloc] initWithJSON:json];
    XCTAssertEqualObjects(button.text, @"Click Me");
    XCTAssertEqualObjects(button.textColor, @"#FFFFFF");
    XCTAssertEqualObjects(button.borderRadius, @"5");
    XCTAssertEqualObjects(button.borderColor, @"#000000");
    XCTAssertEqualObjects(button.backgroundColor, @"#FF0000");
}

- (void)test_initWithJSON_setsJsonDescription {
    NSDictionary *json = @{@"text": @"OK"};
    CTNotificationButton *button = [[CTNotificationButton alloc] initWithJSON:json];
    XCTAssertEqualObjects(button.jsonDescription, json);
}

- (void)test_initWithJSON_withoutActions_actionIsNil {
    NSDictionary *json = @{@"text": @"OK"};
    CTNotificationButton *button = [[CTNotificationButton alloc] initWithJSON:json];
    XCTAssertNil(button.action);
    XCTAssertNil(button.error);
}

#pragma mark - initWithJSON: with action

- (void)test_initWithJSON_withOpenURLAction_setsActionType {
    NSDictionary *json = @{
        @"text": @"Open",
        CLTAP_INAPP_ACTIONS: [self openURLActionJSON]
    };
    CTNotificationButton *button = [[CTNotificationButton alloc] initWithJSON:json];
    XCTAssertNotNil(button.action);
    XCTAssertEqual(button.type, CTInAppActionTypeOpenURL);
}

- (void)test_initWithJSON_withOpenURLAction_setsActionURL {
    NSDictionary *json = @{
        @"text": @"Open",
        CLTAP_INAPP_ACTIONS: [self openURLActionJSON]
    };
    CTNotificationButton *button = [[CTNotificationButton alloc] initWithJSON:json];
    XCTAssertEqualObjects(button.actionURL.absoluteString, @"https://example.com/");
}

- (void)test_initWithJSON_withKVAction_customExtras {
    NSDictionary *json = @{
        @"text": @"KV",
        CLTAP_INAPP_ACTIONS: [self kvActionJSON]
    };
    CTNotificationButton *button = [[CTNotificationButton alloc] initWithJSON:json];
    XCTAssertEqualObjects(button.customExtras[@"key"], @"val");
}

#pragma mark - delegation

- (void)test_type_delegatesToAction {
    NSDictionary *json = @{
        @"text": @"Open",
        CLTAP_INAPP_ACTIONS: [self openURLActionJSON]
    };
    CTNotificationButton *button = [[CTNotificationButton alloc] initWithJSON:json];
    XCTAssertEqual(button.type, button.action.type);
}

- (void)test_fallbackToSettings_delegatesToAction {
    NSDictionary *json = @{
        @"text": @"Open",
        CLTAP_INAPP_ACTIONS: [self openURLActionJSON]
    };
    CTNotificationButton *button = [[CTNotificationButton alloc] initWithJSON:json];
    XCTAssertEqual(button.fallbackToSettings, button.action.fallbackToSettings);
}

- (void)test_actionURL_delegatesToAction {
    NSDictionary *json = @{
        @"text": @"Open",
        CLTAP_INAPP_ACTIONS: [self openURLActionJSON]
    };
    CTNotificationButton *button = [[CTNotificationButton alloc] initWithJSON:json];
    XCTAssertEqualObjects(button.actionURL, button.action.actionURL);
}

@end

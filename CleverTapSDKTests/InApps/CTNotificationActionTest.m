//
//  CTNotificationActionTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 10.05.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTNotificationAction.h"
#import "CTNotificationButton.h"
#import "CTConstants.h"

@interface CTNotificationActionTest : XCTestCase

@end

@implementation CTNotificationActionTest

- (void)testInitWithJSONCustom {
    NSDictionary *json = @{
        @"android": @"",
        @"close": @1,
        @"ios": @"",
        @"kv": @{},
        @"templateId": @"6633c45ae2a2f07007c031a6",
        @"templateName": @"Function1",
        @"type": @"custom-code",
        @"vars": @{
            @"string": @"hello"
        }
    };
    CTNotificationAction *notificationAction = [[CTNotificationAction alloc] initWithJSON:json];
    
    XCTAssertEqual(notificationAction.type, CTInAppActionTypeCustom);
    XCTAssertEqualObjects(notificationAction.customTemplateInAppData.templateId, @"6633c45ae2a2f07007c031a6");
    XCTAssertEqualObjects(notificationAction.customTemplateInAppData.templateName, @"Function1");
    XCTAssertEqualObjects(notificationAction.customTemplateInAppData.args, (@{
        @"string" : @"hello"
    }));
}

- (void)testInitWithJSONOpenURL {
    NSDictionary *json = @{
        @"android": @"https://example.com/",
        @"close": @1,
        @"ios": @"https://example.com/",
        @"kv": @{},
        @"type": @"url"
    };
    CTNotificationAction *notificationAction = [[CTNotificationAction alloc] initWithJSON:json];
    
    XCTAssertEqual(notificationAction.type, CTInAppActionTypeOpenURL);
    XCTAssertTrue([notificationAction.actionURL.absoluteString isEqualToString:@"https://example.com/"]);
    XCTAssertNil(notificationAction.customTemplateInAppData);
}

- (void)testInitWithJSONKV {
    NSDictionary *json = @{
        @"android": @"",
        @"close": @1,
        @"ios": @"",
        @"kv": @{
            @"key": @"value"
        },
        @"type": @"kv"
    };
    CTNotificationAction *notificationAction = [[CTNotificationAction alloc] initWithJSON:json];
    
    XCTAssertEqual(notificationAction.type, CTInAppActionTypeKeyValues);
    XCTAssertNil(notificationAction.customTemplateInAppData);
    XCTAssertEqualObjects(notificationAction.keyValues, (@{
        @"key" : @"value"
    }));
}

- (void)testInitWithJSONClose {
    NSDictionary *json = @{
        @"android": @"",
        @"close": @1,
        @"ios": @"",
        @"kv": @{},
        @"type": @"close"
    };
    CTNotificationAction *notificationAction = [[CTNotificationAction alloc] initWithJSON:json];
    
    XCTAssertEqual(notificationAction.type, CTInAppActionTypeClose);
}

- (void)testInitWithJSONRFP {
    NSDictionary *json = @{
        @"android": @"",
        @"close": @1,
        @"ios": @"",
        @"kv": @{},
        @"fbSettings": @1,
        @"type": @"rfp"
    };
    CTNotificationAction *notificationAction = [[CTNotificationAction alloc] initWithJSON:json];
    
    XCTAssertEqual(notificationAction.type, CTInAppActionTypeRequestForPermission);
    XCTAssertEqual(notificationAction.fallbackToSettings, YES);
}

- (void)testInitWithNotificationButton {
    NSDictionary *json = @{
        @"actions": @{
            @"android": @"",
            @"close": @1,
            @"ios": @"https://example.com/",
            @"kv": @{
                @"key": @"value"
            },
            @"type": @"url",
            @"fbSettings": @1
        }
    };
    CTNotificationButton *notificationButton = [[CTNotificationButton alloc] initWithJSON:json];

    XCTAssertNotNil(notificationButton.action);
    XCTAssertEqual(notificationButton.type, CTInAppActionTypeOpenURL);
    XCTAssertTrue([notificationButton.actionURL.absoluteString isEqualToString:@"https://example.com/"]);
    XCTAssertEqual(notificationButton.fallbackToSettings, YES);
    XCTAssertEqualObjects(notificationButton.customExtras, (@{
        @"key" : @"value"
    }));
}

- (void)testInitWithOpenURL {
    NSURL *url = [[NSURL alloc] initWithString:@"https://example.com/"];
    CTNotificationAction *notificationAction = [[CTNotificationAction alloc] initWithOpenURL:url];
    
    XCTAssertEqual(notificationAction.type, CTInAppActionTypeOpenURL);
    XCTAssertEqualObjects(notificationAction.actionURL, url);
}

@end

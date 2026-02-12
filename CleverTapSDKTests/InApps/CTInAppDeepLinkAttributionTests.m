//
//  CTInAppDeepLinkAttributionTests.m
//  CleverTapSDKTests
//
//  Created by CleverTap on 12/02/26.
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTInAppNotification.h"
#import "CTNotificationButton.h"
#import "CTNotificationAction.h"
#import "CTEventBuilder.h"
#import "CTConstants.h"

@interface CTInAppDeepLinkAttributionTests : XCTestCase

@end

@implementation CTInAppDeepLinkAttributionTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - Event Builder Tests

- (void)testEventBuilderIncludesWzrkDLWhenPresentInParams {
    // Given: A notification and params with wzrk_dl
    NSDictionary *inAppJSON = @{
        @"ti": @"test_campaign_123",
        @"wzrk_id": @"test_campaign_123"
    };
    CTInAppNotification *notification = [[CTInAppNotification alloc] initWithJSON:inAppJSON];

    NSString *deepLink = @"https://example.com/promo";
    NSString *ctaText = @"Shop Now";
    NSDictionary *params = @{
        CLTAP_PROP_WZRK_CTA: ctaText,
        CLTAP_PROP_WZRK_DL: deepLink
    };

    XCTestExpectation *expectation = [self expectationWithDescription:@"Event built with wzrk_dl"];

    // When: Building click event with deep link
    [CTEventBuilder buildInAppNotificationStateEvent:YES
                                     forNotification:notification
                                  andQueryParameters:params
                                   completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        // Then: Event should include wzrk_dl
        XCTAssertNotNil(event, @"Event should not be nil");
        NSDictionary *eventData = event[CLTAP_EVENT_DATA];
        XCTAssertNotNil(eventData, @"Event data should not be nil");

        XCTAssertEqualObjects(eventData[CLTAP_PROP_WZRK_DL], deepLink, @"wzrk_dl should match the deep link");
        XCTAssertEqualObjects(eventData[CLTAP_PROP_WZRK_CTA], ctaText, @"wzrk_c2a should still be present");

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testEventBuilderExcludesWzrkDLWhenNotPresent {
    // Given: A notification and params without wzrk_dl
    NSDictionary *inAppJSON = @{
        @"ti": @"test_campaign_456",
        @"wzrk_id": @"test_campaign_456"
    };
    CTInAppNotification *notification = [[CTInAppNotification alloc] initWithJSON:inAppJSON];

    NSDictionary *params = @{
        CLTAP_PROP_WZRK_CTA: @"Close"
    };

    XCTestExpectation *expectation = [self expectationWithDescription:@"Event built without wzrk_dl"];

    // When: Building click event without deep link
    [CTEventBuilder buildInAppNotificationStateEvent:YES
                                     forNotification:notification
                                  andQueryParameters:params
                                   completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        // Then: Event should not include wzrk_dl
        XCTAssertNotNil(event, @"Event should not be nil");
        NSDictionary *eventData = event[CLTAP_EVENT_DATA];
        XCTAssertNotNil(eventData, @"Event data should not be nil");

        XCTAssertNil(eventData[CLTAP_PROP_WZRK_DL], @"wzrk_dl should not be present");
        XCTAssertEqualObjects(eventData[CLTAP_PROP_WZRK_CTA], @"Close", @"wzrk_c2a should be present");

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testEventBuilderWithEmptyDeepLinkString {
    // Given: A notification and params with empty wzrk_dl
    NSDictionary *inAppJSON = @{
        @"ti": @"test_campaign_789",
        @"wzrk_id": @"test_campaign_789"
    };
    CTInAppNotification *notification = [[CTInAppNotification alloc] initWithJSON:inAppJSON];

    NSDictionary *params = @{
        CLTAP_PROP_WZRK_CTA: @"Dismiss",
        CLTAP_PROP_WZRK_DL: @"" // Empty string
    };

    XCTestExpectation *expectation = [self expectationWithDescription:@"Event built with empty wzrk_dl"];

    // When: Building click event with empty deep link
    [CTEventBuilder buildInAppNotificationStateEvent:YES
                                     forNotification:notification
                                  andQueryParameters:params
                                   completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        // Then: Event should include wzrk_dl as empty string (but ideally calling code should not pass empty strings)
        XCTAssertNotNil(event, @"Event should not be nil");
        NSDictionary *eventData = event[CLTAP_EVENT_DATA];
        XCTAssertNotNil(eventData, @"Event data should not be nil");

        // The event builder doesn't filter empty strings, so it will be present
        // The calling code should handle not passing empty wzrk_dl
        XCTAssertEqualObjects(eventData[CLTAP_PROP_WZRK_DL], @"", @"wzrk_dl should be empty string");

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

#pragma mark - Button Action Tests

- (void)testNotificationButtonWithDeepLink {
    // Given: A notification button with a deep link action
    NSURL *deepLinkURL = [NSURL URLWithString:@"myapp://product/123"];
    CTNotificationAction *action = [[CTNotificationAction alloc] initWithOpenURL:deepLinkURL];

    CTNotificationButton *button = [[CTNotificationButton alloc] init];
    button.text = @"View Product";
    button.action = action;

    // Then: Button should have accessible action URL
    XCTAssertNotNil(button.action, @"Button action should not be nil");
    XCTAssertNotNil(button.action.actionURL, @"Action URL should not be nil");
    XCTAssertEqualObjects(button.action.actionURL.absoluteString, @"myapp://product/123", @"Deep link should match");
}

- (void)testNotificationButtonWithHTTPDeepLink {
    // Given: A notification button with HTTP deep link
    NSURL *deepLinkURL = [NSURL URLWithString:@"https://shop.example.com/sale?utm_source=inapp&user_id=12345"];
    CTNotificationAction *action = [[CTNotificationAction alloc] initWithOpenURL:deepLinkURL];

    CTNotificationButton *button = [[CTNotificationButton alloc] init];
    button.text = @"Shop Sale";
    button.action = action;

    // Then: Button should preserve full URL with query parameters
    XCTAssertNotNil(button.action.actionURL, @"Action URL should not be nil");
    XCTAssertTrue([button.action.actionURL.absoluteString containsString:@"utm_source=inapp"],
                  @"Deep link should preserve query parameters");
    XCTAssertTrue([button.action.actionURL.absoluteString containsString:@"user_id=12345"],
                  @"Deep link should preserve personalization parameters");
}

- (void)testNotificationButtonWithoutDeepLink {
    // Given: A notification button with close action (no URL)
    CTNotificationAction *action = [[CTNotificationAction alloc] init];
    action.type = CTInAppActionTypeClose;

    CTNotificationButton *button = [[CTNotificationButton alloc] init];
    button.text = @"Close";
    button.action = action;

    // Then: Button should have nil action URL
    XCTAssertNil(button.action.actionURL, @"Action URL should be nil for close actions");
}

#pragma mark - Multi-CTA Tests

- (void)testMultipleCTAButtonsWithDifferentDeepLinks {
    // Given: Multiple buttons with different deep links
    NSURL *deepLink1 = [NSURL URLWithString:@"https://example.com/page1"];
    NSURL *deepLink2 = [NSURL URLWithString:@"https://example.com/page2"];

    CTNotificationAction *action1 = [[CTNotificationAction alloc] initWithOpenURL:deepLink1];
    CTNotificationAction *action2 = [[CTNotificationAction alloc] initWithOpenURL:deepLink2];

    CTNotificationButton *button1 = [[CTNotificationButton alloc] init];
    button1.text = @"Option A";
    button1.action = action1;

    CTNotificationButton *button2 = [[CTNotificationButton alloc] init];
    button2.text = @"Option B";
    button2.action = action2;

    // Then: Each button should maintain its own deep link
    XCTAssertEqualObjects(button1.action.actionURL.absoluteString, @"https://example.com/page1",
                         @"Button 1 should have its own deep link");
    XCTAssertEqualObjects(button2.action.actionURL.absoluteString, @"https://example.com/page2",
                         @"Button 2 should have its own deep link");
    XCTAssertNotEqualObjects(button1.action.actionURL, button2.action.actionURL,
                            @"Deep links should be different");
}

#pragma mark - Personalized Deep Link Tests

- (void)testPersonalizedDeepLinkPreserved {
    // Given: A deep link with user-specific parameters
    NSString *personalizedDeepLink = @"https://app.example.com/offer?user_id=abc123&name=John&promo=SPRING2026";
    NSURL *deepLinkURL = [NSURL URLWithString:personalizedDeepLink];

    CTNotificationAction *action = [[CTNotificationAction alloc] initWithOpenURL:deepLinkURL];

    // Then: Personalized parameters should be preserved in absoluteString
    NSString *absoluteURL = action.actionURL.absoluteString;
    XCTAssertTrue([absoluteURL containsString:@"user_id=abc123"], @"User ID should be preserved");
    XCTAssertTrue([absoluteURL containsString:@"name=John"], @"Name should be preserved");
    XCTAssertTrue([absoluteURL containsString:@"promo=SPRING2026"], @"Promo code should be preserved");
}

#pragma mark - Backward Compatibility Tests

- (void)testBackwardCompatibilityWithExistingWzrkC2a {
    // Given: Params with both wzrk_c2a and wzrk_dl (new format)
    NSDictionary *inAppJSON = @{
        @"ti": @"test_backward_compat",
        @"wzrk_id": @"test_backward_compat"
    };
    CTInAppNotification *notification = [[CTInAppNotification alloc] initWithJSON:inAppJSON];

    NSString *ctaText = @"Learn More";
    NSString *deepLink = @"https://learn.example.com";
    NSDictionary *params = @{
        CLTAP_PROP_WZRK_CTA: ctaText,
        CLTAP_PROP_WZRK_DL: deepLink
    };

    XCTestExpectation *expectation = [self expectationWithDescription:@"Backward compatibility"];

    // When: Building event with both properties
    [CTEventBuilder buildInAppNotificationStateEvent:YES
                                     forNotification:notification
                                  andQueryParameters:params
                                   completionHandler:^(NSDictionary *event, NSArray<CTValidationResult *> *errors) {
        // Then: Both properties should be present independently
        NSDictionary *eventData = event[CLTAP_EVENT_DATA];
        XCTAssertEqualObjects(eventData[CLTAP_PROP_WZRK_CTA], ctaText,
                             @"wzrk_c2a should work as before");
        XCTAssertEqualObjects(eventData[CLTAP_PROP_WZRK_DL], deepLink,
                             @"wzrk_dl should be added separately");

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

@end

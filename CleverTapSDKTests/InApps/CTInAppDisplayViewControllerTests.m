//
//  CTInAppDisplayViewControllerTests.m
//  CleverTapSDKTests
//
//  Created by Nishant Kumar on 18/11/24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTInAppDisplayViewControllerMock.h"
#import "CTInAppNotificationDisplayDelegateMock.h"
#import "CTPiPContainerView.h"

// Implemented in CTPiPPayloadModel.m, not declared in its header.
@interface CTPiPConfigModel (PiPTests)
+ (instancetype)modelFromJSON:(NSDictionary *)json;
@end

@interface CTPiPMediaModel (PiPTests)
+ (instancetype)modelFromJSON:(NSDictionary *)json;
@end

// Declared in CTInAppDisplayViewControllerPrivate.h, which the test target does not import.
@interface CTInAppDisplayViewController (SafeAreaTests)
- (void)keepContainerInsideSafeArea:(UIView *)containerView closeButton:(UIView *)closeButton;
+ (UIEdgeInsets)insetsIgnoringEvenSides:(UIEdgeInsets)insets;
@end

@interface CTInAppDisplayViewControllerTests : XCTestCase

@property (nonatomic, strong) CTInAppDisplayViewControllerMock *viewController;
@property (nonatomic, strong) CTInAppNotification *inAppNotification;

@end

@implementation CTInAppDisplayViewControllerTests

- (void)setUp {
    [super setUp];
    
    NSDictionary *inApp = @{
        @"ti": @1
    };
    self.inAppNotification = [[CTInAppNotification alloc] initWithJSON:inApp];
    self.viewController = [[CTInAppDisplayViewControllerMock alloc] initWithNotification:self.inAppNotification];
}

- (void)tearDown {
    self.viewController = nil;

    [super tearDown];
}

#pragma mark triggerInAppAction Tests

- (void)testAddURLParamsOnly {
    // triggerAction should add url parameters only in extras dictionary
    // if callToAction and buttonId is not present.
    NSURL *url = [NSURL URLWithString:@"https://clevertap.com?param1=value1&param2=value2"];
    NSDictionary *expectedExtras = @{
        @"wzrk_id": @"",
        @"param1": @"value1",
        @"param2": @"value2",
        @"wzrk_action": @"url",
        @"wzrk_data": @"https://clevertap.com?param1=value1&param2=value2",
        @"wzrk_dl": @"https://clevertap.com?param1=value1&param2=value2"
    };
    
    CTNotificationAction *action = [[CTNotificationAction alloc] initWithOpenURL:url];
    
    CTInAppNotificationDisplayDelegateMock *delegate = [[CTInAppNotificationDisplayDelegateMock alloc] init];
    [delegate setHandleNotificationAction:^(CTNotificationAction *action, CTInAppNotification *notification, NSDictionary *extras) {
        XCTAssertEqualObjects(url, action.actionURL);
        XCTAssertEqualObjects(expectedExtras, extras);
    }];
    self.viewController.delegate = delegate;
    // Trigger the action
    [self.viewController triggerInAppAction:action callToAction:nil buttonId:nil];
}

- (void)testAddURLParamsAndC2A {
    // triggerAction should add url parameters along with callToAction and buttonId
    // in extras dictionary.
    NSURL *url = [NSURL URLWithString:@"https://clevertap.com?param1=value1&param2=value2"];
    NSString *callToAction = @"Test CTA";
    NSString *buttonId = @"button1";
    NSDictionary *expectedExtras = @{
        @"wzrk_id": @"",
        @"wzrk_c2a": callToAction,
        @"wzrk_element_id": buttonId,
        @"param1": @"value1",
        @"param2": @"value2",
        @"wzrk_action": @"url",
        @"wzrk_data": @"https://clevertap.com?param1=value1&param2=value2",
        @"wzrk_dl": @"https://clevertap.com?param1=value1&param2=value2"
    };
    
    CTNotificationAction *action = [[CTNotificationAction alloc] initWithOpenURL:url];
    
    CTInAppNotificationDisplayDelegateMock *delegate = [[CTInAppNotificationDisplayDelegateMock alloc] init];
    [delegate setHandleNotificationAction:^(CTNotificationAction *action, CTInAppNotification *notification, NSDictionary *extras) {
        XCTAssertEqualObjects(url, action.actionURL);
        XCTAssertEqualObjects(expectedExtras, extras);
    }];
    self.viewController.delegate = delegate;
    // Trigger the action
    [self.viewController triggerInAppAction:action callToAction:callToAction buttonId:buttonId];
}

- (void)testC2AParamsParseFromDL {
    // triggerAction should parse c2a url params with __dl__ data
    // when callToAction is not provided.
    NSURL *url = [NSURL URLWithString:@"https://clevertap.com?wzrk_c2a=c2aParam__dl__https%3A%2F%2Fdeeplink.com%3Fparam1%3Dasd%26param2%3Dvalue2&asd=value"];

    NSString *buttonId = @"button1";
    // wzrk_dl is set from action.actionURL which is updated to the extracted deeplink.
    NSDictionary *expectedExtras = @{
        @"wzrk_id": @"",
        @"wzrk_c2a": @"c2aParam",
        @"wzrk_element_id": buttonId,
        @"asd": @"value",
        @"wzrk_action": @"url",
        @"wzrk_data": @"https://deeplink.com?param1=asd&param2=value2",
        @"wzrk_dl": @"https://deeplink.com?param1=asd&param2=value2"
    };
    NSURL *expectedURL = [NSURL URLWithString:@"https://deeplink.com?param1=asd&param2=value2"];

    CTNotificationAction *action = [[CTNotificationAction alloc] initWithOpenURL:url];

    CTInAppNotificationDisplayDelegateMock *delegate = [[CTInAppNotificationDisplayDelegateMock alloc] init];
    [delegate setHandleNotificationAction:^(CTNotificationAction *action, CTInAppNotification *notification, NSDictionary *extras) {
        XCTAssertEqualObjects(expectedURL, action.actionURL);
        XCTAssertEqualObjects(expectedExtras, extras);
    }];
    self.viewController.delegate = delegate;
    // Trigger the action
    [self.viewController triggerInAppAction:action callToAction:nil buttonId:buttonId];
}

- (void)testC2AParamsDoesNotParseFromDL {
    // triggerAction does not parse c2a url params with __dl__ data when callToAction
    // is provided, wzrk_c2a should have callToAction value only if provided.
    NSURL *url = [NSURL URLWithString:@"https://clevertap.com?wzrk_c2a=c2aParam__dl__https%3A%2F%2Fdeeplink.com%3Fparam1%3Dasd%26param2%3Dvalue2&asd=value"];
    NSString *callToAction = @"Test CTA";
    NSString *buttonId = @"button1";
    // wzrk_dl is set from action.actionURL which is updated to the extracted deeplink.
    NSDictionary *expectedExtras = @{
        @"wzrk_id": @"",
        @"wzrk_c2a": callToAction,
        @"wzrk_element_id": buttonId,
        @"asd": @"value",
        @"wzrk_action": @"url",
        @"wzrk_data": @"https://deeplink.com?param1=asd&param2=value2",
        @"wzrk_dl": @"https://deeplink.com?param1=asd&param2=value2"
    };
    NSURL *expectedURL = [NSURL URLWithString:@"https://deeplink.com?param1=asd&param2=value2"];
    
    CTNotificationAction *action = [[CTNotificationAction alloc] initWithOpenURL:url];
    
    CTInAppNotificationDisplayDelegateMock *delegate = [[CTInAppNotificationDisplayDelegateMock alloc] init];
    [delegate setHandleNotificationAction:^(CTNotificationAction *action, CTInAppNotification *notification, NSDictionary *extras) {
        XCTAssertEqualObjects(expectedURL, action.actionURL);
        XCTAssertEqualObjects(expectedExtras, extras);
    }];
    self.viewController.delegate = delegate;
    // Trigger the action
    [self.viewController triggerInAppAction:action callToAction:callToAction buttonId:buttonId];
}

#pragma mark keepContainerInsideSafeArea Tests

// Builds the same layout as the portrait interstitial xib: a container pinned 30pt from the
// sides, centered vertically, 1:1.78 wide to tall, with a 30pt close button that overhangs
// its top trailing corner by 15pt.
- (NSDictionary<NSString *, UIView *> *)interstitialLayoutInViewOfSize:(CGSize)size {
    UIView *root = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    UIView *container = [UIView new];
    UIView *closeButton = [UIView new];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:container];
    [root addSubview:closeButton];
    [NSLayoutConstraint activateConstraints:@[
        [container.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:30],
        [root.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:30],
        [container.centerYAnchor constraintEqualToAnchor:root.centerYAnchor],
        [container.heightAnchor constraintEqualToAnchor:container.widthAnchor multiplier:1.78],
        [closeButton.widthAnchor constraintEqualToConstant:30],
        [closeButton.heightAnchor constraintEqualToConstant:30],
        [closeButton.leadingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-15],
        [container.topAnchor constraintEqualToAnchor:closeButton.bottomAnchor constant:-15]
    ]];
    return @{ @"root": root, @"container": container, @"closeButton": closeButton };
}

- (void)testKeepContainerInsideSafeAreaShrinksContainerOnSquareScreen {
    XCTSkipIf([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad,
              @"The helper only applies to the phone layouts.");
    NSDictionary<NSString *, UIView *> *views = [self interstitialLayoutInViewOfSize:CGSizeMake(400, 400)];
    UIView *root = views[@"root"];
    UIView *container = views[@"container"];
    UIView *closeButton = views[@"closeButton"];
    self.viewController.view = root;

    // Without the helper the container is 340 x 605 and runs off a 400pt tall view.
    // This layout pass also runs viewWillLayoutSubviews, which moves the side pins to the
    // safe area guide, so the helper is tested against pins it has to find there.
    [root layoutIfNeeded];
    XCTAssertFalse(CGRectContainsRect(root.bounds, container.frame));

    [self.viewController keepContainerInsideSafeArea:container closeButton:closeButton];
    [root setNeedsLayout];
    [root layoutIfNeeded];

    XCTAssertTrue(CGRectContainsRect(root.bounds, container.frame), @"container %@", NSStringFromCGRect(container.frame));
    XCTAssertTrue(CGRectContainsRect(root.bounds, closeButton.frame), @"close button %@", NSStringFromCGRect(closeButton.frame));
    XCTAssertGreaterThan(container.frame.size.width, 0);
    XCTAssertEqualWithAccuracy(container.frame.size.height, container.frame.size.width * 1.78, 0.5);
    XCTAssertEqualWithAccuracy(CGRectGetMidX(container.frame), CGRectGetMidX(root.bounds), 0.5);
    XCTAssertEqualWithAccuracy(CGRectGetMidY(container.frame), CGRectGetMidY(root.bounds), 0.5);
}

- (void)testKeepContainerInsideSafeAreaLeavesFittingLayoutUnchanged {
    XCTSkipIf([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad,
              @"The helper only applies to the phone layouts.");
    NSDictionary<NSString *, UIView *> *views = [self interstitialLayoutInViewOfSize:CGSizeMake(400, 900)];
    UIView *root = views[@"root"];
    UIView *container = views[@"container"];
    UIView *closeButton = views[@"closeButton"];
    self.viewController.view = root;

    [root layoutIfNeeded];
    CGRect containerFrameBefore = container.frame;
    CGRect closeButtonFrameBefore = closeButton.frame;
    XCTAssertTrue(CGRectContainsRect(root.bounds, containerFrameBefore));

    [self.viewController keepContainerInsideSafeArea:container closeButton:closeButton];
    [root setNeedsLayout];
    [root layoutIfNeeded];

    XCTAssertTrue(CGRectEqualToRect(container.frame, containerFrameBefore), @"container %@", NSStringFromCGRect(container.frame));
    XCTAssertTrue(CGRectEqualToRect(closeButton.frame, closeButtonFrameBefore), @"close button %@", NSStringFromCGRect(closeButton.frame));
}

- (void)testKeepContainerInsideSafeAreaIgnoresViewsOutsideTheHierarchy {
    self.viewController.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, 400)];
    UIView *detached = [UIView new];
    XCTAssertNoThrow([self.viewController keepContainerInsideSafeArea:detached closeButton:nil]);
    XCTAssertNoThrow([self.viewController keepContainerInsideSafeArea:nil closeButton:nil]);
    XCTAssertEqual(self.viewController.view.constraints.count, 0);
}

#pragma mark Side safe area tests

// Shows the view controller in a window with the given extra side insets and returns a
// container pinned to both sides of the root view, the way the cover, header and footer xibs do.
- (UIView *)edgePinnedContainerWithLeftInset:(CGFloat)left rightInset:(CGFloat)right window:(UIWindow **)windowOut {
    UIView *root = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, 400)];
    UIView *container = [UIView new];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:container];
    [NSLayoutConstraint activateConstraints:@[
        [container.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [root.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [container.topAnchor constraintEqualToAnchor:root.topAnchor],
        [container.heightAnchor constraintEqualToConstant:100]
    ]];
    self.viewController.view = root;
    self.viewController.additionalSafeAreaInsets = UIEdgeInsetsMake(0, left, 0, right);

    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 400, 400)];
    window.rootViewController = self.viewController;
    window.hidden = NO;
    [root setNeedsLayout];
    [root layoutIfNeeded];
    *windowOut = window;
    return container;
}

// A notched iPhone in landscape has the same inset on both sides. In-apps have always
// run edge to edge there, so the side pins must stay on the view's edges.
- (void)testEvenSideInsetsKeepContentEdgeToEdge {
    UIWindow *window = nil;
    UIView *container = [self edgePinnedContainerWithLeftInset:62 rightInset:62 window:&window];
    UIView *root = self.viewController.view;

    XCTAssertEqualWithAccuracy(root.safeAreaInsets.left, 62, 0.5, @"the test window did not apply the insets");
    XCTAssertEqualWithAccuracy(root.safeAreaInsets.right, 62, 0.5);
    XCTAssertEqualWithAccuracy(CGRectGetMinX(container.frame), 0, 0.5);
    XCTAssertEqualWithAccuracy(CGRectGetMaxX(container.frame), CGRectGetMaxX(root.bounds), 0.5);
    window.hidden = YES;
}

// A foldable has an inset on one side only (the strip beside the closed screen).
// Content must stop at it.
- (void)testUnevenSideInsetsKeepContentInsideSafeArea {
    UIWindow *window = nil;
    UIView *container = [self edgePinnedContainerWithLeftInset:0 rightInset:84 window:&window];
    UIView *root = self.viewController.view;

    XCTAssertEqualWithAccuracy(root.safeAreaInsets.right, 84, 0.5, @"the test window did not apply the insets");
    XCTAssertEqualWithAccuracy(CGRectGetMinX(container.frame), 0, 0.5);
    XCTAssertEqualWithAccuracy(CGRectGetMaxX(container.frame), CGRectGetMaxX(root.bounds) - 84, 0.5);
    window.hidden = YES;
}

- (void)testInsetsIgnoringEvenSides {
    UIEdgeInsets even = [CTInAppDisplayViewController insetsIgnoringEvenSides:UIEdgeInsetsMake(20, 62, 21, 62)];
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(even, UIEdgeInsetsMake(20, 0, 21, 0)), @"%@", NSStringFromUIEdgeInsets(even));

    UIEdgeInsets uneven = [CTInAppDisplayViewController insetsIgnoringEvenSides:UIEdgeInsetsMake(0, 0, 21, 84)];
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(uneven, UIEdgeInsetsMake(0, 0, 21, 84)), @"%@", NSStringFromUIEdgeInsets(uneven));

    UIEdgeInsets none = [CTInAppDisplayViewController insetsIgnoringEvenSides:UIEdgeInsetsMake(62, 0, 34, 0)];
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(none, UIEdgeInsetsMake(62, 0, 34, 0)), @"%@", NSStringFromUIEdgeInsets(none));
}

#pragma mark PiP tests

- (CTPiPContainerView *)pipContainerAtPosition:(NSString *)position {
    CTPiPConfigModel *config = [CTPiPConfigModel modelFromJSON:@{ @"position": position, @"width": @40 }];
    CTPiPMediaModel *media = [CTPiPMediaModel modelFromJSON:@{ @"url": @"https://example.com/a.png" }];
    CTPiPMediaView *mediaView = [[CTPiPMediaView alloc] initWithMedia:media];
    return [[CTPiPContainerView alloc] initWithConfig:config showClose:NO mediaView:mediaView];
}

// A foldable's outer screen has a wide strip on one side. Centre must be the middle of what is left.
- (void)testPiPCenterPositionIsCentredBetweenUnevenSideInsets {
    CGRect bounds = CGRectMake(0, 0, 466, 678);
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, 0, 84);

    CTPiPContainerView *center = [self pipContainerAtPosition:@"center"];
    [center placeInitialPositionInBounds:bounds safeAreaInsets:insets];
    CTPiPContainerView *left = [self pipContainerAtPosition:@"center-left"];
    [left placeInitialPositionInBounds:bounds safeAreaInsets:insets];
    CTPiPContainerView *right = [self pipContainerAtPosition:@"center-right"];
    [right placeInitialPositionInBounds:bounds safeAreaInsets:insets];

    XCTAssertEqualWithAccuracy(CGRectGetMidX(center.frame), (466.0 - 84.0) / 2.0, 0.5);
    XCTAssertEqualWithAccuracy(CGRectGetMinX(center.frame) - CGRectGetMinX(left.frame),
                               CGRectGetMinX(right.frame) - CGRectGetMinX(center.frame), 0.5);
}

- (void)testPiPCenterPositionIsUnchangedWithEvenSideInsets {
    CGRect bounds = CGRectMake(0, 0, 874, 402);
    CTPiPContainerView *center = [self pipContainerAtPosition:@"center"];
    [center placeInitialPositionInBounds:bounds safeAreaInsets:UIEdgeInsetsMake(0, 62, 21, 62)];

    XCTAssertEqualWithAccuracy(CGRectGetMidX(center.frame), 437.0, 0.5);
    XCTAssertEqualWithAccuracy(CGRectGetMidY(center.frame), 201.0, 0.5);
}

@end

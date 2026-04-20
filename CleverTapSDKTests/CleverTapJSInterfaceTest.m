//
//  CleverTapJSInterfaceTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <WebKit/WebKit.h>
#import "CleverTapJSInterface.h"
#import "CleverTapJSInterfacePrivate.h"
#import "CleverTapInstanceConfig.h"

@interface CleverTapJSInterface (Test)
- (void)triggerInAppAction:(NSDictionary *)actionJson
              callToAction:(NSString *)callToAction
                  buttonId:(NSString *)buttonId;
@end

@interface CleverTapJSInterfaceTest : XCTestCase
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CleverTapJSInterface *jsInterface;
@end

@implementation CleverTapJSInterfaceTest

- (void)setUp {
    [super setUp];
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"jsInterfaceTestAcct"
                                                        accountToken:@"testToken"];
    self.jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.config];
}

- (void)tearDown {
    self.jsInterface = nil;
    self.config = nil;
    [super tearDown];
}

#pragma mark - init

- (void)test_initWithConfig_returnsNonNil {
    XCTAssertNotNil(self.jsInterface);
}

- (void)test_initWithConfig_setsWvInitTrue {
    XCTAssertTrue(self.jsInterface.wv_init);
}

#pragma mark - versionScript

- (void)test_versionScript_returnsNonNil {
    WKUserScript *script = [self.jsInterface versionScript];
    XCTAssertNotNil(script);
}

- (void)test_versionScript_sourceContainsSDKVersionKey {
    WKUserScript *script = [self.jsInterface versionScript];
    XCTAssertTrue([script.source containsString:@"cleverTapIOSSDKVersion"]);
}

- (void)test_versionScript_injectionTimeIsAtDocumentStart {
    WKUserScript *script = [self.jsInterface versionScript];
    XCTAssertEqual(script.injectionTime, WKUserScriptInjectionTimeAtDocumentStart);
}

- (void)test_versionScript_isForMainFrameOnly {
    WKUserScript *script = [self.jsInterface versionScript];
    XCTAssertTrue(script.isForMainFrameOnly);
}

#pragma mark - triggerInAppAction: — nil / guard cases

- (void)test_triggerInAppAction_nilActionJson_doesNotCrash {
    // controller is nil (not set); method should return early on nil actionJson
    XCTAssertNoThrow([self.jsInterface triggerInAppAction:nil
                                            callToAction:@"btn"
                                                buttonId:@"0"]);
}

- (void)test_triggerInAppAction_nilController_doesNotCrash {
    // controller not injected via initWithConfigForInApps:, so it's nil
    NSDictionary *actionJson = @{@"type": @"url", @"ios": @"https://example.com"};
    XCTAssertNoThrow([self.jsInterface triggerInAppAction:actionJson
                                            callToAction:@"btn"
                                                buttonId:@"0"]);
}

- (void)test_triggerInAppAction_NSNullCallToAction_doesNotCrash {
    NSDictionary *actionJson = @{@"type": @"url", @"ios": @"https://example.com"};
    XCTAssertNoThrow([self.jsInterface triggerInAppAction:actionJson
                                            callToAction:(NSString *)[NSNull null]
                                                buttonId:@"0"]);
}

- (void)test_triggerInAppAction_NSNullButtonId_doesNotCrash {
    NSDictionary *actionJson = @{@"type": @"url", @"ios": @"https://example.com"};
    XCTAssertNoThrow([self.jsInterface triggerInAppAction:actionJson
                                            callToAction:@"btn"
                                                buttonId:(NSString *)[NSNull null]]);
}

@end

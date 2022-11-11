//
//  CleverTapInstanceConfigTests.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 11.11.22.
//  Copyright © 2022 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "CleverTapInstanceConfig.h"
#import "CTPreferences.h"

@interface CleverTapInstanceConfig (Tests)
+ (NSString*)dataArchiveFileNameWithAccountId:(NSString*)accountId;
@end

@interface CleverTapGlobalInstanceTests : XCTestCase

@end

@implementation CleverTapGlobalInstanceTests

- (void)test_clevertap_instance_g {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"id" accountToken:@"token" accountRegion:@"eu"];
    [config setEnablePersonalization:YES];
    [config setDisableAppLaunchedEvent:YES];
    [config setLogLevel:1];
    [config setDisableIDFV:YES];
    [config setAnalyticsOnly:YES];
    [config setUseCustomCleverTapId:YES];
    [config setIdentityKeys:@[@"Email"]];

    [CTPreferences archiveObject:config forFileName: [CleverTapInstanceConfig dataArchiveFileNameWithAccountId:config.accountId]];

    CleverTapInstanceConfig *cachedConfig = [CTPreferences unarchiveFromFile: [CleverTapInstanceConfig dataArchiveFileNameWithAccountId:config.accountId] ofType:[CleverTapInstanceConfig class] removeFile:YES];
    
    XCTAssertNotNil(cachedConfig);
    XCTAssertEqualObjects([cachedConfig accountId], [config accountId]);
    XCTAssertEqualObjects([cachedConfig accountToken], [config accountToken]);
    XCTAssertEqualObjects([cachedConfig accountRegion], [config accountRegion]);
    
    XCTAssertEqual([cachedConfig enablePersonalization], [config enablePersonalization]);
    XCTAssertEqual([cachedConfig disableAppLaunchedEvent], [config disableAppLaunchedEvent]);
    XCTAssertEqual([cachedConfig disableIDFV], [config disableIDFV]);
    XCTAssertEqual([cachedConfig analyticsOnly], [config analyticsOnly]);
    XCTAssertEqual([cachedConfig useCustomCleverTapId], [config useCustomCleverTapId]);
    XCTAssertEqualObjects([cachedConfig identityKeys], [config identityKeys]);
    XCTAssertEqual([cachedConfig logLevel], [config logLevel]);
}

- (void)test_clevertap_instance_g2 {
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"id" accountToken:@"token"
                                                                             proxyDomain:@"proxy" spikyProxyDomain:@"spikyProxy"];

    [CTPreferences archiveObject:config forFileName: [CleverTapInstanceConfig dataArchiveFileNameWithAccountId:config.accountId]];

    CleverTapInstanceConfig *cachedConfig = [CTPreferences unarchiveFromFile: [CleverTapInstanceConfig dataArchiveFileNameWithAccountId:config.accountId] ofType:[CleverTapInstanceConfig class] removeFile:YES];
    
    XCTAssertNotNil(cachedConfig);
    XCTAssertEqualObjects([cachedConfig accountId], [config accountId]);
    XCTAssertEqualObjects([cachedConfig accountToken], [config accountToken]);
    XCTAssertEqualObjects([cachedConfig proxyDomain], [config proxyDomain]);
    XCTAssertEqualObjects([cachedConfig spikyProxyDomain], [config spikyProxyDomain]);
    
    XCTAssertEqual([cachedConfig enablePersonalization], [config enablePersonalization]);
    XCTAssertEqual([cachedConfig disableAppLaunchedEvent], [config disableAppLaunchedEvent]);
    XCTAssertEqual([cachedConfig disableIDFV], [config disableIDFV]);
    XCTAssertEqual([cachedConfig analyticsOnly], [config analyticsOnly]);
    XCTAssertEqual([cachedConfig useCustomCleverTapId], [config useCustomCleverTapId]);
    XCTAssertEqualObjects([cachedConfig identityKeys], [config identityKeys]);
    XCTAssertEqual([cachedConfig logLevel], [config logLevel]);
}

@end

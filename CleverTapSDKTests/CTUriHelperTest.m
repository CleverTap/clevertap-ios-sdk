//
//  CTUriHelperTest.m
//  CleverTapSDKTests
//
//  Created by Aishwarya Nanna on 27/04/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTUriHelper.h"

@interface CTUriHelperTest : XCTestCase

@end

@implementation CTUriHelperTest

- (void)test_getUrchinFromUri {
    NSString *uri = @"https://example.com/?utm_source=google&utm_medium=cpc&utm_campaign=test_campaign&wzrk_medium=email";
    NSString *sourceApp = @"clevertap";
    NSDictionary *result = [CTUriHelper getUrchinFromUri:uri withSourceApp:sourceApp];
        
    XCTAssertEqualObjects(result[@"referrer"], sourceApp);
    XCTAssertEqualObjects(result[@"us"], @"google");
    XCTAssertEqualObjects(result[@"um"], @"cpc");
    XCTAssertEqualObjects(result[@"uc"], @"test_campaign");
    XCTAssertEqualObjects(result[@"wm"], @"email");
}

- (void)test_getUrchinFromUri_invalidSource{
    NSString *uri = @"https://example.com/?utm_source=google&utm_medium=cpc&utm_campaign=test_campaign&wzrk_medium=email";
    NSString *sourceApp = @"";
    NSDictionary *result = [CTUriHelper getUrchinFromUri:uri withSourceApp:sourceApp];
        
    XCTAssertNil(result[@"referrer"]);
}

- (void)test_getUrchinFromUri_invalidMedium{
    NSString *uri = @"https://example.com/?wzrk_medium=invalid";
    NSString *sourceApp = @"";
    NSDictionary *result = [CTUriHelper getUrchinFromUri:uri withSourceApp:sourceApp];
        
    XCTAssertNil(result[@"wm"]);
}

- (void)test_getUrchinFromUri_invalidUtmOrWzrkValue{
    NSString *uri = @"https://example.com/?utm_medium=cpc&utm_campaign=test_campaign&wzrk_medium=email";
    NSString *sourceApp = @"clevertap";
    NSDictionary *result = [CTUriHelper getUrchinFromUri:uri withSourceApp:sourceApp];
        
    XCTAssertNil(result[@"us"]);
}

- (void)test_getUrchinFromUri_invalidCampignValue{
    NSString *uri = @"https://example.com/?utm_medium=cpc&utm_campaign=&wzrk_medium=email";
    NSString *sourceApp = @"clevertap";
    NSDictionary *result = [CTUriHelper getUrchinFromUri:uri withSourceApp:sourceApp];
        
    XCTAssertNil(result[@"uc"]);
}

- (void)test_getQueryParameters_withDecode{
    NSURL *url = [NSURL URLWithString:@"https://example.com?utm=utmExample&source=exampleSource"];
    NSDictionary *expectedParams = @{@"utm": @"utmExample", @"source": @"exampleSource"};

    NSDictionary *params = [CTUriHelper getQueryParameters:url andDecode:true];
    
    XCTAssertEqualObjects(params, expectedParams);
}

- (void)test_getQueryParameters_withoutDecode{
    NSURL *url = [NSURL URLWithString:@"https://example.com?utm=utmExample&source=exampleSource"];
    NSDictionary *expectedParams = @{@"utm": @"utmExample", @"source": @"exampleSource"};

    NSDictionary *params = [CTUriHelper getQueryParameters:url andDecode:false];
    
    XCTAssertEqualObjects(params, expectedParams);
}

- (void)test_getQueryParameters_invalidURL{
    NSURL *url = nil;
    NSDictionary *params = [CTUriHelper getQueryParameters:url andDecode:false];
    
    XCTAssertEqualObjects(params, @{});
}

@end

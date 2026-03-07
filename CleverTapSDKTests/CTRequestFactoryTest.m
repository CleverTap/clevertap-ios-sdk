//
//  CTRequestFactoryTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTRequestFactory.h"
#import "CTRequest.h"
#import "CTConstants.h"
#import "CleverTapInstanceConfig.h"

@interface CTRequestFactoryTest : XCTestCase

@property (nonatomic, strong) CleverTapInstanceConfig *config;

@end

@implementation CTRequestFactoryTest

- (void)setUp {
    [super setUp];
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccount" accountToken:@"testToken"];
}

- (void)tearDown {
    self.config = nil;
    [super tearDown];
}

#pragma mark - helloRequest

- (void)test_helloRequest_withoutHandshakeDomain_usesDefaultURL {
    CTRequest *request = [CTRequestFactory helloRequestWithConfig:self.config];
    XCTAssertNotNil(request);
    XCTAssertEqualObjects(request.urlRequest.HTTPMethod, @"GET");
    XCTAssertTrue([request.urlRequest.URL.absoluteString isEqualToString:kHANDSHAKE_URL]);
}

- (void)test_helloRequest_withHandshakeDomain_usesCustomURL {
    [self.config setHandshakeDomain:@"custom.domain.com"];
    CTRequest *request = [CTRequestFactory helloRequestWithConfig:self.config];
    XCTAssertNotNil(request);
    XCTAssertEqualObjects(request.urlRequest.HTTPMethod, @"GET");
    XCTAssertTrue([request.urlRequest.URL.absoluteString containsString:@"custom.domain.com"]);
    XCTAssertTrue([request.urlRequest.URL.absoluteString containsString:@"/hello"]);
}

- (void)test_helloRequest_withHandshakeDomain_setsHeader {
    [self.config setHandshakeDomain:@"custom.domain.com"];
    CTRequest *request = [CTRequestFactory helloRequestWithConfig:self.config];
    NSString *headerValue = [request.urlRequest valueForHTTPHeaderField:kHANDSHAKE_DOMAIN_HEADER];
    XCTAssertEqualObjects(headerValue, @"custom.domain.com");
}

#pragma mark - syncVarsRequest

- (void)test_syncVarsRequest_createsPostRequest {
    CTRequest *request = [CTRequestFactory syncVarsRequestWithConfig:self.config params:nil domain:@"api.clevertap.com"];
    XCTAssertNotNil(request);
    XCTAssertEqualObjects(request.urlRequest.HTTPMethod, @"POST");
}

- (void)test_syncVarsRequest_urlContainsDefineVars {
    CTRequest *request = [CTRequestFactory syncVarsRequestWithConfig:self.config params:nil domain:@"api.clevertap.com"];
    XCTAssertTrue([request.urlRequest.URL.absoluteString containsString:@"defineVars"]);
    XCTAssertTrue([request.urlRequest.URL.absoluteString containsString:@"api.clevertap.com"]);
}

#pragma mark - syncTemplatesRequest

- (void)test_syncTemplatesRequest_createsPostRequest {
    CTRequest *request = [CTRequestFactory syncTemplatesRequestWithConfig:self.config params:nil domain:@"api.clevertap.com"];
    XCTAssertNotNil(request);
    XCTAssertEqualObjects(request.urlRequest.HTTPMethod, @"POST");
}

- (void)test_syncTemplatesRequest_urlContainsDefineTemplates {
    CTRequest *request = [CTRequestFactory syncTemplatesRequestWithConfig:self.config params:nil domain:@"api.clevertap.com"];
    XCTAssertTrue([request.urlRequest.URL.absoluteString containsString:@"defineTemplates"]);
    XCTAssertTrue([request.urlRequest.URL.absoluteString containsString:@"api.clevertap.com"]);
}

#pragma mark - previewRequest

- (void)test_previewRequest_createsGetRequest {
    CTRequest *request = [CTRequestFactory previewRequestWithConfig:self.config url:@"https://api.clevertap.com/preview"];
    XCTAssertNotNil(request);
    XCTAssertEqualObjects(request.urlRequest.HTTPMethod, @"GET");
}

- (void)test_previewRequest_usesProvidedURL {
    NSString *previewURL = @"https://api.clevertap.com/preview?id=123";
    CTRequest *request = [CTRequestFactory previewRequestWithConfig:self.config url:previewURL];
    XCTAssertEqualObjects(request.urlRequest.URL.absoluteString, previewURL);
}

#pragma mark - URL construction

- (void)test_urlWithDomain_formatsCorrectly {
    // Tested via syncVarsRequest: https://domain/defineVars
    CTRequest *request = [CTRequestFactory syncVarsRequestWithConfig:self.config params:nil domain:@"example.com"];
    XCTAssertEqualObjects(request.urlRequest.URL.absoluteString, @"https://example.com/defineVars");
}

@end

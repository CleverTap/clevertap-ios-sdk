//
//  CTRequestTest.m
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CTRequest.h"
#import "CTConstants.h"
#import "CleverTapInstanceConfig.h"

@interface CTRequestTest : XCTestCase
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@end

@implementation CTRequestTest

- (void)setUp {
    [super setUp];
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccount" accountToken:@"testToken"];
}

- (void)tearDown {
    self.config = nil;
    [super tearDown];
}

#pragma mark - HTTP method

- (void)test_init_setsHTTPMethodGET {
    CTRequest *request = [[CTRequest alloc] initWithHttpMethod:@"GET" config:self.config params:nil url:@"https://example.com" additionalHeaders:nil];
    XCTAssertEqualObjects(request.urlRequest.HTTPMethod, @"GET");
}

- (void)test_init_setsHTTPMethodPOST {
    CTRequest *request = [[CTRequest alloc] initWithHttpMethod:@"POST" config:self.config params:nil url:@"https://example.com" additionalHeaders:nil];
    XCTAssertEqualObjects(request.urlRequest.HTTPMethod, @"POST");
}

#pragma mark - URL

- (void)test_init_setsURL {
    CTRequest *request = [[CTRequest alloc] initWithHttpMethod:@"GET" config:self.config params:nil url:@"https://api.example.com/path" additionalHeaders:nil];
    XCTAssertEqualObjects(request.urlRequest.URL.absoluteString, @"https://api.example.com/path");
}

#pragma mark - config headers

- (void)test_init_setsAccountIdHeader {
    CTRequest *request = [[CTRequest alloc] initWithHttpMethod:@"GET" config:self.config params:nil url:@"https://example.com" additionalHeaders:nil];
    XCTAssertEqualObjects([request.urlRequest valueForHTTPHeaderField:ACCOUNT_ID_HEADER], @"testAccount");
}

- (void)test_init_setsAccountTokenHeader {
    CTRequest *request = [[CTRequest alloc] initWithHttpMethod:@"GET" config:self.config params:nil url:@"https://example.com" additionalHeaders:nil];
    XCTAssertEqualObjects([request.urlRequest valueForHTTPHeaderField:ACCOUNT_TOKEN_HEADER], @"testToken");
}

#pragma mark - additional headers

- (void)test_init_setsAdditionalHeaders {
    NSDictionary *extra = @{@"X-Custom": @"myValue"};
    CTRequest *request = [[CTRequest alloc] initWithHttpMethod:@"GET" config:self.config params:nil url:@"https://example.com" additionalHeaders:extra];
    XCTAssertEqualObjects([request.urlRequest valueForHTTPHeaderField:@"X-Custom"], @"myValue");
}

- (void)test_init_nilAdditionalHeaders_doesNotThrow {
    XCTAssertNoThrow([[CTRequest alloc] initWithHttpMethod:@"GET" config:self.config params:nil url:@"https://example.com" additionalHeaders:nil]);
}

#pragma mark - POST body

- (void)test_init_POSTWithParams_setsHTTPBody {
    NSDictionary *params = @{@"key": @"value"};
    CTRequest *request = [[CTRequest alloc] initWithHttpMethod:@"POST" config:self.config params:params url:@"https://example.com" additionalHeaders:nil];
    XCTAssertNotNil(request.urlRequest.HTTPBody);
}

- (void)test_init_GETWithParams_noHTTPBody {
    NSDictionary *params = @{@"key": @"value"};
    CTRequest *request = [[CTRequest alloc] initWithHttpMethod:@"GET" config:self.config params:params url:@"https://example.com" additionalHeaders:nil];
    XCTAssertNil(request.urlRequest.HTTPBody);
}

- (void)test_init_POSTWithNilParams_noHTTPBody {
    CTRequest *request = [[CTRequest alloc] initWithHttpMethod:@"POST" config:self.config params:nil url:@"https://example.com" additionalHeaders:nil];
    XCTAssertNil(request.urlRequest.HTTPBody);
}

- (void)test_init_POSTWithParams_bodyIsValidJSON {
    NSDictionary *params = @{@"foo": @"bar"};
    CTRequest *request = [[CTRequest alloc] initWithHttpMethod:@"POST" config:self.config params:params url:@"https://example.com" additionalHeaders:nil];
    NSData *body = request.urlRequest.HTTPBody;
    NSError *error;
    id parsed = [NSJSONSerialization JSONObjectWithData:body options:0 error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(parsed[@"foo"], @"bar");
}

#pragma mark - callbacks

- (void)test_onResponse_setsResponseBlock {
    CTRequest *request = [[CTRequest alloc] initWithHttpMethod:@"GET" config:self.config params:nil url:@"https://example.com" additionalHeaders:nil];
    CTNetworkResponseBlock block = ^(NSData *data, NSURLResponse *response) {};
    [request onResponse:block];
    XCTAssertNotNil(request.responseBlock);
}

- (void)test_onError_setsErrorBlock {
    CTRequest *request = [[CTRequest alloc] initWithHttpMethod:@"GET" config:self.config params:nil url:@"https://example.com" additionalHeaders:nil];
    CTNetworkResponseErrorBlock block = ^(NSError *error) {};
    [request onError:block];
    XCTAssertNotNil(request.errorBlock);
}

@end

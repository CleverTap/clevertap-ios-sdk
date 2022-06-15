#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsResponse+JSON.h>
#import <OHHTTPStubs/NSURLRequest+HTTPBodyTesting.h>
#import "BaseTestCase.h"
#import "CleverTap.h"
#import "CleverTap+Tests.h"

@interface CleverTapSDKTests : BaseTestCase

@end

@implementation CleverTapSDKTests

- (void)setUp {
    self.responseJson = @{ @"key1": @"value1", @"key2": @[@"value2A", @"value2B"] }; // TODO
    self.responseHeaders = @{@"Content-Type":@"application/json"}; // TODO
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

@end

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

//- (void)testBatchHeader {
//    XCTestExpectation *expectation = [self expectationWithDescription:@"Test Batch Header"];
//
//    [self.cleverTapInstance recordEvent:@"testEventForBatchHeader" withProps:@{@"prop1":@1}];
//
//    [self getLastBatchHeader: ^(NSDictionary* lastBatchHeader) {
//        XCTAssertEqualObjects([lastBatchHeader objectForKey:@"type"], @"meta"); // TODO something real here
//        [expectation fulfill];
//    }];
//
//    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
//        if (error) {
//            XCTFail(@"Expectation Failed with error: %@", error);
//        }
//    }];
//}

//- (void)testRecordEvent {
//    XCTestExpectation *expectation = [self expectationWithDescription:@"Test Record Event"];
//
//    [self.cleverTapInstance recordEvent:@"testEvent" withProps:@{@"prop1":@1}];
//
//    [self getLastEvent: ^(NSDictionary* lastEvent) {
//        XCTAssertEqualObjects([lastEvent objectForKey:@"evtName"], @"testEvent");
//        [expectation fulfill];
//    }];
//
//    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
//        if (error) {
//            XCTFail(@"Expectation Failed with error: %@", error);
//        }
//    }];
//}

@end

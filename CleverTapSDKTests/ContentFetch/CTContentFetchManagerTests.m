//
//  CTContentFetchManagerTests.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 29.05.25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsPathHelpers.h>
#import <OHHTTPStubs/HTTPStubsResponse+JSON.h>
#import <OHHTTPStubs/NSURLRequest+HTTPBodyTesting.h>

#import "CTContentFetchManager.h"
#import "CTContentFetchManagerDelegate.h"
#import "CleverTapInstanceConfig.h"
#import "CTRequestSender.h"
#import "CTDispatchQueueManager.h"
#import "CTDomainFactory.h"
#import "CTConstants.h"

#import "CTContentFetchManager+Tests.h"
#import "CTContentFetchManagerDelegateMock.h"
#import "CTContentFetchManagerMock.h"
#import "CTDomainOperationsMock.h"

@interface CTContentFetchManagerTests : XCTestCase

@property (nonatomic, strong) CTContentFetchManagerMock *contentFetchManager;
@property (nonatomic, strong) CTContentFetchManagerDelegateMock *testDelegate;
@property (nonatomic, strong) id requestSender;
@property (nonatomic, strong) CTDomainOperationsMock *testDomainOperations;
@property (nonatomic, strong) id mockDispatchQueueManager;
@property (nonatomic, strong) CleverTapInstanceConfig *config;

@end

@implementation CTContentFetchManagerTests

- (void)setUp {
    [super setUp];
    
    self.testDelegate = [[CTContentFetchManagerDelegateMock alloc] init];
    NSString *testDomain = @"test.clevertap-prod.com";
    self.testDomainOperations = [[CTDomainOperationsMock alloc] initWithRedirectDomain:testDomain];
    self.testDomainOperations.needsHandshake = NO;
    
    self.mockDispatchQueueManager = OCMClassMock([CTDispatchQueueManager class]);
    OCMStub([self.mockDispatchQueueManager runSerialAsync:[OCMArg invokeBlock]]);
    
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccountId"
                                                        accountToken:@"testAccountToken"];
    self.config.logLevel = CleverTapLogDebug;
    
    self.requestSender = [[CTRequestSender alloc] initWithConfig:self.config redirectDomain:testDomain];
    
    self.contentFetchManager = [[CTContentFetchManagerMock alloc]
                                initWithConfig:self.config
                                requestSender:self.requestSender
                                dispatchQueueManager:self.mockDispatchQueueManager
                                domainOperations:self.testDomainOperations
                                delegate:self.testDelegate];
}

- (void)stubRequestsSuccess {
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:@"content"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        NSDictionary *responseData = @{@"status": @"success"};
        return [HTTPStubsResponse responseWithJSONObject:responseData statusCode:200 headers:nil];
    }];
}

- (void)tearDown {
    if (self.testDelegate) {
        self.testDelegate.onResponseReceived = nil;
        self.testDelegate.onErrorReceived = nil;
        self.testDelegate.onMetadataAdded = nil;
    }
    self.contentFetchManager.delegate = nil;
    
    [HTTPStubs removeAllStubs];
    [self.mockDispatchQueueManager stopMocking];
    
    [super tearDown];
}

#pragma mark - Initialization Tests

- (void)testInitialization {
    XCTAssertNotNil(self.contentFetchManager);
    XCTAssertEqual(self.contentFetchManager.delegate, self.testDelegate);
}

#pragma mark - Content Fetch Handling Tests

- (void)testHandleContentFetch_WithValidData_AddsToQueue {
    [self stubRequestsSuccess];
    
    NSDictionary *contentFetchItem1 = @{@"id": @"item1", @"data": @"test1"};
    NSDictionary *contentFetchItem2 = @{@"id": @"item2", @"data": @"test2"};
    NSDictionary *jsonResp = @{
        CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY: @[contentFetchItem1, contentFetchItem2]
    };
    
    [self.contentFetchManager handleContentFetch:jsonResp];
    
    XCTAssertEqual(self.testDelegate.metadataEvents.count, 2);
    
    // Verify first event
    NSDictionary *firstEvent = self.testDelegate.metadataEvents[0];
    XCTAssertEqualObjects(firstEvent[CLTAP_EVENT_NAME], CLTAP_CONTENT_FETCH_EVENT);
    XCTAssertEqualObjects(firstEvent[CLTAP_EVENT_DATA][@"id"], @"item1");
    XCTAssertEqualObjects(firstEvent[@"test_metadata"], @"added_by_delegate");
    
    // Verify second event
    NSDictionary *secondEvent = self.testDelegate.metadataEvents[1];
    XCTAssertEqualObjects(secondEvent[CLTAP_EVENT_NAME], CLTAP_CONTENT_FETCH_EVENT);
    XCTAssertEqualObjects(secondEvent[CLTAP_EVENT_DATA][@"id"], @"item2");
    XCTAssertEqualObjects(secondEvent[@"test_metadata"], @"added_by_delegate");
}

- (void)testHandleContentFetch_WithNoContentFetch_DoesNothing {
    NSDictionary *jsonResp = @{@"other_key": @"other_value"};
    
    [self.contentFetchManager handleContentFetch:jsonResp];
    XCTAssertEqual(self.testDelegate.metadataEvents.count, 0);
}

- (void)testHandleContentFetch_WithEmptyContentFetch_DoesNothing {
    NSDictionary *jsonResp = @{CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY: @[]};
    
    [self.contentFetchManager handleContentFetch:jsonResp];
    XCTAssertEqual(self.testDelegate.metadataEvents.count, 0);
    XCTAssertEqual(self.contentFetchManager.contentFetchQueue.count, 0);
    XCTAssertEqual(self.testDelegate.receivedResponses.count, 0);
}

#pragma mark - Network Request Tests

- (void)testSendContentRequest_WithValidEndpoint_SendsRequest {
    [self stubRequestsSuccess];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Response received"];
    self.testDelegate.onResponseReceived = ^(NSData *data) {
        XCTAssertNotNil(data);
        [expectation fulfill];
    };
    
    [self.contentFetchManager handleContentFetch:@{
        CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY: @[@{@"test": @"data"}]
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertGreaterThan(self.testDelegate.receivedResponses.count, 0);
}

- (void)testSendContentRequest_WithNetworkError_CallsErrorDelegate {
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:@"content"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
        return [HTTPStubsResponse responseWithError:error];
    }];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Error handled"];
    self.testDelegate.onErrorReceived = ^(NSError *error) {
        XCTAssertNotNil(error);
        [expectation fulfill];
    };
    
    [self.contentFetchManager handleContentFetch:@{
        CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY: @[@{@"test": @"data"}]
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Concurrency Tests

- (void)testConcurrencyLimit_MaximumConcurrentRequests {
    const NSInteger totalRequests = 10;
    const NSInteger maxConcurrency = 5;
    
    __block NSInteger currentConcurrentRequests = 0;
    __block NSInteger maxObservedConcurrency = 0;
    __block NSInteger completedRequests = 0;
    
    NSObject *lockObject = [[NSObject alloc] init];
    
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:@"content"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        @synchronized (lockObject) {
            currentConcurrentRequests++;
            maxObservedConcurrency = MAX(maxObservedConcurrency, currentConcurrentRequests);
        }
        
        // Simulate some processing time
        return [[HTTPStubsResponse responseWithJSONObject:@{@"status": @"success"} statusCode:200 headers:nil]
                requestTime:0.1 responseTime:0.5]; // Total 0.6 seconds
    }];
    
    XCTestExpectation *allRequestsCompleted = [self expectationWithDescription:@"All requests completed"];
    self.testDelegate.onResponseReceived = ^(NSData *data) {
        @synchronized (lockObject) {
            currentConcurrentRequests--;
            completedRequests++;
            
            if (completedRequests == totalRequests) {
                [allRequestsCompleted fulfill];
            }
        }
    };
    
    for (int i = 0; i < totalRequests; i++) {
        [self.contentFetchManager handleContentFetch:@{
            CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY: @[@{@"id": [NSString stringWithFormat:@"item%d", i]}]
        }];
    }
    
    [self waitForExpectationsWithTimeout:15.0 handler:nil];
    XCTAssertLessThanOrEqual(maxObservedConcurrency, maxConcurrency);
    XCTAssertGreaterThan(maxObservedConcurrency, 1);
    XCTAssertEqual(completedRequests, totalRequests);
}

#pragma mark - Handshake Tests

- (void)testSendContentRequest_WithHandshakeNeeded_CallsHandshakeFirst {
    self.testDomainOperations.needsHandshake = YES;
    
    XCTestExpectation *handshakeExpectation = [self expectationWithDescription:@"Handshake called"];
    self.testDomainOperations.handshakeBlock = ^(BOOL success) {
        [handshakeExpectation fulfill];
    };
    
    [self stubRequestsSuccess];
    
    [self.contentFetchManager handleContentFetch:@{
        CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY: @[@{@"test": @"data"}]
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - User Switch Tests

- (void)testDeviceIdWillChange_ClearsQueueAndWaitsForCompletion {
    [self.contentFetchManager handleContentFetch:@{
        CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY: @[@{@"test": @"data1"}]
    }];
    [self.contentFetchManager handleContentFetch:@{
        CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY: @[@{@"test": @"data2"}]
    }];
    
    [self stubRequestsSuccess];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"All requests completed"];
    self.contentFetchManager.onAllRequestsCompleted = ^{
        [expectation fulfill];
    };
    
    [self.contentFetchManager deviceIdWillChange];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

#pragma mark - Timeout Tests

- (void)testContentFetchTimeout_WithSlowResponse_TimesOut {
    double requestTime = 20.0;
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:@"content"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        return [[HTTPStubsResponse responseWithJSONObject:@{@"status": @"success"} statusCode:200 headers:nil]
                requestTime:requestTime responseTime:0.0];
    }];
    
    XCTestExpectation *expectationRequestsCompleted = [self expectationWithDescription:@"Request completed"];
    self.contentFetchManager.onAllRequestsCompleted = ^{
        [expectationRequestsCompleted fulfill];
    };
    
    XCTestExpectation *expectationTimeOutError = [self expectationWithDescription:@"Request timed out"];
    self.testDelegate.onErrorReceived = ^(NSError * _Nonnull error) {
        XCTAssertEqual(error.code, NSURLErrorTimedOut);
        [expectationTimeOutError fulfill];
    };
    
    [self.contentFetchManager handleContentFetch:@{
        CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY: @[@{@"test": @"data"}]
    }];
    
    [self waitForExpectationsWithTimeout:20.0 handler:nil];
    XCTAssertEqual(self.testDelegate.receivedResponses.count, 0);
}

#pragma mark - Edge Cases Tests

- (void)testHandleContentFetch_WithNilResponse_DoesNotCrash {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertNoThrow([self.contentFetchManager handleContentFetch:nil]);
    #pragma clang diagnostic pop
}

- (void)testHandleContentFetch_WithMalformedData_DoesNotCrash {
    NSDictionary *malformedResp = @{
        CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY: @"not_an_array"
    };
    
    XCTAssertNoThrow([self.contentFetchManager handleContentFetch:malformedResp]);
}

#pragma mark - Custom Test Methods

- (void)testQueueStateAccess {
    XCTAssertNotNil(self.contentFetchManager.contentFetchQueue);
    XCTAssertNotNil(self.contentFetchManager.queueLock);
    XCTAssertEqual(self.contentFetchManager.contentFetchQueue.count, 0);
}

@end

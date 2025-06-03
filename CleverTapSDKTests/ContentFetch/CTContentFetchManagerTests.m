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
    
    // Set shorter request timeout for testing
    self.requestSender = [[CTRequestSender alloc] initWithConfig:self.config
                                                  redirectDomain:testDomain
                                                  requestTimeout:5.0
                                                 resourceTimeout:5.0];
    
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

- (void)stubRequestsDifferentResponseTime {
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:@"content"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        // Different delays for different requests to ensure they complete at different times
        NSTimeInterval delay = 0.5 + (arc4random_uniform(700) / 1000.0);
        return [[HTTPStubsResponse responseWithJSONObject:@{@"status": @"success"} statusCode:200 headers:nil]
                requestTime:0.1 responseTime:delay];
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
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"All requests completed."];
    self.contentFetchManager.onAllRequestsCompleted = ^{
        [expectation fulfill];
    };
    
    [self.contentFetchManager handleContentFetch:jsonResp];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
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

- (void)testConcurrencyLimit_RequestsAreSentSimultaneously {
    const NSInteger batchSize = 8; // More than max concurrency to test queuing
    const NSInteger expectedSimultaneousRequests = 5;
    
    __block NSMutableArray *requestStartTimes = [NSMutableArray array];
    __block NSDate *firstRequestTime = nil;
    NSObject *lockObject = [[NSObject alloc] init];
    
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:@"content"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        @synchronized (lockObject) {
            NSDate *now = [NSDate date];
            if (!firstRequestTime) {
                firstRequestTime = now;
            }
            [requestStartTimes addObject:now];
        }
        return [[HTTPStubsResponse responseWithJSONObject:@{@"status": @"success"} statusCode:200 headers:nil]
                requestTime:0.1 responseTime:0.4];
    }];
    
    XCTestExpectation *simultaneousRequestsStarted = [self expectationWithDescription:@"Simultaneous requests started"];
    self.contentFetchManager.onAllRequestsCompleted = ^{
        [simultaneousRequestsStarted fulfill];
    };
    
    for (int i = 0; i < batchSize; i++) {
        [self.contentFetchManager handleContentFetch:@{
            CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY:
                @[@{@"id": [NSString stringWithFormat:@"item%d", i]}]
        }];
    }
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    @synchronized (lockObject) {
        XCTAssertEqual(requestStartTimes.count, batchSize);
        
        // Check that the first 5 requests started within a short time window (indicating simultaneity)
        NSDate *lastSimultaneousRequest = requestStartTimes[expectedSimultaneousRequests - 1];
        NSTimeInterval timeDifference = [lastSimultaneousRequest timeIntervalSinceDate:firstRequestTime];
        XCTAssertLessThan(timeDifference, 0.2);
        
        // Also verify individual gaps between consecutive requests are small
        for (NSInteger i = 1; i < expectedSimultaneousRequests && i < requestStartTimes.count; i++) {
            NSDate *prevRequest = requestStartTimes[i - 1];
            NSDate *currentRequest = requestStartTimes[i];
            NSTimeInterval gap = [currentRequest timeIntervalSinceDate:prevRequest];
            XCTAssertLessThan(gap, 0.1);
        }
        
        for (NSInteger i = expectedSimultaneousRequests; i < batchSize; i++) {
            NSDate *currentRequest = requestStartTimes[i];
            NSTimeInterval gap = [currentRequest timeIntervalSinceDate:lastSimultaneousRequest];
            XCTAssertGreaterThan(gap, 0.3);
        }
    }
}

#pragma mark - Duplicate Request Handling Tests

- (void)testFetchContentAtIndex_WithAlreadyHandledRequest_SkipsRequest {
    [self stubRequestsSuccess];
    
    [self.contentFetchManager handleContentFetch:@{
        CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY: @[@{@"test": @"data"}]
    }];
    
    XCTAssertEqual(self.contentFetchManager.contentFetchQueue.count, 1);
    XCTAssertEqual(self.contentFetchManager.inFlightRequestIndices.count, 1);
    
    // Manually mark the item as already handled
    [self.contentFetchManager.queueLock lock];
    self.contentFetchManager.contentFetchQueue[0] = [NSNull null];
    [self.contentFetchManager.queueLock unlock];
    
    XCTestExpectation *waitExpectation = [self expectationWithDescription:@"Wait for potential request"];

    // Try to fetch content at the same index again
    [self.contentFetchManager fetchContentAtIndex:0];
    
    // Assert on the concurrentQueue to ensure the fetchContentAtIndex: was called
    dispatch_async(self.contentFetchManager.concurrentQueue, ^{
        XCTAssertEqual(self.contentFetchManager.inFlightRequestIndices.count, 0);
        XCTAssertEqual(self.testDelegate.receivedResponses.count, 0);
        XCTAssertEqual(self.testDelegate.receivedErrors.count, 0);
        [waitExpectation fulfill];
    });
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Handshake Tests

- (void)testSendContentRequest_WithHandshakeNeeded_CallsHandshakeFirst {
    self.testDomainOperations.needsHandshake = YES;
    
    XCTestExpectation *handshakeExpectation = [self expectationWithDescription:@"Handshake called"];
    self.testDomainOperations.executeEnsureHandshakeBlock = YES;
    self.testDomainOperations.handshakeBlock = ^(BOOL success) {
        [handshakeExpectation fulfill];
    };
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"All requests completed"];
    self.contentFetchManager.onAllRequestsCompleted = ^{
        [expectation fulfill];
    };
    
    [self stubRequestsSuccess];
    
    [self.contentFetchManager handleContentFetch:@{
        CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY: @[@{@"test": @"data"}]
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - User Switch Tests

- (void)testDeviceIdWillChange_ExecutesOnSerialQueueAndWaitsForCompletion {
    // Setup to change the stub
    self.mockDispatchQueueManager = OCMClassMock([CTDispatchQueueManager class]);
    self.contentFetchManager = [[CTContentFetchManagerMock alloc]
                                initWithConfig:self.config
                                requestSender:self.requestSender
                                dispatchQueueManager:self.mockDispatchQueueManager
                                domainOperations:self.testDomainOperations
                                delegate:self.testDelegate];
    
    [self.contentFetchManager handleContentFetch:@{
        CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY: @[@{@"test": @"data1"}]
    }];
    [self.contentFetchManager handleContentFetch:@{
        CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY: @[@{@"test": @"data2"}]
    }];
    XCTAssertEqual(self.contentFetchManager.contentFetchQueue.count, 2);
    
    XCTestExpectation *serialQueueExpectation = [self expectationWithDescription:@"Serial queue execution"];
    XCTestExpectation *allRequestsCompletedExpectation = [self expectationWithDescription:@"All requests completed"];
    
    // Mock the dispatch queue manager to verify serial execution
    OCMStub([self.mockDispatchQueueManager runSerialAsync:[OCMArg checkWithBlock:^BOOL(void (^block)(void)) {
        [serialQueueExpectation fulfill];
        
        // Execute the block to simulate serial queue behavior
        block();
        return YES;
    }]]);
    
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:@"content"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        return [[HTTPStubsResponse responseWithJSONObject:@{@"status": @"success"} statusCode:200 headers:nil]
                requestTime:0.1 responseTime:0.5];
    }];
    
    __block NSInteger responsesReceived = 0;
    self.testDelegate.onResponseReceived = ^(NSData * _Nonnull data) {
        responsesReceived++;
    };
    
    self.contentFetchManager.onAllRequestsCompleted = ^{
        [allRequestsCompletedExpectation fulfill];
    };
    
    [self.contentFetchManager deviceIdWillChange];
    
    [self waitForExpectations:@[serialQueueExpectation, allRequestsCompletedExpectation] timeout:10.0];
    XCTAssertEqual(responsesReceived, 2);
    XCTAssertEqual(self.contentFetchManager.contentFetchQueue.count, 0);
}

- (void)testDeviceIdWillChange_BlocksUntilAllRequestsComplete {
    const NSInteger requestCount = 8;
    __block NSInteger completedRequests = 0;
    
    [self stubRequestsDifferentResponseTime];
    
    self.testDelegate.onResponseReceived = ^(NSData *data) {
        completedRequests++;
    };
    
    for (int i = 0; i < requestCount; i++) {
        [self.contentFetchManager handleContentFetch:@{
            CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY:
                @[@{@"test": [NSString stringWithFormat:@"data%d", i]}]
        }];
    }
    
    XCTestExpectation *deviceIdChangeExpectation = [self expectationWithDescription:@"Device ID change completed"];
    [self.mockDispatchQueueManager runSerialAsync:^{
        [self.contentFetchManager deviceIdWillChange];
        XCTAssertEqual(self.contentFetchManager.contentFetchQueue.count, 0);
        XCTAssertEqual(self.contentFetchManager.inFlightRequestIndices.count, 0);
        [deviceIdChangeExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:15.0 handler:nil];
    XCTAssertEqual(completedRequests, requestCount);
}

- (void)testDeviceIdWillChange_HandlesInFlightAndQueuedRequests {
    const NSInteger requestCount = 7;
    const NSInteger additionalRequests = 3;
    __block NSInteger completedRequests = 0;
    
    [self stubRequestsDifferentResponseTime];
    
    self.testDelegate.onResponseReceived = ^(NSData *data) {
        completedRequests++;
    };
    
    for (int i = 0; i < requestCount; i++) {
        [self.contentFetchManager handleContentFetch:@{
            CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY:
                @[@{@"test": [NSString stringWithFormat:@"data%d", i]}]
        }];
    }
    
    XCTestExpectation *deviceIdChangeExpectation = [self expectationWithDescription:@"Device ID change completed"];
    [self.mockDispatchQueueManager runSerialAsync:^{
        // Assert all requests are queued
        XCTAssertEqual(self.contentFetchManager.contentFetchQueue.count, requestCount);
        
        // Add additional content fetch items directly in the queue array
        for (int i = 0; i < additionalRequests; i++) {
            [self.contentFetchManager.contentFetchQueue addObject:@{
                @"type": @(CleverTapEventTypeRaised),
                CLTAP_EVENT_DATA: @{
                    @"test": [NSString stringWithFormat:@"data%ld", (long)(i + requestCount)]
                },
                CLTAP_EVENT_NAME: CLTAP_CONTENT_FETCH_EVENT
            }];
        }
        
        // Ensure all events are in the queue
        XCTAssertEqual(self.contentFetchManager.contentFetchQueue.count, requestCount + additionalRequests);
        // Ensure in-flight events are only those queued before
        XCTAssertEqual(self.contentFetchManager.inFlightRequestIndices.count, requestCount);
        
        [self.contentFetchManager deviceIdWillChange];
        XCTAssertEqual(self.contentFetchManager.contentFetchQueue.count, 0);
        XCTAssertEqual(self.contentFetchManager.inFlightRequestIndices.count, 0);
        [deviceIdChangeExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:15.0 handler:nil];
    XCTAssertEqual(completedRequests, requestCount + additionalRequests);
}

#pragma mark - Timeout Tests

- (void)testContentFetchTimeout_WithSlowResponse_TimesOut {
    double requestTime = 10.0;
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
    
    [self waitForExpectationsWithTimeout:15.0 handler:nil];
    XCTAssertEqual(self.testDelegate.receivedResponses.count, 0);
}

- (void)testSemaphoreTimeout_WhenAllSlotsOccupied_TimesOut {
    // Set shorter semaphore timeout for testing
    self.contentFetchManager.semaphoreTimeout = 2.0;
    
    const NSInteger maxConcurrency = 5;
    const NSInteger totalRequests = maxConcurrency + 1;
    
    NSTimeInterval responseTime = self.contentFetchManager.semaphoreTimeout * 2;
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:@"content"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        return [[HTTPStubsResponse responseWithJSONObject:@{@"status": @"success"} statusCode:200 headers:nil]
                requestTime:0.1 responseTime:responseTime];
    }];
    
    __block NSInteger errorCount = 0;
    __block NSInteger successCount = 0;
    
    XCTestExpectation *semaphoreTimeoutExpectation = [self expectationWithDescription:@"Semaphore timeout occurred"];
    XCTestExpectation *requestsProcessedExpectation = [self expectationWithDescription:@"All requests processed"];
    
    void (^checkRequestsProcessed)(void) = ^void() {
        if (successCount + errorCount == totalRequests) {
            [requestsProcessedExpectation fulfill];
        }
    };

    self.testDelegate.onResponseReceived = ^(NSData *data) {
        successCount++;
        NSLog(@"Success count: %ld", (long)successCount);
        
        checkRequestsProcessed();
    };
    
    self.testDelegate.onErrorReceived = ^(NSError *error) {
        errorCount++;
        NSLog(@"Error count: %ld, Error: %@", (long)errorCount, error.localizedDescription);
        
        // Check if this is a semaphore timeout error
        if (error.code == NSURLErrorTimedOut &&
            [error.localizedDescription containsString:@"could not acquire concurrency slot"]) {
            [semaphoreTimeoutExpectation fulfill];
        }
        
        checkRequestsProcessed();
    };
    
    for (int i = 0; i < totalRequests; i++) {
        [self.contentFetchManager handleContentFetch:@{
            CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY:
                @[@{@"id": [NSString stringWithFormat:@"item%d", i]}]
        }];
    }
    
    [self waitForExpectations:@[semaphoreTimeoutExpectation] timeout:5.0];
    [self waitForExpectations:@[requestsProcessedExpectation] timeout:15.0];
    
    XCTAssertEqual(successCount, maxConcurrency);
    XCTAssertEqual(errorCount, totalRequests - maxConcurrency, @"Should have 1 semaphore timeout error");
    XCTAssertEqual(successCount + errorCount, totalRequests);
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

- (void)testSendContentRequest_WithNilEndpoint_CompletesWithoutSendingRequest {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    self.testDomainOperations.redirectDomain = nil;
#pragma clang diagnostic pop
    
    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Request completed"];
    self.contentFetchManager.onAllRequestsCompleted = ^{
        [completionExpectation fulfill];
    };
    
    [self.contentFetchManager handleContentFetch:@{
        CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY: @[@{@"test": @"data"}]
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertEqual(self.testDelegate.receivedResponses.count, 0);
    XCTAssertEqual(self.testDelegate.receivedErrors.count, 0);
    XCTAssertEqual(self.contentFetchManager.contentFetchQueue.count, 0);
}

- (void)testSendContentRequest_WithNilBatchHeader_CompletesWithoutSendingRequest {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    self.testDelegate.batchHeader = nil;
#pragma clang diagnostic pop
    
    XCTestExpectation *completionExpectation = [self expectationWithDescription:@"Request completed"];
    self.contentFetchManager.onAllRequestsCompleted = ^{
        [completionExpectation fulfill];
    };
    
    [self.contentFetchManager handleContentFetch:@{
        CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY: @[@{@"test": @"data"}]
    }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    XCTAssertEqual(self.testDelegate.receivedResponses.count, 0);
    XCTAssertEqual(self.testDelegate.receivedErrors.count, 0);
    XCTAssertEqual(self.contentFetchManager.contentFetchQueue.count, 0);
}

#pragma mark - Custom Test Methods

- (void)testQueueStateAccess {
    XCTAssertNotNil(self.contentFetchManager.contentFetchQueue);
    XCTAssertNotNil(self.contentFetchManager.queueLock);
    XCTAssertEqual(self.contentFetchManager.contentFetchQueue.count, 0);
}

@end

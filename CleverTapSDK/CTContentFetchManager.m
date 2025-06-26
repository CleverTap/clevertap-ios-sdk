//
//  CTContentFetchManager.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 19.05.25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import "CTContentFetchManager.h"
#import "CTPreferences.h"
#import "CTRequestFactory.h"
#import "CTRequestSender.h"
#import "CTRequest.h"
#import "CleverTap.h"
#import "CTConstants.h"
#import "CTDispatchQueueManager.h"
#import "CleverTapBuildInfo.h"
#import "CleverTapInstanceConfig.h"

// Limit concurrent content fetch requests
static const NSUInteger kCONCURRENCY_COUNT = 5;
// Reasonable timeout for all requests to complete on user switch
static const NSTimeInterval kDEFAULT_USER_SWITCH_TIMEOUT = 120.0; // 2 minutes

@interface CTContentFetchManager()

@property (nonatomic, strong) CTRequestSender *requestSender;
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTDispatchQueueManager *dispatchQueueManager;
@property (nonatomic, strong) id<CTDomainOperations> domainOperations;
@property (nonatomic, strong) NSMutableArray *contentFetchQueue;

@property (nonatomic, strong) NSLock *queueLock;
@property (nonatomic, strong) dispatch_queue_t concurrentQueue;
@property (nonatomic, strong) dispatch_semaphore_t concurrencySemaphore;
@property NSTimeInterval semaphoreTimeout;
@property NSTimeInterval userSwitchTimeout;

@property (nonatomic, strong) dispatch_group_t allRequestsGroup;
@property (nonatomic, strong) NSMutableSet *inFlightRequestIndices;
@property (nonatomic, assign) NSUInteger completedBatches;

@end

@implementation CTContentFetchManager

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
                 requestSender:(CTRequestSender *)requestSender
          dispatchQueueManager:(CTDispatchQueueManager *)dispatchQueueManager
              domainOperations:(id<CTDomainOperations>)domainOperations
                      delegate:(id<CTContentFetchManagerDelegate>)delegate {
    self = [super init];
    if (self) {
        self.config = config;
        self.requestSender = requestSender;
        self.domainOperations = domainOperations;
        self.delegate = delegate;
        self.dispatchQueueManager = dispatchQueueManager;
        
        // Add 5 second buffer for dispatch overhead and ensure request timeout fires first
        self.semaphoreTimeout = self.requestSender.requestTimeout + 5;
        // Set the user switch timeout to the default one
        self.userSwitchTimeout = kDEFAULT_USER_SWITCH_TIMEOUT;
        
        self.queueLock = [[NSLock alloc] init];
        self.concurrentQueue = dispatch_queue_create("com.clevertap.contentfetch", DISPATCH_QUEUE_CONCURRENT);
        self.concurrencySemaphore = dispatch_semaphore_create(kCONCURRENCY_COUNT);
        self.contentFetchQueue = [[NSMutableArray alloc] init];
        
        self.allRequestsGroup = dispatch_group_create();
        self.inFlightRequestIndices = [[NSMutableSet alloc] init];
    }
    
    return self;
}

- (void)handleContentFetch:(NSDictionary *)jsonResp {
    NSArray *contentFetch = jsonResp[CLTAP_CONTENT_FETCH_JSON_RESPONSE_KEY];
    if (!contentFetch || ![contentFetch isKindOfClass:[NSArray class]] || contentFetch.count == 0) {
        return;
    }
    
    NSMutableArray *events = [[NSMutableArray alloc] init];
    for (NSDictionary *contentFetchItem in contentFetch) {
        NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:@{
            CLTAP_EVENT_NAME: CLTAP_CONTENT_FETCH_EVENT,
            CLTAP_EVENT_DATA: contentFetchItem
        }];
        
        // Call delegate to add event metadata
        [self.delegate contentFetchManager:self addMetadataToEvent:event ofType:CleverTapEventTypeRaised];
        
        [events addObject:event];
    }
    [self.queueLock lock];
    [self.contentFetchQueue addObject:events];
    CleverTapLogDebug(self.config.logLevel, @"%@: Added content fetch with %ld events", self, [events count]);
    NSUInteger batchIndex = self.contentFetchQueue.count - 1;
    [self.queueLock unlock];
    
    [self fetchContentAtIndex:batchIndex];
}

- (void)markCompletedAtIndex:(NSUInteger)i {
    [self.queueLock lock];
    
    [self.inFlightRequestIndices removeObject:@(i)];
    
    if (i < self.contentFetchQueue.count && self.contentFetchQueue[i] != [NSNull null]) {
        self.contentFetchQueue[i] = [NSNull null];
        self.completedBatches++;
    }
    
    [self cleanupIfAllCompleted];
    
    [self.queueLock unlock];
}

- (void)cleanupIfAllCompleted {
    if (self.completedBatches == self.contentFetchQueue.count && self.contentFetchQueue.count > 0) {
        CleverTapLogInternal(self.config.logLevel, @"%@: All %ld batches completed, clearing queue",
                             self, self.contentFetchQueue.count);
        
        [self.contentFetchQueue removeAllObjects];
        [self.inFlightRequestIndices removeAllObjects];
        self.completedBatches = 0;
    }
}

- (void)fetchContentAtIndex:(NSUInteger)i {
    // Check if already in-flight to prevent duplicates
    [self.queueLock lock];
    if ([self.inFlightRequestIndices containsObject:@(i)]) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Content fetch already processing index: %ld", self, i);
        [self.queueLock unlock];
        return;
    }
    [self.inFlightRequestIndices addObject:@(i)];
    [self.queueLock unlock];
    
    dispatch_group_enter(self.allRequestsGroup);
    
    dispatch_async(self.concurrentQueue, ^{
        NSArray *batch;
        [self.queueLock lock];
        if (i >= self.contentFetchQueue.count || self.contentFetchQueue[i] == [NSNull null]) {
            [self.queueLock unlock];
            [self.inFlightRequestIndices removeObject:@(i)];
            dispatch_group_leave(self.allRequestsGroup);
            return;
        }
        batch = [self.contentFetchQueue[i] copy];
        [self.queueLock unlock];
        
        dispatch_time_t semaphore_timeout = dispatch_time(DISPATCH_TIME_NOW,
                                                          self.semaphoreTimeout * NSEC_PER_SEC);
        if (dispatch_semaphore_wait(self.concurrencySemaphore, semaphore_timeout) != 0) {
            CleverTapLogDebug(self.config.logLevel, @"%@: Content fetch timed out waiting for concurrency slot at index: %ld", self, i);
            [self markCompletedAtIndex:i];
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                                 code:NSURLErrorTimedOut
                                             userInfo:@{
                NSLocalizedDescriptionKey: @"Content fetch request could not acquire concurrency slot",
                NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"Waited %.1f seconds for available slot", self.semaphoreTimeout]
            }];
            [self.delegate contentFetchManager:self didFailWithError:error];
            dispatch_group_leave(self.allRequestsGroup);
            return;
        }
        
        CleverTapLogDebug(self.config.logLevel, @"%@: Will send Content fetch for index: %ld", self, i);
        [self sendContentRequest:batch completed:^{
            [self markCompletedAtIndex:i];
            dispatch_semaphore_signal(self.concurrencySemaphore);
            dispatch_group_leave(self.allRequestsGroup);
        }];
    });
}

- (void)fetchContent {
    NSUInteger queueCount;
    
    [self.queueLock lock];
    queueCount = self.contentFetchQueue.count;
    [self.queueLock unlock];
    
    for (NSUInteger i = 0; i < queueCount; i++) {
        [self fetchContentAtIndex:i];
    }
}

- (NSString *)contentEndpoint {
    NSString *endpointDomain = self.domainOperations.redirectDomain;
    if (!endpointDomain) return nil;
    long long currentRequestTimestamp = (long long) [[[NSDate alloc] init] timeIntervalSince1970];
    NSString *endpointUrl = [[NSString alloc] initWithFormat:@"https://%@/content?os=iOS&t=%@&z=%@&ts=%lld",
                             endpointDomain, WR_SDK_REVISION, self.config.accountId, currentRequestTimestamp];
    return endpointUrl;
}

- (void)sendContentRequest:(NSArray *)events completed:(void(^)(void))completedBlock {
    void (^sendRequestBlock)(void) = ^{
        NSString *url = [self contentEndpoint];
        if (!url) {
            CleverTapLogDebug(self.config.logLevel, @"%@: Endpoint is not set, will not send content fetch", self);
            completedBlock();
            return;
        }
        
        NSDictionary *meta = [self.delegate contentFetchManagerGetBatchHeader:self];
        if (!meta) {
            CleverTapLogDebug(self.config.logLevel, @"%@: Batch header is nil, will not send content fetch", self);
            completedBlock();
            return;
        }
        
        NSMutableArray *params = [[NSMutableArray alloc] init];
        [params addObject:meta];
        [params addObjectsFromArray:events];
        CTRequest *request = [CTRequestFactory contentRequestWithConfig:self.config params:params url:url];
        
        [request onResponse:^(NSData * _Nullable data, NSURLResponse * _Nullable response) {
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if (httpResponse.statusCode == 200) {
                    CleverTapLogDebug(self.config.logLevel, @"%@: Content fetch response received successfully", self);
                    [self.delegate contentFetchManager:self didReceiveResponse:data];
                } else {
                    // Error cases - create appropriate NSError and call didFailWithError
                    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                    userInfo[NSLocalizedDescriptionKey] = [NSString stringWithFormat:@"Content fetch failed with HTTP status code %ld", (long)httpResponse.statusCode];
                    
                    if (httpResponse.statusCode == 429) {
                        CleverTapLogDebug(self.config.logLevel, @"%@: Content fetch request was rate limited (429). Consider reducing request frequency.", self);
                        userInfo[NSLocalizedFailureReasonErrorKey] = @"Request was rate limited by the server";
                    } else {
                        userInfo[NSLocalizedFailureReasonErrorKey] = [NSString stringWithFormat:@"HTTP request failed with status code %ld", (long)httpResponse.statusCode];
                    }
                    
                    NSError *httpError = [NSError errorWithDomain:NSURLErrorDomain
                                                             code:httpResponse.statusCode
                                                         userInfo:userInfo];
                    [self.delegate contentFetchManager:self didFailWithError:httpError];
                }
            } else {
                NSError *responseError = [NSError errorWithDomain:NSURLErrorDomain
                                                             code:NSURLErrorBadServerResponse
                                                         userInfo:@{
                    NSLocalizedDescriptionKey: @"Content fetch received unexpected response type",
                    NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:@"Expected NSHTTPURLResponse but received %@", [response class]]
                }];
                [self.delegate contentFetchManager:self didFailWithError:responseError];
            }
            
            completedBlock();
        }];
        [request onError:^(NSError * _Nullable error) {
            [self.delegate contentFetchManager:self didFailWithError:error];
            CleverTapLogDebug(self.config.logLevel, @"%@: Error Content fetch: %@", self, error.debugDescription);
            completedBlock();
        }];
        CleverTapLogInternal(self.config.logLevel, @"%@: Sending Content fetch request", self);
        [self.requestSender send:request];
    };
    
    if ([self.domainOperations needsHandshake]) {
        [self.domainOperations runSerialAsyncEnsureHandshake:^(BOOL success) {
            dispatch_async(self.concurrentQueue, ^{
                sendRequestBlock();
            });
        }];
    } else {
        sendRequestBlock();
    }
}

- (void)deviceIdWillChange {
    [self.dispatchQueueManager runSerialAsync:^{
        CleverTapLogInternal(self.config.logLevel, @"%@: Fetching content on deviceIdWillChange", self);
        
        // Send all requests (those in-flight will be filtered out)
        [self fetchContent];
        
        // Ensure all content fetch requests complete before user switch (both in-flight and newly started)
        dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.userSwitchTimeout * NSEC_PER_SEC));
        long result = dispatch_group_wait(self.allRequestsGroup, timeout);
        if (result != 0) {
            CleverTapLogDebug(self.config.logLevel,
                              @"%@: Content fetch requests timed out after %.0f seconds during user switch",
                              self, self.userSwitchTimeout);
        } else {
            CleverTapLogInternal(self.config.logLevel,
                                 @"%@: All content fetch requests completed successfully before user switch",
                                 self);
        }
        
        // Clean up
        [self.queueLock lock];
        [self.contentFetchQueue removeAllObjects];
        [self.inFlightRequestIndices removeAllObjects];
        self.completedBatches = 0;
        [self.queueLock unlock];
    }];
}

@end

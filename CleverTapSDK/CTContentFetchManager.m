//
//  ContentFetchManager.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 19.05.25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import "CTContentFetchManager.h"
#import "CTPreferences.h"
#import "CTRequestFactory.h"
#import "CTRequest.h"
#import "CleverTap.h"
#import "CTConstants.h"
#import "CTDispatchQueueManager.h"

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

@property (nonatomic, strong) dispatch_group_t allRequestsGroup;
@property (nonatomic, strong) NSMutableSet *inFlightRequestIndices;

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
        
        self.semaphoreTimeout = CLTAP_REQUEST_TIME_OUT_INTERVAL + 5;
        
        self.queueLock = [[NSLock alloc] init];
        self.concurrentQueue = dispatch_queue_create("com.clevertap.contentfetch", DISPATCH_QUEUE_CONCURRENT);
        int concurrencyCount = 5;
        self.concurrencySemaphore = dispatch_semaphore_create(concurrencyCount);
        self.contentFetchQueue = [[NSMutableArray alloc] init];
        
        self.allRequestsGroup = dispatch_group_create();
        self.inFlightRequestIndices = [[NSMutableSet alloc] init];
    }
    
    return self;
}

- (void)handleContentFetch:(NSDictionary *)jsonResp {
    NSArray *contentFetch = jsonResp[@"content_fetch"];
    if (!contentFetch) {
        return;
    }
    
    NSMutableArray *events = [[NSMutableArray alloc] init];
    for (NSDictionary *contentFetchItem in contentFetch) {
        NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:@{
            CLTAP_EVENT_NAME: @"content_fetch",
            CLTAP_EVENT_DATA: contentFetchItem
        }];
        
        // Call delegate to add event metadata
        [self.delegate contentFetchManager:self addMetadataToEvent:event ofType:CleverTapEventTypeRaised];
        
        [events addObject:event];
    }
    [self.queueLock lock];
    [self.contentFetchQueue addObject:events];
    NSUInteger batchIndex = self.contentFetchQueue.count - 1;
    [self.queueLock unlock];
    
    [self fetchContentAtIndex:batchIndex];
}

- (void)safeRemoveFromContentFetchQueueAt:(NSUInteger)i {
    [self.queueLock lock];
    
    [self.inFlightRequestIndices removeObject:@(i)];
    
    if (i < self.contentFetchQueue.count) {
        [self.contentFetchQueue removeObjectAtIndex:i];
    }
    
    if (self.contentFetchQueue.count == 0 &&
        [self.delegate respondsToSelector:@selector(contentFetchManagerDidCompleteAllRequests:)]) {
        [self.delegate contentFetchManagerDidCompleteAllRequests:self];
    }
    
    [self.queueLock unlock];
}

- (void)fetchContentAtIndex:(NSUInteger)i {
    // Check if already in-flight to prevent duplicates
    [self.queueLock lock];
    if ([self.inFlightRequestIndices containsObject:@(i)]) {
        [self.queueLock unlock];
        return;
    }
    [self.inFlightRequestIndices addObject:@(i)];
    [self.queueLock unlock];
    
    dispatch_group_enter(self.allRequestsGroup);
    
    dispatch_async(self.concurrentQueue, ^{
        NSArray *batch;
        [self.queueLock lock];
        if (i >= self.contentFetchQueue.count) {
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
            [self safeRemoveFromContentFetchQueueAt:i];
            dispatch_group_leave(self.allRequestsGroup);
            return;
        }
        
        NSDictionary *meta = [self.delegate contentFetchManagerGetBatchHeader:self];
        CTRequest *request = [self contentFetchRequest:batch withBatchHeader:meta];
        [self sendContentRequest:request completed:^{
            [self safeRemoveFromContentFetchQueueAt:i];
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

- (CTRequest *)contentFetchRequest:(NSArray *)events withBatchHeader:(NSDictionary *)batchHeader {
    NSDictionary *meta = batchHeader;
    NSMutableArray *params = [[NSMutableArray alloc] init];
    [params addObject:meta];
    [params addObjectsFromArray:events];
    CTRequest *ctRequest = [CTRequestFactory contentRequestWithConfig:self.config params:params domain:[self contentDomain]];
    return ctRequest;
}

// TODO: Resolve content domain (TBD)
- (NSString *)contentDomain {
    return @"sk1-content-staging.clevertap-prod.com";
}

- (void)sendContentRequest:(CTRequest *)request completed:(void(^)(void))completedBlock {
    void (^sendRequestBlock)(void) = ^{
        [request onResponse:^(NSData * _Nullable data, NSURLResponse * _Nullable response) {
            [self.delegate contentFetchManager:self didReceiveResponse:data];
            completedBlock();
        }];
        [request onError:^(NSError * _Nullable error) {
            completedBlock();
        }];
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
        // Send all requests (those in-flight will be filtered out)
        [self fetchContent];
        
        // Wait for all to complete (both in-flight and newly started)
        dispatch_group_wait(self.allRequestsGroup, DISPATCH_TIME_FOREVER);
        
        // Clean up
        [self.queueLock lock];
        [self.contentFetchQueue removeAllObjects];
        [self.inFlightRequestIndices removeAllObjects];
        [self.queueLock unlock];
    }];
}

@end

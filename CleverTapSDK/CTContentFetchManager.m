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

@interface CTContentFetchManager()

@property (nonatomic, strong) CTRequestSender *requestSender;
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) id<CTDomainOperations> domainOperations;
@property (nonatomic, strong) NSMutableArray *contentFetchQueue;

@property (nonatomic, strong) NSLock *queueLock;
@property (nonatomic, strong) dispatch_queue_t concurrentQueue;
@property (nonatomic, strong) dispatch_semaphore_t concurrencySemaphore;
@property NSTimeInterval semaphoreTimeout;

@end

@implementation CTContentFetchManager

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
                 requestSender:(CTRequestSender *)requestSender
               domainOperations:(id<CTDomainOperations>)domainOperations
                      delegate:(id<CTContentFetchManagerDelegate>)delegate {
    self = [super init];
    if (self) {
        self.config = config;
        self.requestSender = requestSender;
        self.domainOperations = domainOperations;
        self.delegate = delegate;
        
        self.semaphoreTimeout = CLTAP_REQUEST_TIME_OUT_INTERVAL + 5;

        self.queueLock = [[NSLock alloc] init];
        self.concurrentQueue = dispatch_queue_create("com.clevertap.contentfetch", DISPATCH_QUEUE_CONCURRENT);
        int concurrencyCount = 5;
        self.concurrencySemaphore = dispatch_semaphore_create(concurrencyCount);
        
        [self inflateQueue];
        if (self.contentFetchQueue.count > 0) {
            [self fetchContent];
        }
    }
    
    return self;
}

- (void)persistQueue {
    NSString *fileName = [self contentFetchFileName];
    NSMutableArray *contentFetchQueueCopy;
    [self.queueLock lock];
    contentFetchQueueCopy = [NSMutableArray arrayWithArray:[self.contentFetchQueue copy]];
    [self.queueLock unlock];
    [CTPreferences archiveObject:contentFetchQueueCopy forFileName:fileName config:self.config];
}

- (void)inflateQueue {
    self.contentFetchQueue = (NSMutableArray *)[CTPreferences unarchiveFromFile:[self contentFetchFileName] ofType:[NSMutableArray class] removeFile:YES];
    if (!self.contentFetchQueue) {
        self.contentFetchQueue = [NSMutableArray array];
    }
}

- (NSString *)contentFetchFileName {
    return [NSString stringWithFormat:@"clevertap-%@-content-fetch.plist", self.config.accountId];
}

- (void)handleContentFetch:(NSDictionary *)jsonResp {
    NSArray *contentFetch = jsonResp[@"content_fetch"];
    if (!contentFetch) {
        return;
    }
    
    NSMutableArray *events = [[NSMutableArray alloc] init];
    for (NSDictionary *contentFetchItem in contentFetch) {
        NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:@{
            @"type": @"event",
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
    dispatch_async(self.concurrentQueue, ^{
        NSArray *batch;
        [self.queueLock lock];
        if (i >= self.contentFetchQueue.count) {
            [self.queueLock unlock];
            return;
        }
        batch = [self.contentFetchQueue[i] copy];
        [self.queueLock unlock];
        
        dispatch_time_t semaphore_timeout = dispatch_time(DISPATCH_TIME_NOW,
                                                          self.semaphoreTimeout * NSEC_PER_SEC);
        if (dispatch_semaphore_wait(self.concurrencySemaphore, semaphore_timeout) != 0) {
            [self safeRemoveFromContentFetchQueueAt:i];
            return;
        }
        
        NSDictionary *meta = [self.delegate contentFetchManagerGetBatchHeader:self];
        CTRequest *request = [self contentFetchRequest:batch withBatchHeader:meta];
        [self sendContentRequest:request completed:^{
            [self safeRemoveFromContentFetchQueueAt:i];
            dispatch_semaphore_signal(self.concurrencySemaphore);
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
    CTRequest *ctRequest = [CTRequestFactory contentRequestWithConfig:self.config params:params domain:@"sk1-content-staging.clevertap-prod.com"];
    return ctRequest;
}

- (void)sendContentRequest:(CTRequest *)request completed:(void(^)(void))completedBlock {
    void (^sendRequestBlock)(void) = ^{
        [request onResponse:^(NSData * _Nullable data, NSURLResponse * _Nullable response) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Content fetch didReceiveResponse", self);
            [self.delegate contentFetchManager:self didReceiveResponse:data];
            completedBlock();
        }];
        [request onError:^(NSError * _Nullable error) {
            CleverTapLogDebug(self.config.logLevel, @"%@: Error Content Fetch: %@", self, error.debugDescription);
            completedBlock();
        }];
        CleverTapLogInternal(self.config.logLevel, @"%@: Sending content fetch request", self);
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

@end

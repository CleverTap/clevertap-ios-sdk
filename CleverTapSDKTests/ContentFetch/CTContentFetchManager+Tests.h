//
//  CTContentFetchManager+Tests.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 29.05.25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#ifndef CTContentFetchManager_Tests_h
#define CTContentFetchManager_Tests_h

@class CTContentFetchManager;

@interface CTContentFetchManager (Tests)

@property (nonatomic, strong) NSMutableArray *contentFetchQueue;
@property (nonatomic, strong) NSLock *queueLock;
@property (nonatomic, strong) NSMutableSet *inFlightRequestIndices;
@property NSTimeInterval semaphoreTimeout;
@property (nonatomic, strong) dispatch_queue_t concurrentQueue;

- (void)markCompletedAtIndex:(NSUInteger)i;
- (void)fetchContentAtIndex:(NSUInteger)i;

@end

#endif /* CTContentFetchManager_Tests_h */

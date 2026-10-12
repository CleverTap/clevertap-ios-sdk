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
@property NSTimeInterval userSwitchTimeout;
@property (nonatomic, strong) dispatch_queue_t concurrentQueue;

- (void)markCompletedAtIndex:(NSUInteger)i;
/// The primitive every completion path funnels through — override this, not the index-only form.
- (void)markCompletedAtIndex:(NSUInteger)i token:(NSUInteger)token;
- (void)fetchContentAtIndex:(NSUInteger)i;

@end

#endif /* CTContentFetchManager_Tests_h */

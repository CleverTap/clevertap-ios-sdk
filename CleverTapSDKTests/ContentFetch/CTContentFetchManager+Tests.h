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
- (void)markCompletedAtIndex:(NSUInteger)i;

@property (nonatomic, strong) NSMutableSet *inFlightRequestIndices;

@end

#endif /* CTContentFetchManager_Tests_h */

//
//  CTContentFetchManagerMock.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 29.05.25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import "CTContentFetchManagerMock.h"
#import "CTContentFetchManager+Tests.h"

@implementation CTContentFetchManagerMock

// Hooks the token variant because that is the primitive every completion path funnels through.
// The index-only method just forwards to it, so overriding that one would miss most calls.
- (void)markCompletedAtIndex:(NSUInteger)i token:(NSUInteger)token {
    [super markCompletedAtIndex:i token:token];

    [self.queueLock lock];
    if (self.contentFetchQueue.count == 0 && self.onAllRequestsCompleted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.onAllRequestsCompleted();
        });
    }
    [self.queueLock unlock];
}

@end

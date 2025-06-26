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

- (void)markCompletedAtIndex:(NSUInteger)i {
    [super markCompletedAtIndex:i];
    
    [self.queueLock lock];
    if (self.contentFetchQueue.count == 0 && self.onAllRequestsCompleted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.onAllRequestsCompleted();
        });
    }
    [self.queueLock unlock];
}

@end

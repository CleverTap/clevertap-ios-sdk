//
//  CTLocalDataStore+Tests.h
//  CleverTapSDKTests
//
//  Created by Akash Malhotra on 11/12/24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTLocalDataStore.h"

@interface CTLocalDataStore (Tests)
- (void)runOnBackgroundQueue:(void (^)(void))taskBlock;
@property (nonatomic, readonly) dispatch_queue_t backgroundQueue;

// Exposed so a test can clear the persisted profile between cases.
- (NSString *)profileFileName;
@end


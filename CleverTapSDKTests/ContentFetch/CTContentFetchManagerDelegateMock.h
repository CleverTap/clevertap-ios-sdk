//
//  CTContentFetchManagerDelegateMock.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 29.05.25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CTContentFetchManagerDelegate;

@interface CTContentFetchManagerDelegateMock : NSObject <CTContentFetchManagerDelegate>

@property (nonatomic, strong) NSDictionary *batchHeader;
@property (nonatomic, strong) NSMutableArray *receivedResponses;
@property (nonatomic, strong) NSMutableArray *receivedErrors;
@property (nonatomic, strong) NSMutableArray *metadataEvents;

@property (nonatomic, copy, nullable) void (^onResponseReceived)(NSData *data);
@property (nonatomic, copy, nullable) void (^onErrorReceived)(NSError *error);
@property (nonatomic, copy, nullable) void (^onMetadataAdded)(NSDictionary *event);

/// Hold the parse completion instead of running it, standing in for a delegate that parses on
/// another queue. Release it with `runHeldCompletion`.
@property (nonatomic, assign) BOOL holdsCompletion;

/// The completion captured while `holdsCompletion` was set, if any.
@property (nonatomic, copy, nullable) dispatch_block_t heldCompletion;

/// Run and clear `heldCompletion`. Returns NO when nothing was held.
- (BOOL)runHeldCompletion;

@end

NS_ASSUME_NONNULL_END

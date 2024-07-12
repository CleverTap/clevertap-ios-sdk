//
//  CTMultiDelegateManager.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 10.10.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTAttachToBatchHeaderDelegate.h"
#import "CTSwitchUserDelegate.h"
#import "CTBatchSentDelegate.h"
#import "CTQueueType.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTMultiDelegateManager : NSObject

- (void)addAttachToHeaderDelegate:(id<CTAttachToBatchHeaderDelegate>)delegate;
- (void)removeAttachToHeaderDelegate:(id<CTAttachToBatchHeaderDelegate>)delegate;
- (BatchHeaderKeyPathValues)notifyAttachToHeaderDelegatesAndCollectKeyPathValues:(CTQueueType)queueType;

- (void)addSwitchUserDelegate:(id<CTSwitchUserDelegate>)delegate;
- (void)removeSwitchUserDelegate:(id<CTSwitchUserDelegate>)delegate;
- (void)notifyDelegatesDeviceIdDidChange:(NSString *)newDeviceId;

- (void)addBatchSentDelegate:(id<CTBatchSentDelegate>)delegate;
- (void)removeBatchSentDelegate:(id<CTBatchSentDelegate>)delegate;
- (void)notifyDelegatesBatchDidSend:(NSArray *)batchWithHeader withSuccess:(BOOL)success withQueueType:(CTQueueType)queueType;

@end

NS_ASSUME_NONNULL_END

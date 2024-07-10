//
//  CTMultiDelegateManager.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 10.10.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTMultiDelegateManager.h"
#import "CTConstants.h"
#import "CTBatchSentDelegateHelper.h"

@interface CTMultiDelegateManager ()

@property (nonatomic, strong) NSHashTable<id<CTAttachToBatchHeaderDelegate>> *attachToHeaderDelegates;
@property (nonatomic, strong) NSHashTable<id<CTSwitchUserDelegate>> *switchUserDelegates;
@property (nonatomic, strong) NSHashTable<id<CTBatchSentDelegate>> *batchSentDelegates;

@end

@implementation CTMultiDelegateManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _attachToHeaderDelegates = [NSHashTable weakObjectsHashTable];
        _switchUserDelegates = [NSHashTable weakObjectsHashTable];
        _batchSentDelegates = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

#pragma mark CTAttachToBatchHeaderDelegate
- (void)addAttachToHeaderDelegate:(id<CTAttachToBatchHeaderDelegate>)delegate {
    [self.attachToHeaderDelegates addObject:delegate];
}

- (void)removeAttachToHeaderDelegate:(id<CTAttachToBatchHeaderDelegate>)delegate {
    [self.attachToHeaderDelegates removeObject:delegate];
}

- (BatchHeaderKeyPathValues)notifyAttachToHeaderDelegatesAndCollectKeyPathValues:(CTQueueType)queueType {
    NSMutableDictionary<NSString *, id> *header = [NSMutableDictionary dictionary];
    for (id<CTAttachToBatchHeaderDelegate> delegate in self.attachToHeaderDelegates) {
        NSDictionary<NSString *, id> *additionalHeader = [delegate onBatchHeaderCreationForQueue:queueType];
        if (additionalHeader) {
            [header addEntriesFromDictionary:additionalHeader];
        }
    }
    return [header copy];
}

#pragma mark CTSwitchUserDelegate
- (void)addSwitchUserDelegate:(id<CTSwitchUserDelegate>)delegate {
    [self.switchUserDelegates addObject:delegate];
}

- (void)removeSwitchUserDelegate:(id<CTSwitchUserDelegate>)delegate {
    [self.switchUserDelegates removeObject:delegate];
}

- (void)notifyDelegatesDeviceIdDidChange:(NSString *)newDeviceId {
    for (id<CTSwitchUserDelegate> delegate in self.switchUserDelegates) {
        if (delegate && [delegate respondsToSelector:@selector(deviceIdDidChange:)]) {
            [delegate deviceIdDidChange:newDeviceId];
        }
    }
}

#pragma mark CTBatchSentDelegate
- (void)addBatchSentDelegate:(id<CTBatchSentDelegate>)delegate {
    [self.batchSentDelegates addObject:delegate];
}

- (void)removeBatchSentDelegate:(id<CTBatchSentDelegate>)delegate {
    [self.batchSentDelegates removeObject:delegate];
}

- (void)notifyDelegatesBatchDidSend:(NSArray *)batchWithHeader withSuccess:(BOOL)success withQueueType:(CTQueueType)queueType{
    NSNumber *isAppLaunched = nil;
    for (id<CTBatchSentDelegate> batchSentDelegate in self.batchSentDelegates) {
        if ([batchSentDelegate respondsToSelector:@selector(onBatchSent: withSuccess:withQueueType:)]) {
            [batchSentDelegate onBatchSent:batchWithHeader withSuccess:success withQueueType:queueType];
        }
        if ([batchSentDelegate respondsToSelector:@selector(onAppLaunchedWithSuccess:)]) {
            if (isAppLaunched == nil) {
                // Check once for the batch
                isAppLaunched = [NSNumber numberWithBool:[CTBatchSentDelegateHelper isBatchWithAppLaunched:batchWithHeader]];
            }
            if ([isAppLaunched boolValue]) {
                [batchSentDelegate onAppLaunchedWithSuccess:success];
            }
        }
    }
}

@end

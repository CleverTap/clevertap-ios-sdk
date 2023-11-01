//
//  CTDelegateManager.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 10.10.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTDelegateManager.h"
#import "CTConstants.h"

@interface CTDelegateManager ()

@property (nonatomic, strong) NSHashTable<id<CTAttachToBatchHeaderDelegate>> *attachToHeaderDelegates;
@property (nonatomic, strong) NSHashTable<id<CTSwitchUserDelegate>> *switchUserDelegates;
@property (nonatomic, strong) NSHashTable<id<CTBatchSentDelegate>> *batchSentDelegates;

@end

// TODO: rename to CTMultiDelegateManager
@implementation CTDelegateManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _attachToHeaderDelegates = [NSHashTable weakObjectsHashTable];
        _switchUserDelegates = [NSHashTable weakObjectsHashTable];
        _switchUserDelegates = [NSHashTable weakObjectsHashTable];

    }
    return self;
}

- (void)addAttachToHeaderDelegate:(id<CTAttachToBatchHeaderDelegate>)delegate {
    [self.attachToHeaderDelegates addObject:delegate];
}

- (void)removeAttachToHeaderDelegate:(id<CTAttachToBatchHeaderDelegate>)delegate {
    [self.attachToHeaderDelegates removeObject:delegate];
}

- (BatchHeaderKeyPathValues)notifyAttachToHeaderDelegatesAndCollectKeyPathValues {
    NSMutableDictionary<NSString *, id> *header = [NSMutableDictionary dictionary];
    for (id<CTAttachToBatchHeaderDelegate> delegate in self.attachToHeaderDelegates) {
        NSDictionary<NSString *, id> *additionalHeader = [delegate onBatchHeaderCreation];
        if (additionalHeader) {
            [header addEntriesFromDictionary:additionalHeader];
        }
    }
    return [header copy];
}

- (void)addSwitchUserDelegate:(id<CTSwitchUserDelegate>)delegate {
    [self.switchUserDelegates addObject:delegate];
}

- (void)removeSwitchUserDelegate:(id<CTSwitchUserDelegate>)delegate {
    [self.switchUserDelegates addObject:delegate];
}

- (void)notifyDelegatesDeviceIdDidChange:(NSString *)newDeviceId {
    for (id<CTSwitchUserDelegate> delegate in self.switchUserDelegates) {
        if (delegate && [delegate respondsToSelector:@selector(deviceIdDidChange:)]) {
            [delegate deviceIdDidChange:newDeviceId];
        }
    }
}

- (void)addBatchSentDelegate:(id<CTBatchSentDelegate>)delegate {
    [self.batchSentDelegates addObject:delegate];
}

- (void)removeBatchSentDelegate:(id<CTBatchSentDelegate>)delegate {
    [self.batchSentDelegates addObject:delegate];
}

- (void)notifyDelegatesBatchDidSend:(NSArray *)batchWithHeader withSuccess:(BOOL)success {
    NSNumber *isAppLaunched = nil;
    for (id<CTBatchSentDelegate> batchSentDelegate in self.batchSentDelegates) {
        if ([batchSentDelegate respondsToSelector:@selector(onBatchSent: withSuccess:)]) {
            [batchSentDelegate onBatchSent:batchWithHeader withSuccess:success];
        }
        if ([batchSentDelegate respondsToSelector:@selector(onAppLaunchedWithSuccess:)]) {
            if (isAppLaunched == nil) {
                // Find the event with evtName == "App Launched"
                for (NSDictionary *event in batchWithHeader) {
                    if ([event[CLTAP_EVENT_NAME] isEqualToString:CLTAP_APP_LAUNCHED_EVENT]) {
                        isAppLaunched = [NSNumber numberWithBool:YES];
                        break;
                    }
                }
            }
            if ([isAppLaunched boolValue]) {
                [batchSentDelegate onAppLaunchedWithSuccess:success];
            }
        }
    }
}

@end

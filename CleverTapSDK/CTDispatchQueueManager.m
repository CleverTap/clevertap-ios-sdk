//
//  CTDispatchQueueManager.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 03/07/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTDispatchQueueManager.h"
#import "CleverTapInstanceConfigPrivate.h"
#import "CTUIUtils.h"

@interface CTDispatchQueueManager ()
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@end

@implementation CTDispatchQueueManager

static const void *const kQueueKey = &kQueueKey;
static const void *const kNotificationQueueKey = &kNotificationQueueKey;
dispatch_queue_t _notificationQueue;
dispatch_queue_t _serialQueue;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config {
    
    if ((self = [super init])) {
        self.config = config;
        
        _serialQueue = dispatch_queue_create([_config.queueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_serialQueue, kQueueKey, (__bridge void *)self, NULL);
        
        if (!_config.analyticsOnly && ![CTUIUtils runningInsideAppExtension]) {
            _notificationQueue = dispatch_queue_create([[NSString stringWithFormat:@"com.clevertap.notificationQueue:%@", _config.accountId] UTF8String], DISPATCH_QUEUE_SERIAL);
            dispatch_queue_set_specific(_notificationQueue, kNotificationQueueKey, (__bridge void *)self, NULL);
        }
    }
    return self;
}

- (void)runSerialAsync:(void (^)(void))taskBlock {
    if ([self inSerialQueue]) {
        taskBlock();
    } else {
        dispatch_async(_serialQueue, taskBlock);
    }
}

- (BOOL)inSerialQueue {
    CTDispatchQueueManager *currentQueue = (__bridge id) dispatch_get_specific(kQueueKey);
    return currentQueue == self;
}

- (void)runOnNotificationQueue:(void (^)(void))taskBlock {
    if ([self inNotificationQueue]) {
        taskBlock();
    } else {
        dispatch_async(_notificationQueue, taskBlock);
    }
}

- (BOOL)inNotificationQueue {
    CTDispatchQueueManager *currentQueue = (__bridge id) dispatch_get_specific(kNotificationQueueKey);
    return currentQueue == self;
}

@end

//
//  CTDispatchQueueManager.h
//  CleverTapSDK
//
//  Created by Akash Malhotra on 03/07/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CleverTapInstanceConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTDispatchQueueManager : NSObject

- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig*)config;
- (void)runSerialAsync:(void (^)(void))taskBlock;
- (void)runOnNotificationQueue:(void (^)(void))taskBlock;

@end

NS_ASSUME_NONNULL_END

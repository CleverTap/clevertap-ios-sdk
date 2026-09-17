//
//  CTDispatchQueueManager.h
//  CleverTapSDK
//
//  Created by Akash Malhotra on 03/07/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
// This header is copied into PrivateHeaders of the built framework.
// CleverTapInstanceConfig.h is copied into Headers, which is a different directory.
// A quoted import looks only next to this file, so it fails there.
// The angled form goes through the framework module instead.
#if __has_include(<CleverTapSDK/CleverTapInstanceConfig.h>)
#import <CleverTapSDK/CleverTapInstanceConfig.h>
#else
#import "CleverTapInstanceConfig.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CTDispatchQueueManager : NSObject

- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig*)config;
- (void)runSerialAsync:(void (^)(void))taskBlock;
- (void)runOnNotificationQueue:(void (^)(void))taskBlock;
- (BOOL)inSerialQueue;

@end

NS_ASSUME_NONNULL_END

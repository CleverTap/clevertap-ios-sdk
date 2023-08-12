//
//  CTRetryManager.h
//  CleverTapSDK
//
//  Created by Akash Malhotra on 10/08/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CleverTapInstanceConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTRetryManager : NSObject

@property (nonatomic, assign) int sendQueueFails;

- (instancetype)initWithConfig:(CleverTapInstanceConfig*)config;

- (void)resetFailsCounter;
- (void)incrementFailsCounter;
- (int)getDelayFrequency;

@end

NS_ASSUME_NONNULL_END

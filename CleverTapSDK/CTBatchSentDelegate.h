//
//  CTBatchSentDelegate.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 12.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTQueueType.h"

@protocol CTBatchSentDelegate <NSObject>

@optional
- (void)onBatchSent:(NSArray *)batchWithHeader withSuccess:(BOOL)success withQueueType:(CTQueueType)queueType;

@optional
- (void)onAppLaunchedWithSuccess:(BOOL)success;

@end

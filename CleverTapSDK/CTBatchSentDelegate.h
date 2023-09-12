//
//  CTBatchSentDelegate.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 12.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CTBatchSentDelegate <NSObject>

@optional
- (void)onBatchSent:(NSArray *)batchWithHeader withSuccess:(BOOL)success;

@optional
- (void)onAppLaunchedWithSuccess:(BOOL)success;

@end

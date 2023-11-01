//
//  CTBatchSentDelegateHelper.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 1.11.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTBatchSentDelegateHelper : NSObject

+ (BOOL)isBatchWithAppLaunched:(NSArray *)batchWithHeader;

@end

NS_ASSUME_NONNULL_END

//
//  CTAttachToHeaderDelegate.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 29.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CTAttachToHeaderDelegate <NSObject>

- (NSDictionary<NSString *, id> *)onBatchHeaderCreation;

@end

NS_ASSUME_NONNULL_END

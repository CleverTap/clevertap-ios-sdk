//
//  LimitAdapter.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 31.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CTLimitType){
    CTLimitTypeEver,
    CTLimitTypeSession,
    CTLimitTypeSeconds,
    CTLimitTypeMinutes,
    CTLimitTypeHours,
    CTLimitTypeDays,
    CTLimitTypeWeeks,
    CTLimitTypeOnEvery,
    CTLimitTypeOnExactly
};

@interface CTLimitAdapter : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithJSON:(NSDictionary *)limitJSON;

- (CTLimitType)limitType;
- (NSInteger)limit;
- (NSInteger)frequency;
- (BOOL)isEmpty;

@end

NS_ASSUME_NONNULL_END

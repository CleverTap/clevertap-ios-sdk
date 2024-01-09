//
//  CTImpressionManager.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 18.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTSwitchUserDelegate.h"
#import "CTMultiDelegateManager.h"
#import "CTClock.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTImpressionManager : NSObject <CTSwitchUserDelegate>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId
                  delegateManager:(CTMultiDelegateManager *)delegateManager;

- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId
                  delegateManager:(CTMultiDelegateManager *)delegateManager
                            clock:(id <CTClock>)clock
                           locale:(NSLocale *)locale;

- (void)recordImpression:(NSString *)campaignId;

- (NSInteger)perSessionTotal;

- (NSInteger)perSession:(NSString *)campaignId;

- (NSInteger)perSecond:(NSString *)campaignId seconds:(NSInteger)seconds;

- (NSInteger)perMinute:(NSString *)campaignId minutes:(NSInteger)minutes;

- (NSInteger)perHour:(NSString *)campaignId hours:(NSInteger)hours;

- (NSInteger)perDay:(NSString *)campaignId days:(NSInteger)days;

- (NSInteger)perWeek:(NSString *)campaignId weeks:(NSInteger)weeks;

- (NSMutableArray *)getImpressions:(NSString *)campaignId;

- (void)removeImpressions:(NSString *)campaignId;

- (void)resetSession;

@end

NS_ASSUME_NONNULL_END

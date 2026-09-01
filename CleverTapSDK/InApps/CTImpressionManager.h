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

/**
 The word that identifies this store inside its preference keys, for example @c impressions.
 Two managers with the same value share storage, so each channel needs its own.

 Called @c storageNamespace rather than @c namespace because @c namespace is a reserved word in
 Objective-C++ and would break any consumer compiling this header from a @c .mm file.
 */
@property (nonatomic, copy, readonly) NSString *storageNamespace;

- (instancetype)init NS_UNAVAILABLE;

/// Uses the in-app namespace. Kept so existing call sites and stored keys are unaffected.
- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId
                  delegateManager:(CTMultiDelegateManager *)delegateManager;

- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId
                  delegateManager:(CTMultiDelegateManager *)delegateManager
                 storageNamespace:(NSString *)storageNamespace;

- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId
                  delegateManager:(CTMultiDelegateManager *)delegateManager
                            clock:(id <CTClock>)clock
                           locale:(NSLocale *)locale;

- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId
                  delegateManager:(CTMultiDelegateManager *)delegateManager
                 storageNamespace:(NSString *)storageNamespace
                            clock:(id <CTClock>)clock
                           locale:(NSLocale *)locale NS_DESIGNATED_INITIALIZER;

- (void)recordImpression:(NSString *)campaignId;

/**
 Records one impression, and says whether to keep the timestamp on disk.

 The session counts are always updated; they live in memory and are cheap. The timestamp is a
 different matter, because the whole saved list for the campaign is rewritten on every append, so it
 gets longer and slower the more impressions there are.

 The saved timestamps have exactly one reader: matching @c frequencyLimits and @c occurrenceLimits.
 A campaign with neither has nothing that will ever look at them, so passing @c NO leaves them out.

 In-app always passes @c YES, through @c recordImpression: above. Native Display passes @c NO for the
 campaigns it knows have no such limits, because its impressions are driven by the app rather than by
 the SDK and there is no upper bound on how many arrive.
 */
- (void)recordImpression:(NSString *)campaignId storeTimestamp:(BOOL)storeTimestamp;

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

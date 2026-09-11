//
//  CTNdFCManager.h
//  CleverTapSDK
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTAttachToBatchHeaderDelegate.h"
#import "CTSwitchUserDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@class CleverTapInstanceConfig;
@class CTImpressionManager;
@class CTInAppTriggerManager;
@class CTMultiDelegateManager;

/**
 Frequency caps for Native Display. The Native Display version of @c CTInAppFCManager.

 It handles the caps that work by counting how many times a campaign was shown. Each campaign has a
 lifetime cap (@c tlc), a daily cap (@c tdc) and a session cap (@c mdc). The account has two more,
 @c ndmp for the day and @c ndmc for the session.

 Two flags can skip caps. They skip different amounts. @c efc skips every cap.
 @c excludeGlobalFCaps skips only the two account caps. The campaign still has to obey @c tlc,
 @c tdc and @c mdc. In-app treats both flags the same. Native Display does not.

 @c frequencyLimits and @c occurrenceLimits are not checked here. The SDK checks them earlier. It
 then sends the campaigns that pass in @c adUnit_eval. The server sends content only for those.
 @c CTInAppFCManager does check them a second time. This is the one place the two differ on purpose.
 */
@interface CTNdFCManager : NSObject <CTAttachToBatchHeaderDelegate, CTSwitchUserDelegate>

@property (nonatomic, strong, readonly) CleverTapInstanceConfig *config;
@property (atomic, copy, readonly) NSString *deviceId;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
               delegateManager:(CTMultiDelegateManager *)delegateManager
                      deviceId:(NSString *)deviceId
             impressionManager:(CTImpressionManager *)impressionManager
                triggerManager:(CTInAppTriggerManager *)triggerManager NS_DESIGNATED_INITIALIZER;

/**
 Whether the server has set either account limit, @c ndmp for the day or @c ndmc for the session.

 Neither is set until a response carries @c ndmc. An account that never receives it has no account
 limit of any kind. Only the log line that warns about missing view reports reads this. The caps
 themselves do not need it. @c canShowCampaign: already lets an unset limit through.
 */
- (BOOL)hasAccountCaps;

/**
 The campaign id this unit's counts are stored under. Empty string if the unit has none.

 Always @c ti, which is the campaign. Never @c wzrk_id. A @c wzrk_id is the @c ti plus a suffix. The
 suffix changes on every send. A campaign that runs again gets a new @c wzrk_id. Its counts would
 start from zero. The suffix is not always a date either. Nothing here tries to read it.

 It lives here, next to the caps, and not at the call site. Every store uses what this returns as its
 key. They match only as long as they all ask the same place.
 */
+ (NSString *)campaignIdFrom:(nullable NSDictionary *)unit;

- (NSString *)storageKeyWithSuffix:(NSString *)suffix;

/// Resets the daily counts if the date has changed. Lifetime counts are not touched.
- (void)checkUpdateDailyLimits;

/**
 Whether this campaign can be shown right now, under all the counting caps.

 @param campaignId the @c ti, which is the campaign. Never @c wzrk_id. A @c wzrk_id changes on every
        send. It would restart the counts.
 @param excludeFromCaps @c efc. Skips every cap.
 @param excludeGlobalCaps @c excludeGlobalFCaps. Skips only the two account caps, @c ndmp for the day
        and @c ndmc for the session. The campaign's own @c tlc, @c tdc and @c mdc still apply. This
        flag skips less than @c efc. The two are not the same.
 @param totalLifetimeCount @c tlc, or -1 for no limit.
 @param totalDailyCount @c tdc, or -1 for no limit.
 @param maxPerSession @c mdc, or -1 for no limit.

 @note Native Display never sends @c efc, @c tlc, @c tdc or @c mdc. Those four belong to in-app. A
       Native Display campaign puts its own cap in @c frequencyLimits or @c occurrenceLimits. The
       gate in @c CleverTap.m passes these four parameters unset.
 */
- (BOOL)canShowCampaign:(NSString *)campaignId
        excludeFromCaps:(BOOL)excludeFromCaps
      excludeGlobalCaps:(BOOL)excludeGlobalCaps
     totalLifetimeCount:(int)totalLifetimeCount
        totalDailyCount:(int)totalDailyCount
          maxPerSession:(int)maxPerSession;

/**
 The same check as @c canShowCampaign:, with the cap that blocked the campaign named.

 Returns nil when the campaign can still be shown. Returns a short sentence when a cap is full. The
 sentence names the cap and prints the count against the limit. It is written for a log line. Do not
 parse it.

 Five caps can block a campaign. Three belong to the campaign, @c tlc, @c tdc and @c mdc. Two belong
 to the account, @c ndmc and @c ndmp. A caller that only needs a yes or no should use
 @c canShowCampaign:.

 The parameters mean what they mean in @c canShowCampaign:.
 */
- (nullable NSString *)reasonCampaignIsHeldBack:(NSString *)campaignId
                                excludeFromCaps:(BOOL)excludeFromCaps
                              excludeGlobalCaps:(BOOL)excludeGlobalCaps
                             totalLifetimeCount:(int)totalLifetimeCount
                                totalDailyCount:(int)totalDailyCount
                                  maxPerSession:(int)maxPerSession;

/**
 Records one display: the impression, the campaign's daily and lifetime counts, and the day total.

 @param storeTimestamp whether to save the impression time on disk. Pass @c YES only for a campaign
        that has @c frequencyLimits or @c occurrenceLimits. Matching those is the only thing that
        ever reads saved times. Native Display impressions come from the app. There is no limit on
        how many arrive. A time saved for each one would grow a list nobody reads. See
        @c CTImpressionManager @c recordImpression:storeTimestamp:.
 */
- (void)didShowCampaign:(NSString *)campaignId storeTimestamp:(BOOL)storeTimestamp;

/// Saves the account limits the server sends with each response. Pass -1 for no limit.
- (void)updateGlobalLimitsPerDay:(int)perDay andPerSession:(int)perSession;

/// Deletes the counts, impressions and triggers for campaigns the server says are gone.
- (void)removeStaleCampaignCounts:(NSArray *)staleCampaigns;

/// How many Native Display units the SDK showed today. Sent to the server as @c ndmp.
- (int)shownTodayCount;

@end

NS_ASSUME_NONNULL_END

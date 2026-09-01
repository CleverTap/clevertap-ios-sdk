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

 Two flags can skip caps, and they skip different amounts. @c efc skips every cap.
 @c excludeGlobalFCaps skips only the two account caps, so the campaign still has to obey @c tlc,
 @c tdc and @c mdc. In-app treats both flags the same. Native Display does not.

 @c frequencyLimits and @c occurrenceLimits are not checked here. The SDK checks them earlier and
 sends the campaigns that pass in @c adUnit_eval. The server then sends content only for those.
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
 Whether the server sent any frequency cap settings with this unit.

 Only these units are capped and counted. A unit without them is left alone, so display units that
 already exist keep working and never add to the account's daily and session totals.
 */
+ (BOOL)isFcapManaged:(nullable NSDictionary *)unit;

/**
 The campaign id this unit's counts are stored under. Empty string if the unit has none.

 Always @c ti, which is the campaign. Never @c wzrk_id. A @c wzrk_id is the @c ti plus a suffix that
 changes on every send, so a campaign that runs again gets a new one and its counts start from zero.
 The suffix is not always a date either, so nothing here tries to read it.

 It lives here, next to the caps, and not at the call site. Every store uses what this returns as its
 key, and they only match as long as they all ask the same place.
 */
+ (NSString *)targetIdFrom:(nullable NSDictionary *)unit;

- (NSString *)storageKeyWithSuffix:(NSString *)suffix;

/// Resets the daily counts if the date has changed. Lifetime counts are not touched.
- (void)checkUpdateDailyLimits;

/**
 Whether this campaign can be shown right now, under all the counting caps.

 @param targetId the @c ti, which is the campaign. Never @c wzrk_id, which changes on every send and
        would restart the counts.
 @param excludeFromCaps @c efc. Skips every cap.
 @param excludeGlobalCaps @c excludeGlobalFCaps. Skips only the two account caps, @c ndmp for the day
        and @c ndmc for the session. The campaign's own @c tlc, @c tdc and @c mdc still apply, so this
        flag skips less than @c efc and the two are not the same.
 @param totalLifetimeCount @c tlc, or -1 for no limit.
 @param totalDailyCount @c tdc, or -1 for no limit.
 @param maxPerSession @c mdc, or negative to use the default.
 */
- (BOOL)canShowTarget:(NSString *)targetId
      excludeFromCaps:(BOOL)excludeFromCaps
    excludeGlobalCaps:(BOOL)excludeGlobalCaps
   totalLifetimeCount:(int)totalLifetimeCount
      totalDailyCount:(int)totalDailyCount
        maxPerSession:(int)maxPerSession;

/**
 Records one display: the impression, the campaign's daily and lifetime counts, and the day total.

 @param storeTimestamp whether to save the impression time on disk. Pass @c YES only for a campaign
        that has @c frequencyLimits or @c occurrenceLimits, because matching those is the only thing
        that ever reads saved times. Native Display impressions come from the app and there is no
        limit on how many arrive, so saving a time for each one would grow a list nobody reads. See
        @c CTImpressionManager @c recordImpression:storeTimestamp:.
 */
- (void)didShowTarget:(NSString *)targetId storeTimestamp:(BOOL)storeTimestamp;

/// Saves the account limits the server sends with each response. Pass -1 for no limit.
- (void)updateGlobalLimitsPerDay:(int)perDay andPerSession:(int)perSession;

/// Deletes the counts, impressions and triggers for campaigns the server says are gone.
- (void)removeStaleTargetCounts:(NSArray *)staleTargets;

/// How many Native Display units the SDK showed today. Sent to the server as @c ndmp.
- (int)shownTodayCount;

@end

NS_ASSUME_NONNULL_END

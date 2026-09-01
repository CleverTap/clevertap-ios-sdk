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
 Counter frequency caps for the Native Display channel. The sibling of @c CTInAppFCManager.

 It checks the caps that work by counting how many times something was shown:
 per-target lifetime (@c tlc) and daily (@c tdc), per-target session (@c mdc), the account session
 max (@c ndmc) and the account daily max (@c ndmp).

 There are two exclusion flags and one is wider than the other. @c efc skips every one of these
 caps. @c excludeGlobalFCaps skips only the two account-wide ones, so a target that opted out of the
 account maximums still has to obey its own limits. In-app treats both as one flag; this does not.

 The advanced rules, @c frequencyLimits and @c occurrenceLimits, are not checked here. The SDK
 already checked them earlier and sent the ids that passed in @c adUnit_eval, and the server sends
 content back only for those ids. Checking again now would repeat a decision that has already been
 made and acted on. This is the one place the API deliberately differs from @c CTInAppFCManager,
 which does check them a second time.

 The methods take plain numbers and strings instead of a model object, because Native Display has no
 notification class to pass around.
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
 Whether a unit carries any frequency-cap settings at all.

 Only these units are checked against the caps and counted. A unit with none of these fields is
 left alone, so display units that exist today keep working and never add to the account's daily
 and session totals.
 */
+ (BOOL)isFcapManaged:(nullable NSDictionary *)unit;

- (NSString *)storageKeyWithSuffix:(NSString *)suffix;

/// Rolls the daily counters over if the date has changed. Lifetime counts are kept.
- (void)checkUpdateDailyLimits;

/**
 Whether this target can be shown right now, under all of the counting caps.

 @param targetId the @c ti. Never @c wzrk_id, which changes daily and would reset every count.
 @param excludeFromCaps @c efc, which skips all of these caps.
 @param excludeGlobalCaps @c excludeGlobalFCaps, which skips only the two account-wide caps, the
        daily @c ndmp and the session @c ndmc. The target's own @c tlc, @c tdc and @c mdc still
        apply. This flag skips less than @c efc does, so the two are not interchangeable.
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

/// Records one display: the impression, the target's today and lifetime counts, and the day total.
- (void)didShowTarget:(NSString *)targetId;

/// Saves the account maximums the server sends with each response. Pass -1 for no limit.
- (void)updateGlobalLimitsPerDay:(int)perDay andPerSession:(int)perSession;

/// Deletes the counts, impressions and triggers for targets the server says no longer exist.
- (void)removeStaleTargetCounts:(NSArray *)staleTargets;

/// How many Native Display units the SDK has shown today. Sent as @c ndmp on a request.
- (int)shownTodayCount;

@end

NS_ASSUME_NONNULL_END

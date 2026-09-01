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

 It enforces the caps that are counted rather than evaluated:
 per-target lifetime (@c tlc) and daily (@c tdc), per-target session (@c mdc), the global session
 ceiling (@c ndmc) and the global daily ceiling (@c ndmp).

 There are two exclusion flags and they are not the same size. @c efc skips every counter cap.
 @c excludeGlobalFCaps skips only the two account-wide ones, so a target that opted out of the
 account budget still owes its own limits. In-app collapses both into a single flag; this does not.

 The advanced rules, @c frequencyLimits and @c occurrenceLimits, are not re-checked here. For Native
 Display the vote the SDK sends in @c adUnit_eval is the only enforcement the server relies on, so
 re-checking at delivery would just repeat a decision the server already deferred to. This is the one
 place the API deliberately differs from @c CTInAppFCManager, which does re-check.

 The API takes primitives instead of a model object because Native Display has no notification class
 to pass around.
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
 Whether a unit carries any frequency-cap configuration at all.

 Only these units are gated and counted. Anything without one of these markers passes through
 untouched, so display units that exist today keep working and never eat into the account's Native
 Display budget.
 */
+ (BOOL)isFcapManaged:(nullable NSDictionary *)unit;

- (NSString *)storageKeyWithSuffix:(NSString *)suffix;

/// Rolls the daily counters over if the date has changed. Lifetime counts are kept.
- (void)checkUpdateDailyLimits;

/**
 Whether this target can be surfaced right now under every counter cap.

 @param targetId the @c ti. Never @c wzrk_id, which changes daily and would reset every count.
 @param excludeFromCaps @c efc, which skips every counter cap.
 @param excludeGlobalCaps @c excludeGlobalFCaps, which skips both account-wide caps, the daily
        @c ndmp and the session @c ndmc. The target's own @c tlc, @c tdc and @c mdc still apply.
        This is the narrower of the two flags, so the pair is not interchangeable.
 @param totalLifetimeCount @c tlc, or -1 for uncapped.
 @param totalDailyCount @c tdc, or -1 for uncapped.
 @param maxPerSession @c mdc, or negative for the per-target session default.
 */
- (BOOL)canShowTarget:(NSString *)targetId
      excludeFromCaps:(BOOL)excludeFromCaps
    excludeGlobalCaps:(BOOL)excludeGlobalCaps
   totalLifetimeCount:(int)totalLifetimeCount
      totalDailyCount:(int)totalDailyCount
        maxPerSession:(int)maxPerSession;

/// Records one render: the impression, the target's today and lifetime pair, and the global counter.
- (void)didShowTarget:(NSString *)targetId;

/// Stores the account ceilings pushed on every cap-aware response. Pass -1 for uncapped.
- (void)updateGlobalLimitsPerDay:(int)perDay andPerSession:(int)perSession;

/// Purges counts, impressions and triggers for targets the server has declared dead.
- (void)removeStaleTargetCounts:(NSArray *)staleTargets;

/// The SDK's render count for today. This is the @c ndmp value on a request.
- (int)shownTodayCount;

@end

NS_ASSUME_NONNULL_END

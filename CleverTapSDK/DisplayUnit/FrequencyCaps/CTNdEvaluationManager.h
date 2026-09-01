//
//  CTNdEvaluationManager.h
//  CleverTapSDK
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CTBatchSentDelegate.h"
#import "CTAttachToBatchHeaderDelegate.h"
#import "CTSwitchUserDelegate.h"
#import "CTLocalDataStore.h"

NS_ASSUME_NONNULL_BEGIN

@class CTMultiDelegateManager;
@class CTImpressionManager;
@class CTInAppTriggerManager;
@class CTNdStore;

/**
 Works out which Native Display campaigns the user is eligible for. The sibling of
 @c CTInAppEvaluationManager.

 On each event it walks the rules saved in @c CTNdStore, matches @c whenTriggers, counts the trigger,
 then checks @c frequencyLimits and @c occurrenceLimits against Native Display's own impression and
 trigger counts. Every campaign that passes has its @c ti added to @c adUnit_eval, which is sent with
 the next request. The server then sends content back only for the ids in that list, which is why
 @c CTNdFCManager does not check these two rules a second time at display time.

 The class also holds the @c adUnit_suppressed list. Those entries are not produced here: they are
 control group acknowledgements that response handling records through
 @c recordSuppressedNativeDisplay:. Both lists live in this class because that is where in-app keeps
 its equivalents, and both survive an app restart.

 Native Display is server side only, so there is no client side path and nothing here decides what to
 show. It only reports what the user qualifies for.
 */
@interface CTNdEvaluationManager : NSObject <CTBatchSentDelegate, CTAttachToBatchHeaderDelegate, CTSwitchUserDelegate>

/// Passed to each event so location based triggers can be matched. Set by @c CleverTap.
@property (nonatomic, assign) CLLocationCoordinate2D location;

- (instancetype)init NS_UNAVAILABLE;

/**
 @param impressionManager the Native Display impression manager, not the in-app one. Sharing in-app's
        would let one channel's displays count against the other's limits.
 @param triggerManager likewise the Native Display trigger manager.
 */
- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId
                  delegateManager:(CTMultiDelegateManager *)delegateManager
                impressionManager:(CTImpressionManager *)impressionManager
                   triggerManager:(CTInAppTriggerManager *)triggerManager
                          ndStore:(CTNdStore *)ndStore
                   localDataStore:(CTLocalDataStore *)dataStore NS_DESIGNATED_INITIALIZER;

- (void)evaluateOnEvent:(NSString *)eventName withProps:(nullable NSDictionary *)properties;
- (void)evaluateOnChargedEvent:(NSDictionary *)chargeDetails andItems:(nullable NSArray *)items;
- (void)evaluateOnUserAttributeChange:(NSDictionary<NSString *, NSDictionary *> *)properties;

/**
 Records that a campaign was held back because the user is in its control group.

 The server sends these as stubs inside @c adUnit_notifs_applaunched, carrying @c wzrk_id and
 @c wzrk_cgId but no content. Acknowledging them here rather than on the server means the control
 group event lines up with the moment the unit would have been shown.

 A stub with no @c wzrk_id is logged and dropped, because there is nothing to acknowledge.
 */
- (void)recordSuppressedNativeDisplay:(NSDictionary *)suppressedUnit;

@end

NS_ASSUME_NONNULL_END

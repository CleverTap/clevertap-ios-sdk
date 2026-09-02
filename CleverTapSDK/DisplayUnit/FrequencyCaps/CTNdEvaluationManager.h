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
 Works out which Native Display campaigns the user is eligible for. The Native Display version of
 @c CTInAppEvaluationManager.

 On each event it goes through the rules saved in @c CTNdStore. For each campaign it does three
 things. First it checks whether the event matches @c whenTriggers. Then it adds one to that
 campaign's trigger count. Then it checks @c frequencyLimits and @c occurrenceLimits against Native
 Display's own impression and trigger counts. Every campaign that passes has its @c ti added to
 @c adUnit_eval. That list goes out with the next request. The server sends content only for the ids
 in it. That is why @c CTNdFCManager does not check those two limits again when the unit is shown.

 This class also holds the @c adUnit_suppressed list. Those are not made here. They are control group
 replies. The server picked this user to see nothing. We tell it we noticed. Response handling adds
 them through @c recordSuppressedNativeDisplay:. Both lists live here because that is where in-app
 keeps its versions. Both survive an app restart.

 Native Display is server side only. Nothing here decides what to show. It only reports what the user
 qualifies for.
 */
@interface CTNdEvaluationManager : NSObject <CTBatchSentDelegate, CTAttachToBatchHeaderDelegate, CTSwitchUserDelegate>

/// Passed to each event so location based triggers can be matched. Set by @c CleverTap.
@property (nonatomic, assign) CLLocationCoordinate2D location;

- (instancetype)init NS_UNAVAILABLE;

/**
 @param impressionManager the Native Display impression manager, not the in-app one. Sharing in-app's
        would make one channel's displays count towards the other's limits.
 @param triggerManager the Native Display trigger manager, for the same reason.
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
 Records that a campaign was not shown because the user is in its control group.

 The server sends these inside @c adUnit_notifs_applaunched as stubs. They carry @c wzrk_id and
 @c wzrk_cgId but no content. We reply here rather than on the server. The control group event then
 happens at the same moment the unit would have been shown.

 A stub with no @c wzrk_id is logged and dropped. There is nothing to reply about.
 */
- (void)recordSuppressedNativeDisplay:(NSDictionary *)suppressedUnit;

@end

NS_ASSUME_NONNULL_END

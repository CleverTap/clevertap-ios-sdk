//
//  CTInAppEvaluationManager.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 31.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CTBatchSentDelegate.h"
#import "CTAttachToBatchHeaderDelegate.h"
#import "CTLocalDataStore.h"

@class CTMultiDelegateManager;
@class CTImpressionManager;
@class CTInAppDisplayManager;
@class CTInAppStore;
@class CTInAppTriggerManager;

NS_ASSUME_NONNULL_BEGIN

@interface CTInAppEvaluationManager : NSObject <CTBatchSentDelegate, CTAttachToBatchHeaderDelegate>

@property (nonatomic, assign) CLLocationCoordinate2D location;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId
                   delegateManager:(CTMultiDelegateManager *)delegateManager
                impressionManager:(CTImpressionManager *)impressionManager
              inAppDisplayManager:(CTInAppDisplayManager *)inAppDisplayManager
                       inAppStore:(CTInAppStore *)inAppStore
              inAppTriggerManager:(CTInAppTriggerManager *)inAppTriggerManager
                   localDataStore:(CTLocalDataStore *)dataStore;

- (void)evaluateOnEvent:(NSString *)eventName withProps:(NSDictionary *)properties;
- (void)evaluateOnChargedEvent:(NSDictionary *)chargeDetails andItems:(NSArray *)items;
- (void)evaluateOnUserAttributeChange:(NSDictionary<NSString *, NSDictionary *> *)properties;
- (void)evaluateOnAppLaunchedClientSide;
- (void)evaluateOnAppLaunchedServerSide:(NSArray *)appLaunchedNotifs;
- (void)evaluateOnAppLaunchedDelayedServerSide:(NSArray *)appLaunchedNotifs;
- (void)evaluateOnAppLaunchedInActionServerSide:(NSArray *)appLaunchedNotifs;

#pragma mark - App Launched arbitration

/*!
 How long to hold the app-launch in-app waiting for the content fetch, in seconds.

 This is a UX bound, not a correctness one, and is deliberately far shorter than the content
 fetch's own limits (10s request, 15s including the wait for a concurrency slot). Matching those
 would delay the in-app by up to 15s on a slow network.

 Correctness comes from `appLaunchedArbitrationContentFetchDidComplete` instead: a response that
 arrives after this timeout has fired is dropped rather than shown, so a slow fetch can never
 produce a second in-app. Exposed mainly for tests.
 */
@property (nonatomic, assign) NSTimeInterval appLaunchedArbitrationTimeout;

/*!
 Defer app-launch in-app display until the content fetch spawned by this response resolves.

 The `/content` response is re-fed through the same handler chain as `/a1`, so without a window
 each response runs its own independent selection and one in-app is shown per response. While a
 window is open, `evaluateOnAppLaunchedServerSide:` buffers its winner instead of queueing it;
 on close a single merged selection runs across every buffered winner, so exactly one in-app is
 shown for the launch.

 Buffering the per-response winner rather than every eligible candidate is equivalent: the
 comparator is a total order, so max(max(A), max(B)) == max(A ∪ B).

 @param targetIds Campaign ids the content fetch is expected to return. Recorded for diagnostics
 only — the window closes on the fetch's completion signal, not on these arriving.
 */
- (void)openAppLaunchedArbitrationWithTargetIds:(NSArray<NSString *> *)targetIds;

/*!
 Report that the content fetch for this launch has settled.

 Displays the merged winner if the timeout has not already done so, then ends the window
 entirely so subsequent responses are handled normally again.

 Must be called for every window that was opened, on success and on failure alike — otherwise
 app-launch in-apps stay suppressed for the rest of the session. The content fetch completion
 block guarantees this by running exactly once in all cases.

 Safe to call with no window open, and idempotent.
 */
- (void)appLaunchedArbitrationContentFetchDidComplete;

@end

NS_ASSUME_NONNULL_END

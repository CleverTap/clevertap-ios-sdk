//
//  NdHelper.h
//  CleverTapSDKTests
//
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CleverTapInstanceConfig;
@class CTMultiDelegateManager;
@class CTImpressionManager;
@class CTInAppTriggerManager;
@class CTLocalDataStore;
@class CTNdStore;
@class CTNdFCManager;
@class CTNdEvaluationManager;

NS_ASSUME_NONNULL_BEGIN

/**
 Builds a full set of Native Display managers for a test, wired the same way @c CleverTap wires them.
 The sibling of @c InAppHelper.

 Each instance invents its own account id, so two tests never read each other's counts. Preferences
 are a single flat keyspace shared by the whole test run, and every one of these managers writes to
 it, so without that the order the tests happen to run in would change their results.

 Call @c tearDown at the end of a test to take those preferences back out again.
 */
@interface NdHelper : NSObject

@property (nonatomic, strong, readonly) NSString *accountId;
@property (nonatomic, strong, readonly) NSString *deviceId;

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTMultiDelegateManager *delegateManager;

/// The Native Display impression and trigger managers, on the Native Display namespaces. Sharing
/// in-app's would let one channel's displays count against the other's limits.
@property (nonatomic, strong) CTImpressionManager *impressionManager;
@property (nonatomic, strong) CTInAppTriggerManager *triggerManager;

@property (nonatomic, strong) CTLocalDataStore *dataStore;
@property (nonatomic, strong) CTNdStore *ndStore;
@property (nonatomic, strong) CTNdFCManager *ndFCManager;
@property (nonatomic, strong) CTNdEvaluationManager *evaluationManager;

/// Deletes every preference this helper's managers wrote. Safe to call more than once.
- (void)tearDown;

@end

NS_ASSUME_NONNULL_END

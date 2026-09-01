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
 Builds a full set of Native Display managers for a test, connected the same way @c CleverTap
 connects them. The Native Display version of @c InAppHelper.

 Each instance makes up its own account id, so two tests never read each other's counts. Preferences
 are one flat list of keys shared by the whole test run, and every manager here writes to it. Without
 its own account id, the order the tests happen to run in would change their results.

 Call @c tearDown at the end of a test to remove those preferences again.
 */
@interface NdHelper : NSObject

@property (nonatomic, strong, readonly) NSString *accountId;
@property (nonatomic, strong, readonly) NSString *deviceId;

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTMultiDelegateManager *delegateManager;

/// The Native Display impression and trigger managers, using the Native Display storage names.
/// Sharing in-app's would make one channel's displays count towards the other's limits.
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

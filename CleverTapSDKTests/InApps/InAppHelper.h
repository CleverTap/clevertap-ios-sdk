//
//  InAppHelper.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 15.11.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CTInAppFCManager;
@class CTInAppEvaluationManager;
@class CTInAppDisplayManager;
@class CTImpressionManager;
@class CTInAppStore;
@class CleverTapInstanceConfig;
@class CTMultiDelegateManager;
@class CTInAppTriggerManager;
@class CTInAppImagePrefetchManager;

NS_ASSUME_NONNULL_BEGIN

@interface InAppHelper : NSObject

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTMultiDelegateManager *delegateManager;
@property (nonatomic, strong) CTInAppFCManager *inAppFCManager;
@property (nonatomic, strong) CTInAppEvaluationManager *inAppEvaluationManager;
@property (nonatomic, strong) CTInAppDisplayManager *inAppDisplayManager;
@property (nonatomic, strong) CTImpressionManager *impressionManager;
@property (nonatomic, strong) CTInAppStore *inAppStore;
@property (nonatomic, strong) CTInAppTriggerManager *inAppTriggerManager;
@property (nonatomic, strong) CTInAppImagePrefetchManager *imagePrefetchManager;

- (NSString *)accountId;
- (NSString *)accountToken;
- (NSString *)deviceId;
- (NSString *)campaignId;

@end

NS_ASSUME_NONNULL_END

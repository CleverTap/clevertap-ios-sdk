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
@class CTFileDownloader;
@class CTLocalDataStore;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const CLTAP_TEST_ACCOUNT_ID;
extern NSString *const CLTAP_TEST_ACCOUNT_TOKEN;
extern NSString *const CLTAP_TEST_DEVICE_ID;
extern NSString *const CLTAP_TEST_CAMPAIGN_ID;

@interface InAppHelper : NSObject

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTMultiDelegateManager *delegateManager;
@property (nonatomic, strong) CTInAppFCManager *inAppFCManager;
@property (nonatomic, strong) CTInAppEvaluationManager *inAppEvaluationManager;
@property (nonatomic, strong) CTInAppDisplayManager *inAppDisplayManager;
@property (nonatomic, strong) CTImpressionManager *impressionManager;
@property (nonatomic, strong) CTInAppStore *inAppStore;
@property (nonatomic, strong) CTInAppTriggerManager *inAppTriggerManager;
@property (nonatomic, strong) CTFileDownloader *fileDownloader;
@property (nonatomic, strong) CTLocalDataStore *dataStore;

- (NSString *)accountId;
- (NSString *)accountToken;
- (NSString *)deviceId;
- (NSString *)campaignId;

@end

NS_ASSUME_NONNULL_END

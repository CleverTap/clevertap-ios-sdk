//
//  CTInAppEvaluationManager+Tests.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 17.11.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#ifndef CTInAppEvaluationManager_Tests_h
#define CTInAppEvaluationManager_Tests_h

@interface CTInAppEvaluationManager(Test)
@property (nonatomic, strong) CTInAppTriggerManager *triggerManager;
@property (nonatomic, strong) CTInAppDisplayManager *inAppDisplayManager;
@property (nonatomic, strong) NSMutableArray *suppressedClientSideInApps;
@property (nonatomic, strong) NSMutableArray *evaluatedServerSideInAppIds;
@property (nonatomic, strong) NSMutableArray *evaluatedServerSideInAppIdsForProfile;
@property (nonatomic, strong) NSMutableArray *suppressedClientSideInAppsForProfile;
@property (nonatomic, strong) NSDictionary *appLaunchedProperties;
- (void)sortByPriority:(NSMutableArray *)inApps;
- (NSMutableArray *)evaluate:(CTEventAdapter *)event withInApps:(NSArray *)inApps;
- (BOOL)shouldSuppress:(NSDictionary *)inApp;
- (void)suppress:(NSDictionary *)inApp;
- (NSString *)generateWzrkId:(NSString *)ti;
- (void)updateTTL:(NSMutableDictionary *)inApp;
- (void)onAppLaunchedWithSuccess:(BOOL)success;
- (void)saveEvaluatedServerSideInAppIds;
- (void)saveSuppressedClientSideInApps;
- (void)saveEvaluatedServerSideInAppIdsForProfile;
- (void)saveSuppressedClientSideInAppsForProfile;
- (NSString *)storageKeyWithSuffix:(NSString *)suffix;
@end

#endif /* CTInAppEvaluationManager_Tests_h */

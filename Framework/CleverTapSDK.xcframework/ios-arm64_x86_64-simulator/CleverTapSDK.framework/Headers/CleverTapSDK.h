//
//  CleverTapSDK.h
//  CleverTapSDK
//
//  Created by Akash Malhotra on 27/02/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for CleverTapSDK.
FOUNDATION_EXPORT double CleverTapSDKVersionNumber;

//! Project version string for CleverTapSDK.
FOUNDATION_EXPORT const unsigned char CleverTapSDKVersionString[];

#if TARGET_OS_IOS
#import "CleverTap.h"
#import "CleverTap+Inbox.h"
#import "CleverTap+FeatureFlags.h"
#import "CleverTap+ProductConfig.h"
#import "CleverTap+DisplayUnit.h"
#import "CleverTap+SSLPinning.h"
#import "CleverTapBuildInfo.h"
#import "CleverTapEventDetail.h"
#import "CleverTapInAppNotificationDelegate.h"
#import "CleverTapPushNotificationDelegate.h"
#import "CleverTapURLDelegate.h"
#import "CleverTapSyncDelegate.h"
#import "CleverTapUTMDetail.h"
#import "CleverTapTrackedViewController.h"
#import "CleverTapInstanceConfig.h"
#import "CleverTapJSInterface.h"
#import "CleverTap+InAppNotifications.h"
#import "CleverTap+SCDomain.h"
#import "CTLocalInApp.h"
#import "CleverTap+CTVar.h"
#import "CTVar.h"
#import "LeanplumCT.h"
#import "CTInAppTemplateBuilder.h"
#import "CTAppFunctionBuilder.h"
#import "CTTemplatePresenter.h"
#import "CTTemplateProducer.h"
#import "CTCustomTemplateBuilder.h"
#import "CTCustomTemplate.h"
#import "CTTemplateContext.h"
#import "CTCustomTemplatesManager.h"
#import "CleverTap+PushPermission.h"
#import "CTJsonTemplateProducer.h"

#elif TARGET_OS_TV
#import "CleverTap.h"
#import "CleverTap+SSLPinning.h"
#import "CleverTap+FeatureFlags.h"
#import "CleverTap+ProductConfig.h"
#import "CleverTapBuildInfo.h"
#import "CleverTapEventDetail.h"
#import "CleverTapSyncDelegate.h"
#import "CleverTapUTMDetail.h"
#import "CleverTapTrackedViewController.h"
#import "CleverTapInstanceConfig.h"
#import "CTVar.h"
#import "CleverTap+CTVar.h"
#import "LeanplumCT.h"
#endif

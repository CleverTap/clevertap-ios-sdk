#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "CleverTap.h"
#import "CleverTap+SSLPinning.h"
#import "CleverTap+Inbox.h"
#import "CleverTapInstanceConfig.h"
#import "CleverTapBuildInfo.h"
#import "CleverTapEventDetail.h"
#import "CleverTapInAppNotificationDelegate.h"
#import "CleverTapSyncDelegate.h"
#import "CleverTapTrackedViewController.h"
#import "CleverTapUTMDetail.h"
#import "CleverTapJSInterface.h"
#import "CleverTap+ABTesting.h"
#import "CleverTap+DisplayUnit.h"

FOUNDATION_EXPORT double CleverTapSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char CleverTapSDKVersionString[];


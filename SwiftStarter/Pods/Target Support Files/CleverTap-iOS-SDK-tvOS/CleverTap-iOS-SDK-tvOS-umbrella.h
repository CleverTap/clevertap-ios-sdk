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
#import "CleverTapInstanceConfig.h"
#import "CleverTapBuildInfo.h"
#import "CleverTapEventDetail.h"
#import "CleverTapSyncDelegate.h"
#import "CleverTapTrackedViewController.h"
#import "CleverTapUTMDetail.h"
#import "CleverTap+FeatureFlags.h"
#import "CleverTap+ProductConfig.h"

FOUNDATION_EXPORT double CleverTapSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char CleverTapSDKVersionString[];


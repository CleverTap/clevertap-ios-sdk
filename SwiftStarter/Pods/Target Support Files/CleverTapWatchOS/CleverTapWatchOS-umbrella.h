#ifdef __OBJC__
#import <Foundation/Foundation.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "CleverTapWatchOS.h"

FOUNDATION_EXPORT double CleverTapWatchOSVersionNumber;
FOUNDATION_EXPORT const unsigned char CleverTapWatchOSVersionString[];


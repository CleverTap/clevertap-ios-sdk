#import <Foundation/Foundation.h>
#import "CTAttachToHeaderDelegate.h"

@class CleverTapInstanceConfig;
@class CTInAppNotification;

// Storage keys
extern NSString* const kKEY_COUNTS_PER_INAPP;
extern NSString* const kKEY_COUNTS_SHOWN_TODAY;
extern NSString* const kKEY_MAX_PER_DAY;

@interface CTInAppFCManager : NSObject <CTAttachToHeaderDelegate>

@property (nonatomic, strong, readonly) CleverTapInstanceConfig *config;
@property (atomic, copy, readonly) NSString *deviceId;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config deviceId:(NSString *)deviceId;

- (NSString *)storageKeyWithSuffix: (NSString *)suffix;

- (void)checkUpdateDailyLimits;

- (BOOL)canShow:(CTInAppNotification *)inapp;

- (void)changeUserWithGuid:(NSString *)guid;

- (void)didShow:(CTInAppNotification *)inapp;

- (void)updateGlobalLimitsPerDay:(int)perDay andPerSession:(int)perSession;

- (void)removeStaleInAppCounts:(NSArray *)staleInApps;

- (BOOL)hasLifetimeCapacityMaxedOut:(CTInAppNotification *)dictionary;

- (BOOL)hasDailyCapacityMaxedOut:(CTInAppNotification *)dictionary;

@end

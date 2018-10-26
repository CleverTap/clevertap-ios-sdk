#import <Foundation/Foundation.h>

@class CleverTapInstanceConfig;
@class CTInAppNotification;

@interface CTInAppFCManager : NSObject

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config;

- (void)checkUpdateDailyLimits;

- (BOOL)canShow:(CTInAppNotification *)inapp;

- (void)didDismiss:(CTInAppNotification *)inapp;

- (void)resetSession;

- (void)changeUser;

- (void)didShow:(CTInAppNotification *)inapp;

- (void)updateLimitsPerDay:(int)perDay andPerSession:(int)perSession;

- (void)attachToHeader:(NSMutableDictionary *)header;

- (void)processResponse:(NSDictionary *)response;

- (BOOL)hasLifetimeCapacityMaxedOut:(CTInAppNotification *)dictionary;

- (BOOL)hasDailyCapacityMaxedOut:(CTInAppNotification *)dictionary;

@end

#import <Foundation/Foundation.h>

@class CleverTapInstanceConfig;
@class CTInAppNotification;

@interface CTInAppFCManager : NSObject

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config guid:(NSString *)guid;

- (void)checkUpdateDailyLimits;

- (BOOL)canShow:(CTInAppNotification *)inapp;

- (void)didDismiss:(CTInAppNotification *)inapp;

- (void)resetSession;

- (void)changeUserWithGuid:(NSString *)guid;

- (void)didShow:(CTInAppNotification *)inapp;

- (void)updateLimitsPerDay:(int)perDay andPerSession:(int)perSession;

- (void)attachToHeader:(NSMutableDictionary *)header;

- (void)processResponse:(NSDictionary *)response;

- (BOOL)hasLifetimeCapacityMaxedOut:(CTInAppNotification *)dictionary;

- (BOOL)hasDailyCapacityMaxedOut:(CTInAppNotification *)dictionary;

@end

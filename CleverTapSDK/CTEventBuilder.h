#import <Foundation/Foundation.h>
#import "CleverTap.h"

@class CTValidationResult;
@class CTInAppNotification;
@class CleverTapInboxMessage;
@class CleverTapDisplayUnit;

@interface CTEventBuilder : NSObject

+ (void)build:(NSString * _Nonnull)eventName completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable event, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)build:(NSString * _Nonnull)eventName withEventActions:(NSDictionary * _Nullable)eventActions completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable event, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildChargedEventWithDetails:(NSDictionary * _Nonnull)chargeDetails
                            andItems:(NSArray * _Nullable)items completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable event, NSArray<CTValidationResult*> * _Nullable errors))completion;

+ (void)buildPushNotificationEvent:(BOOL)clicked
                   forNotification:(NSDictionary * _Nonnull)notification
                 completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable event, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildInAppNotificationStateEvent:(BOOL)clicked
                         forNotification:(CTInAppNotification * _Nonnull)notification
                      andQueryParameters:(NSDictionary * _Nullable)params
                       completionHandler:(void(^ _Nonnull)(NSDictionary* _Nullable event, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildInboxMessageStateEvent:(BOOL)clicked
                         forMessage:(CleverTapInboxMessage * _Nonnull)message
                 andQueryParameters:(NSDictionary * _Nullable)params
                  completionHandler:(void(^ _Nonnull)(NSDictionary * _Nullable event, NSArray<CTValidationResult*> * _Nullable errors))completion;

+ (void)buildDisplayViewStateEvent:(BOOL)clicked
                    forDisplayUnit:(CleverTapDisplayUnit * _Nonnull)displayUnit
                andQueryParameters:(NSDictionary * _Nullable)params
                 completionHandler:(void(^ _Nonnull)(NSDictionary * _Nullable event, NSArray<CTValidationResult*> * _Nullable errors))completion;

+ (void)buildGeofenceStateEvent:(BOOL)entered
                 forGeofenceDetails:(NSDictionary * _Nonnull)geofenceDetails
              completionHandler:(void(^ _Nonnull)(NSDictionary * _Nullable event, NSArray<CTValidationResult*> * _Nullable errors))completion;

+ (void)buildSignedCallEvent:(int)eventRawValue
              forCallDetails:(NSDictionary * _Nonnull)callDetails
           completionHandler:(void(^ _Nonnull)(NSDictionary * _Nullable event, NSArray<CTValidationResult*> * _Nullable errors))completion;

@end

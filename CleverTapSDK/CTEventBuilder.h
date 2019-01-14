#import <Foundation/Foundation.h>

@class CTValidationResult;
@class CTInAppNotification;
@class CleverTapInboxMessage;

@interface CTEventBuilder : NSObject

+ (void)build:(NSString *)eventName completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable event, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)build:(NSString *)eventName withEventActions:(NSDictionary *)eventActions completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable event, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildChargedEventWithDetails:(NSDictionary *)chargeDetails
                           andItems:(NSArray *)items completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable event, NSArray<CTValidationResult*> *errors))completion;

+ (void)buildPushNotificationEventForNotification:(NSDictionary*)notification
                                completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable event, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildInAppNotificationStateEvent:(BOOL)clicked
                               forNotification:(CTInAppNotification *)notification
                      andQueryParameters:(NSDictionary *)params
                       completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable event, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildInboxMessageStateEvent:(BOOL)clicked
                         forMessage:(CleverTapInboxMessage *)message
                      andQueryParameters:(NSDictionary *)params
                       completionHandler:(void(^)(NSDictionary* event, NSArray<CTValidationResult*> *errors))completion;

@end

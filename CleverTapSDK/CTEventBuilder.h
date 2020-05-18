#import <Foundation/Foundation.h>

@class CTValidationResult;
@class CTInAppNotification;
@class CleverTapInboxMessage;
@class CleverTapDisplayUnit;

NS_ASSUME_NONNULL_BEGIN

@interface CTEventBuilder : NSObject

+ (void)build:(NSString *)eventName completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable event, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)build:(NSString *)eventName withEventActions:(NSDictionary *_Nullable)eventActions completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable event, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildChargedEventWithDetails:(NSDictionary *)chargeDetails
                            andItems:(NSArray *_Nullable)items completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable event, NSArray<CTValidationResult*> * _Nullable errors))completion;

+ (void)buildPushNotificationEvent:(BOOL)clicked
                   forNotification:(NSDictionary *)notification
                 completionHandler:(void(^ _Nonnull)(NSDictionary* _Nullable event, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildInAppNotificationStateEvent:(BOOL)clicked
                         forNotification:(CTInAppNotification *)notification
                      andQueryParameters:(NSDictionary *_Nullable)params
                       completionHandler:(void(^ _Nonnull)(NSDictionary* _Nullable event, NSArray<CTValidationResult*>* _Nullable errors))completion;

+ (void)buildInboxMessageStateEvent:(BOOL)clicked
                         forMessage:(CleverTapInboxMessage *)message
                 andQueryParameters:(NSDictionary *_Nullable)params
                  completionHandler:(void(^ _Nonnull)(NSDictionary * _Nullable event, NSArray<CTValidationResult*> * _Nullable errors))completion;

+ (void)buildDisplayViewStateEvent:(BOOL)clicked
                    forDisplayUnit:(CleverTapDisplayUnit *)displayUnit
                andQueryParameters:(NSDictionary *_Nullable)params
                 completionHandler:(void(^ _Nonnull)(NSDictionary * _Nullable event, NSArray<CTValidationResult*> * _Nullable errors))completion;

@end

NS_ASSUME_NONNULL_END

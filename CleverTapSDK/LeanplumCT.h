//
//  LeanplumCT.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 22.05.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CleverTap.h"

NS_ASSUME_NONNULL_BEGIN

@interface LeanplumCT : NSObject

@property (class) CleverTap *instance;
typedef void (^LeanplumStartBlock)(BOOL success);

/**
 * Block to call when the start call finishes, and variables are returned
 * back from the server. Calling this multiple times will call each block
 * in succession.
 */
+ (void)onStartResponse:(LeanplumStartBlock)block;

/**
 * @{
 * Advances to a particular state in your application. The string can be
 * any value of your choosing, and will show up in the dashboard.
 * A state is a section of your app that the user is currently in.
 * @param state The name of the state.
 */
+ (void)advanceTo:(nullable NSString *)state
NS_SWIFT_NAME(advance(state:));

/**
 * Advances to a particular state in your application. The string can be
 * any value of your choosing, and will show up in the dashboard.
 * A state is a section of your app that the user is currently in.
 * @param state The name of the state.
 * @param info Anything else you want to log with the state. For example, if the state
 * is watchVideo, info could be the video ID.
 */
+ (void)advanceTo:(nullable NSString *)state
         withInfo:(nullable NSString *)info
NS_SWIFT_NAME(advance(state:info:));

/**
 * Advances to a particular state in your application. The string can be
 * any value of your choosing, and will show up in the dashboard.
 * A state is a section of your app that the user is currently in.
 * You can specify up to 200 types of parameters per app across all events and state.
 * The parameter keys must be strings, and values either strings or numbers.
 * @param state The name of the state.
 * @param params A dictionary with custom parameters.
 */
+ (void)advanceTo:(nullable NSString *)state
   withParameters:(nullable NSDictionary<NSString *, id> *)params
NS_SWIFT_NAME(advance(state:params:));

/**
 * Advances to a particular state in your application. The string can be
 * any value of your choosing, and will show up in the dashboard.
 * A state is a section of your app that the user is currently in.
 * You can specify up to 200 types of parameters per app across all events and state.
 * The parameter keys must be strings, and values either strings or numbers.
 * @param state The name of the state. (nullable)
 * @param info Anything else you want to log with the state. For example, if the state
 * is watchVideo, info could be the video ID.
 * @param params A dictionary with custom parameters.
 */
+ (void)advanceTo:(nullable NSString *)state
         withInfo:(nullable NSString *)info
    andParameters:(nullable NSDictionary<NSString *, id> *)params
NS_SWIFT_NAME(advance(state:info:params:));

/**
 * Returns the deviceId in the current Leanplum session. This should only be called after
 * [Leanplum start].
 */
+ (nullable NSString *)deviceId;

/**
 * Returns the userId in the current Leanplum session. This should only be called after
 * [Leanplum start].
 */
+ (nullable NSString *)userId;

/**
 * Sets additional user attributes after the session has started.
 * Variables retrieved by start won't be targeted based on these attributes, but
 * they will count for the current session for reporting purposes.
 * Only those attributes given in the dictionary will be updated. All other
 * attributes will be preserved.
 */
+ (void)setUserAttributes:(NSDictionary *)attributes;

/**
 * Updates a user ID after session start.
 */
+ (void)setUserId:(NSString *)userId
NS_SWIFT_NAME(setUserId(_:));

/**
 * Updates a user ID after session start with a dictionary of user attributes.
 */
+ (void)setUserId:(NSString *)userId withUserAttributes:(NSDictionary *)attributes
NS_SWIFT_NAME(setUserId(_:attributes:));

/**
 * Sets the traffic source info for the current user.
 * Keys in info must be one of: publisherId, publisherName, publisherSubPublisher,
 * publisherSubSite, publisherSubCampaign, publisherSubAdGroup, publisherSubAd.
 */
+ (void)setTrafficSourceInfo:(NSDictionary *)info
NS_SWIFT_NAME(setTrafficSource(info:));

/**
 * @{
 * Call this when your application starts.
 * This will initiate a call to Leanplum's servers to get the values
 * of the variables used in your app.
 */
+ (void)start;

+ (void)startWithResponseHandler:(LeanplumStartBlock)response
NS_SWIFT_NAME(start(completion:));

+ (void)startWithUserAttributes:(NSDictionary<NSString *, id> *)attributes
NS_SWIFT_NAME(start(attributes:));

+ (void)startWithUserId:(NSString *)userId
NS_SWIFT_NAME(start(userId:));

+ (void)startWithUserId:(NSString *)userId
        responseHandler:(nullable LeanplumStartBlock)response
NS_SWIFT_NAME(start(userId:completion:));

+ (void)startWithUserId:(NSString *)userId
         userAttributes:(NSDictionary<NSString *, id> *)attributes
NS_SWIFT_UNAVAILABLE("Use start(userId:attributes:completion:");

+ (void)startWithUserId:(nullable NSString *)userId
         userAttributes:(nullable NSDictionary<NSString *, id> *)attributes
        responseHandler:(nullable LeanplumStartBlock)startResponse
NS_SWIFT_NAME(start(userId:attributes:completion:));
/**@}*/

/**
 * Manually track purchase event with currency code in your application. It is advised to use
 * trackInAppPurchases to automatically track IAPs.
 */
+ (void)trackPurchase:(NSString *)event
            withValue:(double)value
      andCurrencyCode:(nullable NSString *)currencyCode
        andParameters:(nullable NSDictionary<NSString *, id> *)params
NS_SWIFT_NAME(track(event:value:currencyCode:params:));
/**@}*/

/**
 * @{
 * Logs a particular event in your application. The string can be
 * any value of your choosing, and will show up in the dashboard.
 * To track a purchase, use LP_PURCHASE_EVENT.
 */
+ (void)track:(NSString *)event;

+ (void)track:(NSString *)event
    withValue:(double)value
NS_SWIFT_NAME(track(_:value:));

+ (void)track:(NSString *)event
     withInfo:(nullable NSString *)info
NS_SWIFT_NAME(track(_:info:));

+ (void)track:(NSString *)event
    withValue:(double)value
      andInfo:(nullable NSString *)info
NS_SWIFT_NAME(track(_:value:info:));

// See above for the explanation of params.
+ (void)track:(NSString *)event withParameters:(nullable NSDictionary<NSString *, id> *)params
NS_SWIFT_NAME(track(_:params:));

+ (void)track:(NSString *)event
    withValue:(double)value
andParameters:(nullable NSDictionary<NSString *, id> *)params
NS_SWIFT_NAME(track(_:value:params:));

+ (void)track:(NSString *)event
    withValue:(double)value
      andInfo:(nullable NSString *)info
andParameters:(nullable NSDictionary<NSString *, id> *)params
NS_SWIFT_NAME(track(_:value:info:params:));
/**@}*/

@end

NS_ASSUME_NONNULL_END

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@protocol CleverTapSyncDelegate;
#if !defined(CLEVERTAP_APP_EXTENSION)
@protocol CleverTapInAppNotificationDelegate;
#endif

@class CleverTapEventDetail;
@class CleverTapUTMDetail;

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"

@interface CleverTap : NSObject


/* ------------------------------------------------------------------------------------------------------
 * Initialization
 */

/*!
@method

@abstract
Initializes and returns a singleton instance of the API.

@discussion
This method will set up a singleton instance of the CleverTap class, when you want to make calls to CleverTap
elsewhere in your code, you can use this singleton or call sharedInstance.

 */
+ (instancetype)sharedInstance;

#if !defined(CLEVERTAP_APP_EXTENSION)
/*!
 @method
 
 @abstract
 Auto integrates CleverTap and initializes and returns a singleton instance of the API.
 
 @discussion
 This method will auto integrate CleverTap to automatically handle device token registration and 
 push notification/url referrer tracking, and set up a singleton instance of the CleverTap class, 
 when you want to make calls to CleverTap elsewhere in your code, you can use this singleton or call sharedInstance.
 
 This is accomplished by proxying the AppDelegate and "inserting" a CleverTap AppDelegate
 behind the AppDelegate. The proxy will first call the AppDelegate and then call the CleverTap AppDelegate.
 
 */
+ (instancetype)autoIntegrate;
#endif


/*!
 @method
 
 @abstract
 Change the CleverTap accountID and token
 
 @discussion
 Changes the CleverTap account associated with the app on the fly.  Should only used during testing.
 Instead, considering relying on the separate -Test account created for your app in CleverTap.
 
 @param accountID  the CleverTap account id
 @param token       the CleverTap account token
 
 */
+ (void)changeCredentialsWithAccountID:(NSString *)accountID andToken:(NSString *)token;

#if !defined(CLEVERTAP_APP_EXTENSION)
/*!
 @method
 
 @abstract
 notify the SDK of application launch
 
 */
- (void)notifyApplicationLaunchedWithOptions:launchOptions;
#endif

/* ------------------------------------------------------------------------------------------------------
 * User Profile/Action Events/Session API
 */

/*!
 @method
 
 @abstract
 Enables the Profile/Events Read and Synchronization API
 
 @discussion
 Call this method (typically once at app launch) to enable the Profile/Events Read and Synchronization API.
 
 */
+ (void)enablePersonalization;

/*!
 @method
 
 @abstract
 Disables the Profile/Events Read and Synchronization API
 
 */
+ (void)disablePersonalization;


/*!
 @method
 
 @abstract
 Store the users location in CleverTap.
 
 @discussion
 Optional.  If you're application is collection the user location you can pass it to CleverTap
 for, among other things, more fine-grained geo-targeting and segmentation purposes.
 
 @param location       CLLocationCoordiate2D
 */
+ (void)setLocation:(CLLocationCoordinate2D)location;

#if !defined(CLEVERTAP_APP_EXTENSION)
/*!
 @method
 
 @abstract
 Get the device location if available.  Calling this will prompt the user location permissions dialog.
 
 Please be sure to include the NSLocationWhenInUseUsageDescription key in your Info.plist.  See https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW26

 Uses desired accuracy of kCLLocationAccuracyHundredMeters.

 If you need background location updates or finer accuracy please implement your own location handling.  Please see https://developer.apple.com/library/ios/documentation/CoreLocation/Reference/CLLocationManager_Class/index.html for more info.
 
 @discussion
 Optional.  You can use location to pass it to CleverTap via the setLocation API
 for, among other things, more fine-grained geo-targeting and segmentation purposes.
*/
+ (void)getLocationWithSuccess:(void (^)(CLLocationCoordinate2D location))success andError:(void (^)(NSString *reason))error;
#endif

/*!
 @method
 
 @abstract
 Creates a separate and distinct user profile identified by one or more of Identity, Email, FBID or GPID values,
 and populated with the key-values included in the properties dictionary.
 
 @discussion
 If your app is used by multiple users, you can use this method to assign them each a unique profile to track them separately.
 
 If instead you wish to assign multiple Identity, Email, FBID and/or GPID values to the same user profile,
 use profilePush rather than this method.
 
 If none of Identity, Email, FBID or GPID is included in the properties dictionary,
 all properties values will be associated with the current user profile.
 
 When initially installed on this device, your app is assigned an "anonymous" profile.
 The first time you identify a user on this device (whether via onUserLogin or profilePush),
 the "anonymous" history on the device will be associated with the newly identified user.
 
 Then, use this method to switch between subsequent separate identified users.
 
 Please note that switching from one identified user to another is a costly operation
 in that the current session for the previous user is automatically closed
 and data relating to the old user removed, and a new session is started
 for the new user and data for that user refreshed via a network call to CleverTap.
 In addition, any global frequency caps are reset as part of the switch.

 @param properties       properties dictionary
 
 */
- (void)onUserLogin:(NSDictionary *)properties;

#pragma mark Profile API

/*!
 @method
 
 @abstract
 Set properties on the current user profile.
 
 @discussion
 Property keys must be NSString and values must be one of NSString, NSNumber, BOOL, NSDate.
 
 To add a multi-value (array) property value type please use profileAddValueToSet: forKey:
 
 Keys are limited to 32 characters.
 Values are limited to 120 bytes.  
 
 Longer will be truncated.
 
 Maximum number of custom profile attributes is 63
 
 @param properties       properties dictionary
 */
- (void)profilePush:(NSDictionary *)properties;


/*!
 @method
 
 @abstract
 Remove the property specified by key from the user profile.
 
 @param key       key string

 */
- (void)profileRemoveValueForKey:(NSString *)key;

/*!
 @method
 
 @abstract
 Method for setting a multi-value user profile property.
 
 Any existing value(s) for the key will be overwritten.
 
 @discussion
 Key must be NSString.
 Values must be NSStrings, max 40 bytes.  Longer will be truncated.
 Max 100 values, on reaching 100 cap, oldest value(s) will be removed.

 
 @param key       key string
 @param values    values NSArray<NSString *>
 
 */
- (void)profileSetMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key;

/*!
 @method
 
 @abstract
 Method for adding a unique value to a multi-value profile property (or creating if not already existing).
 
 If the key currently contains a scalar value, the key will be promoted to a multi-value property
 with the current value cast to a string and the new value(s) added
 
 @discussion
 Key must be NSString.
 Values must be NSStrings, max 40 bytes. Longer will be truncated.
 Max 100 values, on reaching 100 cap, oldest value(s) will be removed.

 
 @param key       key string
 @param value     value string
 */
- (void)profileAddMultiValue:(NSString *)value forKey:(NSString *)key;

/*!
 @method
 
 @abstract
 Method for adding multiple unique values to a multi-value profile property (or creating if not already existing).
 
 If the key currently contains a scalar value, the key will be promoted to a multi-value property
 with the current value cast to a string and the new value(s) added.
 
 @discussion
 Key must be NSString.
 Values must be NSStrings, max 40 bytes. Longer will be truncated.
 Max 100 values, on reaching 100 cap, oldest value(s) will be removed.
 
 
 @param key       key string
 @param values    values NSArray<NSString *>
 */
- (void)profileAddMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key;

/*!
 @method
 
 @abstract
 Method for removing a unique value from a multi-value profile property.
 
 If the key currently contains a scalar value, prior to performing the remove operation the key will be promoted to a multi-value property with the current value cast to a string.
 
 If the multi-value property is empty after the remove operation, the key will be removed.
 
 @param key       key string
 @param value     value string
 */
- (void)profileRemoveMultiValue:(NSString *)value forKey:(NSString *)key;

/*!
 @method
 
 @abstract
 Method for removing multiple unique values from a multi-value profile property.
 
 If the key currently contains a scalar value, prior to performing the remove operation the key will be promoted to a multi-value property with the current value cast to a string.
 
 If the multi-value property is empty after the remove operation, the key will be removed.
 
 @param key       key string
 @param values    values NSArray<NSString *>
 */
- (void)profileRemoveMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key;

/*!
 @method
 
 @abstract
 Convenience method to set the Facebook Graph User properties on the user profile.
 
 @discussion
 If you support social login via FB connect in your app and are using the Facebook library in your app,
 you can push a GraphUser object of the user.
 Be sure that you’re sending a GraphUser object of the currently logged in user.
 
 @param fbGraphUser       fbGraphUser Facebook Graph User object
 
 */
- (void)profilePushGraphUser:(id)fbGraphUser;

/*!
 @method
 
 @abstract
 Convenience method to set the Google Plus User properties on the user profile.
 
 @discussion
 If you support social login via Google Plus in your app and are using the Google Plus library in your app,
 you can set a GTLPlusPerson object on the user profile, after a successful login.
 
 @param googleUser       GTLPlusPerson object
 
 */
- (void)profilePushGooglePlusUser:(id)googleUser;

/*!
 @method
 
 @abstract
 Get a user profile property.
 
 @discussion
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 If the property is not available or enablePersonalization has not been called, this call will return nil.
 
 @param propertyName          property name
 
 @return
 returns NSArray in the case of a multi-value property
 
 */
- (id)profileGet:(NSString *)propertyName;

/*!
 @method
 
 @abstract
 Get the CleverTap ID of the User Profile.
 
 @discussion
 The CleverTap ID is the unique identifier assigned to the User Profile by CleverTap.
 
 */
- (NSString *)profileGetCleverTapID;

/*!
 @method
 
 @abstract
 Returns a unique CleverTap identifier suitable for use with install attribution providers.
 
 */
- (NSString *)profileGetCleverTapAttributionIdentifier;

#pragma mark User Action Events API

/*!
 @method
 
 @abstract
 Record an event.
 
 Reserved event names: "Stayed", "Notification Clicked", "Notification Viewed", "UTM Visited", "Notification Sent", "App Launched", "wzrk_d", are prohibited.
 
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 
 @param event           event name
 */
- (void)recordEvent:(NSString *)event;

/*!
 @method
 
 @abstract
 Records an event with properties.
 
 @discussion
 Property keys must be NSString and values must be one of NSString, NSNumber, BOOL or NSDate.
 Reserved event names: "Stayed", "Notification Clicked", "Notification Viewed", "UTM Visited", "Notification Sent", "App Launched", "wzrk_d", are prohibited.
 Keys are limited to 32 characters.
 Values are limited to 40 bytes.
 Longer will be truncated.
 Maximum number of event properties is 16.
 
 @param event           event name
 @param properties      properties dictionary
 */
- (void)recordEvent:(NSString *)event withProps:(NSDictionary *)properties;

/*!
 @method
 
 @abstract
 Records the special Charged event with properties.
 
 @discussion
 Charged is a special event in CleverTap. It should be used to track transactions or purchases.
 Recording the Charged event can help you analyze how your customers are using your app, or even to reach out to loyal or lost customers.
 The transaction total or subscription charge should be recorded in an event property called “Amount” in the chargeDetails param.
 Set your transaction ID or the receipt ID as the value of the "Charged ID" property of the chargeDetails param.
 
 You can send an array of purchased item dictionaries via the items param.
 
 Property keys must be NSString and values must be one of NSString, NSNumber, BOOL or NSDATE.
 Keys are limited to 32 characters.
 Values are limited to 40 bytes.
 Longer will be truncated.
 
 @param chargeDetails   charge transaction details dictionary
 @param items           charged items array
 */
- (void)recordChargedEventWithDetails:(NSDictionary *)chargeDetails andItems:(NSArray *)items;

/*!
 @method
 
 @abstract
 Record an error event.
 
 @param message           error message
 @param code              int error code
 */

- (void)recordErrorWithMessage:(NSString *)message andErrorCode:(int)code;

/*!
 @method
 
 @abstract
 Get the time of the first recording of the event.
 
 Be sure to call enablePersonalization prior to invoking this method.
 
 @param event           event name
 */
- (NSTimeInterval)eventGetFirstTime:(NSString *)event;

/*!
 @method
 
 @abstract
 Get the time of the last recording of the event.
 Be sure to call enablePersonalization prior to invoking this method.
 
 @param event           event name
 */

- (NSTimeInterval)eventGetLastTime:(NSString *)event;

/*!
 @method
 
 @abstract
 Get the number of occurrences of the event.
 Be sure to call enablePersonalization prior to invoking this method.
 
 @param event           event name
 */
- (int)eventGetOccurrences:(NSString *)event;

/*!
 @method
 
 @abstract
 Get the user's event history.
 
 @discussion
 Returns a dictionary of CleverTapEventDetail objects (eventName, firstTime, lastTime, occurrences), keyed by eventName.
 
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 
 */
- (NSDictionary *)userGetEventHistory;

/*!
 @method
 
 @abstract
 Get the details for the event.
 
 @discussion
 Returns a CleverTapEventDetail object (eventName, firstTime, lastTime, occurrences)
 
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 
 @param event           event name
 */
- (CleverTapEventDetail *)eventGetDetail:(NSString *)event;


#pragma mark Session API

/*!
 @method
 
 @abstract
 Get the elapsed time of the current user session.
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 */
- (NSTimeInterval)sessionGetTimeElapsed;

/*!
 @method
 
 @abstract
 Get the utm referrer details for this user session.
 
 @discussion
 Returns a CleverTapUTMDetail object (source, medium and campaign).
 
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 
 */
- (CleverTapUTMDetail *)sessionGetUTMDetails;

/*!
 @method
 
 @abstract
 Get the total number of visits by this user.
 
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 */
- (int)userGetTotalVisits;

/*!
 @method
 
 @abstract
 Get the total screens viewed by this user.
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 
 */
- (int)userGetScreenCount;

/*!
 @method
 
 @abstract
 Get the last prior visit time for this user.
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 
 */
- (NSTimeInterval)userGetPreviousVisitTime;

/* ------------------------------------------------------------------------------------------------------
* Synchronization
*/


/*!
 @abstract 
 Posted when the CleverTap User Profile/Event History has changed in response to a synchronization call to the CleverTap servers.
 
 @discussion 
 CleverTap provides a flexible notification system for informing applications when changes have occured
 to the CleverTap User Profile/Event History in response to synchronization activities.
 
 CleverTap leverages the NSNotification broadcast mechanism to notify your application when changes occur.
 Your application should observe CleverTapProfileDidChangeNotification in order to receive notifications.
 
 Be sure to call enablePersonalization (typically once at app launch) to enable synchronization.
 
 Change data will be returned in the userInfo property of the NSNotification, and is of the form: 
 {
    "profile":{"<property1>":{"oldValue":<value>, "newValue":<value>}, ...},
    "events:{"<eventName>":
                {"count":
                    {"oldValue":(int)<old count>, "newValue":<new count>},
                "firstTime":
                    {"oldValue":(double)<old first time event occurred>, "newValue":<new first time event occurred>},
                "lastTime":
                    {"oldValue":(double)<old last time event occurred>, "newValue":<new last time event occurred>},
            }, ...
        }
 }
 
 */
extern NSString *const CleverTapProfileDidChangeNotification;

/*!
 
 @abstract
 Posted when the CleverTap User Profile is initialized.
 
 @discussion
 Useful for accessing the CleverTap ID of the User Profile.
 
 The CleverTap ID is the unique identifier assigned to the User Profile by CleverTap.
 
 The CleverTap ID will be returned in the userInfo property of the NSNotifcation in the form: {@"CleverTapID":CleverTapID}.
 
 */
extern NSString *const CleverTapProfileDidInitializeNotification;


/*!
 
 @method
 
 @abstract 
 The `CleverTapSyncDelegate` protocol provides additional/alternative methods for notifying
 your application (the adopting delegate) about synchronization-related changes to the User Profile/Event History.
 
 @see CleverTapSyncDelegate.h
 
 @discussion
 This sets the CleverTapSyncDelegate.
 
 Be sure to call enablePersonalization (typically once at app launch) to enable synchronization.
 
 @param delegate     an object conforming to the CleverTapSyncDelegate Protocol
 */
- (void)setSyncDelegate:(id <CleverTapSyncDelegate>)delegate;

#if !defined(CLEVERTAP_APP_EXTENSION)
/*!

 @method

 @abstract
 The `CleverTapInAppNotificationDelegate` protocol provides methods for notifying
 your application (the adopting delegate) about in-app notifications.

 @see CleverTapInAppNotificationDelegate.h

 @discussion
 This sets the CleverTapInAppNotificationDelegate.

 @param delegate     an object conforming to the CleverTapInAppNotificationDelegate Protocol
 */
- (void)setInAppNotificationDelegate:(id <CleverTapInAppNotificationDelegate>)delegate;
#endif

#if !defined(CLEVERTAP_APP_EXTENSION)
/* ------------------------------------------------------------------------------------------------------
 * Notifications
 */

/*!
 @method
 
 @abstract
 Register the device to receive push notifications.
 
 @discussion
 This will associate the device token with the current user to allow push notifications to the user.
 
 @param pushToken     device token as returned from application:didRegisterForRemoteNotificationsWithDeviceToken:
 */
- (void)setPushToken:(NSData *)pushToken;

/*!
 @method
 
 @abstract
 Convenience method to register the device push token as as string.
 
 @discussion
 This will associate the device token with the current user to allow push notifications to the user.
 
 @param pushTokenString     device token as returned from application:didRegisterForRemoteNotificationsWithDeviceToken: converted to an NSString.
 */
- (void)setPushTokenAsString:(NSString *)pushTokenString;

/*!
 @method
 
 @abstract
 Track and process a push notification based on its payload.
 
 @discussion
 By calling this method, CleverTap will automatically track user notification interaction for you.
 If the push notification contains a deep link, CleverTap will handle the call to application:openUrl: with the deep link.
 
 @param data         notification payload
 */
- (void)handleNotificationWithData:(id)data;

#endif

#if !defined(CLEVERTAP_APP_EXTENSION)
/*!
 @method
 
 @abstract
 Manually initiate the display of any pending in app notifications.
 
 */
- (void)showInAppNotificationIfAny;

#endif

#if !defined(CLEVERTAP_APP_EXTENSION)
/* ------------------------------------------------------------------------------------------------------
 * Referrer tracking
 */

/*!
 @method
 
 @abstract
 Track incoming referrers.
 
 @discussion
 By calling this method, CleverTap will automatically track incoming referrer utm details.

 
 @param url                     the incoming NSURL
 @param sourceApplication       the source application
 */
- (void)handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication;

/*!
 @method
 
 @abstract
 Manually track incoming referrers.
 
 @discussion
 Call this to manually track the utm details for an incoming install referrer.
 
 
 @param source                   the utm source
 @param medium                   the utm medium
 @param campaign                 the utm campaign
 */
- (void)pushInstallReferrerSource:(NSString *)source
                           medium:(NSString *)medium
                         campaign:(NSString *)campaign;

#endif

/* ------------------------------------------------------------------------------------------------------
 * Admin
 */

/*!
 @method
 
 @abstract
 Set the debug logging level
 
 @discussion
 0 = off, 1 = on
 
 @param level  the level to set (0 or 1)
 
 */
+ (void)setDebugLevel:(int)level;


#pragma mark deprecations as of version 2.0.3

+ (CleverTap *)push __attribute__((deprecated("Deprecated as of version 2.0.3, use sharedInstance instead")));

+ (CleverTap *)event __attribute__((deprecated("Deprecated as of version 2.0.3, use sharedInstance instead")));

+ (CleverTap *)profile __attribute__((deprecated("Deprecated as of version 2.0.3, use sharedInstance instead")));

+ (CleverTap *)session  __attribute__((deprecated("Deprecated as of version 2.0.3, use sharedInstance instead")));

- (void)eventName:(NSString *)event __attribute__((deprecated("Deprecated as of version 2.0.3, use recordEvent: instead")));

- (void)eventName:(NSString *)event eventProps:(NSDictionary *)properties __attribute__((deprecated("Deprecated as of version 2.0.3, use recordEvent:withProps: instead")));

- (void)chargedEventWithDetails:(NSDictionary *)chargeDetails andItems:(NSArray *)items __attribute__((deprecated("Deprecated as of version 2.0.3, use recordChargedEventWithDetails:andItems: instead")));

- (void)profile:(NSDictionary *)profileDictionary __attribute__((deprecated("Deprecated as of version 2.0.3, use profilePush: instead")));

- (void)graphUser:(id)fbGraphUser __attribute__((deprecated("Deprecated as of version 2.0.3, use profilePushGraphUser: instead")));

- (void)googlePlusUser:(id)googleUser __attribute__((deprecated("Deprecated as of version 2.0.3, use profilePushGooglePlusUser: instead")));
#if !defined(CLEVERTAP_APP_EXTENSION)
+ (void)setPushToken:(NSData *)pushToken __attribute__((deprecated("Deprecated as of version 2.0.3, use [[CleverTap sharedInstance] setPushToken:] instead")));

+ (void)notifyApplicationLaunchedWithOptions:(NSDictionary *)launchOptions __attribute__((deprecated));

+ (void)showInAppNotificationIfAny __attribute__((deprecated("Deprecated as of version 2.0.3, use [[CleverTap sharedInstance] showInAppNotificationIfAny] instead")));

+ (void)handleNotificationWithData:(id)data __attribute__((deprecated("Deprecated as of version 2.0.3, use [[CleverTap sharedInstance] handleNotificationWithData:] instead")));

+ (void)handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication __attribute__((deprecated("Deprecated as of version 2.0.3, use [[CleverTap sharedInstance] handleOpenUrl:sourceApplication:] instead")));
#endif
+ (void)notifyViewLoaded:(UIViewController *)viewController __attribute__((deprecated));

#if !defined(CLEVERTAP_APP_EXTENSION)
+ (void)pushInstallReferrerSource:(NSString *)source
                           medium:(NSString *)medium
                         campaign:(NSString *)campaign __attribute__((deprecated("Deprecated as of version 2.0.3, use [[CleverTap sharedInstance] pushInstallReferrerSource:medium:campaign] instead")));
#endif
#pragma mark Event API messages

- (NSTimeInterval)getFirstTime:(NSString *)event __attribute__((deprecated("Deprecated as of version 2.0.3, use eventGetFirstTime: instead")));

- (NSTimeInterval)getLastTime:(NSString *)event __attribute__((deprecated("Deprecated as of version 2.0.3, use eventGetLastTime: instead")));

- (int)getOccurrences:(NSString *)event __attribute__((deprecated("Deprecated as of version 2.0.3, use eventGetOccurrences: instead")));

- (NSDictionary *)getHistory __attribute__((deprecated("Deprecated as of version 2.0.3, use userGetEventHistory: instead")));

- (CleverTapEventDetail *)getEventDetail:(NSString *)event __attribute__((deprecated("Deprecated as of version 2.0.3, use eventGetDetail: instead")));

#pragma mark Profile API messages

- (id)getProperty:(NSString *)propertyName __attribute__((deprecated("Deprecated as of version 2.0.3, use profileGet: instead")));

#pragma mark Session API messages

- (NSTimeInterval)getTimeElapsed __attribute__((deprecated("Deprecated as of version 2.0.3, use sessionGetTimeElapsed: instead")));

- (int)getTotalVisits __attribute__((deprecated("Deprecated as of version 2.0.3, use userGetTotalVisits: instead")));

- (int)getScreenCount __attribute__((deprecated("Deprecated as of version 2.0.3, use userGetScreenCount: instead")));

- (NSTimeInterval)getPreviousVisitTime __attribute__((deprecated("Deprecated as of version 2.0.3, use userGetPreviousVisitTime: instead")));

- (CleverTapUTMDetail *)getUTMDetails __unused  __attribute__((deprecated("Deprecated as of version 2.0.3, use sessionGetUTMDetails: instead")));


@end

#pragma clang diagnostic pop

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#if defined(CLEVERTAP_HOST_WATCHOS)
#import <WatchConnectivity/WatchConnectivity.h>
#endif

#if TARGET_OS_TV
#define CLEVERTAP_TVOS 1
#endif

#if defined(CLEVERTAP_TVOS)
#define CLEVERTAP_NO_INAPP_SUPPORT 1
#define CLEVERTAP_NO_REACHABILITY_SUPPORT 1
#define CLEVERTAP_NO_INBOX_SUPPORT 1
#define CLEVERTAP_NO_DISPLAY_UNIT_SUPPORT 1
#define CLEVERTAP_NO_GEOFENCE_SUPPORT 1
#endif

@protocol CleverTapDomainDelegate;
@protocol CleverTapSyncDelegate;
@protocol CleverTapURLDelegate;
@protocol CleverTapPushNotificationDelegate;
#if !CLEVERTAP_NO_INAPP_SUPPORT
@protocol CleverTapInAppNotificationDelegate;
@class CTTemplateContext;
@protocol CTTemplateProducer;
#endif

@protocol CTBatchSentDelegate;
@protocol CTAttachToBatchHeaderDelegate;
@protocol CTSwitchUserDelegate;

@class CleverTapEventDetail;
@class CleverTapUTMDetail;
@class CleverTapInstanceConfig;
@class CleverTapFeatureFlags;
@class CleverTapProductConfig;

@class CTInAppNotification;
#import "CTVar.h"

#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedMethodInspection"

typedef NS_ENUM(int, CleverTapLogLevel) {
    CleverTapLogOff = -1,
    CleverTapLogInfo = 0,
    CleverTapLogDebug = 1
};

typedef NS_ENUM(int, CleverTapChannel) {
    CleverTapPushNotification = 0,
    CleverTapAppInbox = 1,
    CleverTapInAppNotification = 2
};

typedef NS_ENUM(int, CTSignedCallEvent) {
    SIGNED_CALL_OUTGOING_EVENT = 0,
    SIGNED_CALL_INCOMING_EVENT,
    SIGNED_CALL_END_EVENT
};

typedef NS_ENUM(int, CleverTapEncryptionLevel) {
    CleverTapEncryptionNone = 0,
    CleverTapEncryptionMedium = 1
};

typedef void (^CleverTapFetchInAppsBlock)(BOOL success);

@interface CleverTap : NSObject

#pragma mark - Properties

/* -----------------------------------------------------------------------------
 * Instance Properties
 */

/**
 CleverTap Configuration (e.g. the CleverTap accountId, token, region, other configuration properties...) for this instance.
 */

@property (nonatomic, strong, readonly, nonnull) CleverTapInstanceConfig *config;

/**
 CleverTap region/ domain value for signed call domain setup
 */
@property (nonatomic, strong, readwrite, nullable) NSString *signedCallDomain;


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
 
 Returns nil if the CleverTap Account ID and Token are not provided in apps info.plist
 
 */
+ (nullable instancetype)sharedInstance;

/*!
 @method
 
 @abstract
 Initializes and returns a singleton instance of the API.
 
 @discussion
 This method will set up a singleton instance of the CleverTap class, when you want to make calls to CleverTap
 elsewhere in your code, you can use this singleton or call sharedInstanceWithCleverTapId.
 
 Returns nil if the CleverTap Account ID and Token are not provided in apps info.plist
 
 CleverTapUseCustomId key should be set to YES in apps info.plist to enable support for setting custom cleverTapID.
 
 */
+ (nullable instancetype)sharedInstanceWithCleverTapID:(NSString * _Nonnull)cleverTapID;

/*!
 @method
 
 @abstract
 Auto integrates CleverTap and initializes and returns a singleton instance of the API.
 
 @discussion
 This method will auto integrate CleverTap to automatically handle device token registration and
 push notification/url referrer tracking, and set up a singleton instance of the CleverTap class,
 when you want to make calls to CleverTap elsewhere in your code, you can use this singleton or call sharedInstance.
 
 Returns nil if the CleverTap Account ID and Token are not provided in apps info.plist
 
 */
+ (nullable instancetype)autoIntegrate;

/*!
 @method
 
 @abstract
 Auto integrates with CleverTapID CleverTap and initializes and returns a singleton instance of the API.
 
 @discussion
 This method will auto integrate CleverTap to automatically handle device token registration and
 push notification/url referrer tracking, and set up a singleton instance of the CleverTap class,
 when you want to make calls to CleverTap elsewhere in your code, you can use this singleton or call sharedInstance.
 
 Returns nil if the CleverTap Account ID and Token are not provided in apps info.plist
 
 CleverTapUseCustomId key should be set to YES in apps info.plist to enable support for setting custom cleverTapID.
 
 */
+ (nullable instancetype)autoIntegrateWithCleverTapID:(NSString * _Nonnull)cleverTapID;

/*!
 @method
 
 @abstract
 Returns the CleverTap instance corresponding to the config.accountId param. Use this for multiple instances of the SDK.
 
 @discussion
 Create an instance of CleverTapInstanceConfig with your CleverTap Account Id, Token, Region(if any) and other optional config properties.
 Passing that into this method will create (if necessary, and on all subsequent calls return) a singleton instance mapped to the config.accountId property.
 
 */
+ (instancetype _Nonnull )instanceWithConfig:(CleverTapInstanceConfig * _Nonnull)config;

/*!
 @method
 
 @abstract
 Returns the CleverTap instance corresponding to the config.accountId param. Use this for multiple instances of the SDK.
 
 @discussion
 Create an instance of CleverTapInstanceConfig with your CleverTap Account Id, Token, Region(if any) and other optional config properties.
 Passing that into this method will create (if necessary, and on all subsequent calls return) a singleton instance mapped to the config.accountId property.
 
 */
+ (instancetype _Nonnull)instanceWithConfig:(CleverTapInstanceConfig * _Nonnull)config andCleverTapID:(NSString * _Nonnull)cleverTapID;

/*!
 @method
 
 @abstract
 Returns the CleverTap instance corresponding to the CleverTap accountId param.
 
 @discussion
 Returns the instance if such is already created, otherwise loads it from cache.
 
 @param accountId  the CleverTap account id
 */
+ (CleverTap *_Nullable)getGlobalInstance:(NSString *_Nonnull)accountId;

/*!
 @method
 
 @abstract
 Set the CleverTap AccountID and Token
 
 @discussion
 Sets the CleverTap account credentials.  Once thes default shared instance is intialized subsequent calls will be ignored.
 Only has effect on the default shared instance.
 
 @param accountID  the CleverTap account id
 @param token      the CleverTap account token
 
 */
+ (void)changeCredentialsWithAccountID:(NSString * _Nonnull)accountID andToken:(NSString * _Nonnull)token __attribute__((deprecated("Deprecated as of version 3.1.7, use setCredentialsWithAccountID:andToken instead")));

/*!
 @method
 
 @abstract
 Set the CleverTap AccountID, Token and Region
 
 @discussion
 Sets the CleverTap account credentials.  Once the default shared instance is intialized subsequent calls will be ignored.
 Only has effect on the default shared instance.
 
 @param accountID  the CleverTap account id
 @param token      the CleverTap account token
 @param region     the dedicated CleverTap region
 
 */
+ (void)changeCredentialsWithAccountID:(NSString * _Nonnull)accountID token:(NSString * _Nonnull)token region:(NSString * _Nonnull)region __attribute__((deprecated("Deprecated as of version 3.1.7, use setCredentialsWithAccountID:token:region instead")));

/*!
 @method
 
 @abstract
 Set the CleverTap AccountID and Token
 
 @discussion
 Sets the CleverTap account credentials.  Once the default shared instance is intialized subsequent calls will be ignored.
 Only has effect on the default shared instance.
 
 @param accountID  the CleverTap account id
 @param token      the CleverTap account token
 
 */
+ (void)setCredentialsWithAccountID:(NSString * _Nonnull)accountID andToken:(NSString * _Nonnull)token;

/*!
 @method
 
 @abstract
 Set the CleverTap AccountID, Token and Region
 
 @discussion
 Sets the CleverTap account credentials.  Once the default shared instance is intialized subsequent calls will be ignored.
 Only has effect on the default shared instance.
 
 @param accountID  the CleverTap account id
 @param token      the CleverTap account token
 @param region     the dedicated CleverTap region
 
 */
+ (void)setCredentialsWithAccountID:(NSString * _Nonnull)accountID token:(NSString * _Nonnull)token region:(NSString * _Nonnull)region;

/*!
 @method
 
 @abstract
 Sets the CleverTap AccountID, token and proxy domain URL
 
 @discussion
 Sets the CleverTap account credentials and proxy domain URL. Once the default shared instance is intialized subsequent calls will be ignored.
 Only has effect on the default shared instance.
 
 @param accountID  the CleverTap account id
 @param token the CleverTap account token
 @param proxyDomain the domain of the proxy server eg: example.com or subdomain.example.com
 */
+ (void)setCredentialsWithAccountID:(NSString * _Nonnull)accountID token:(NSString * _Nonnull)token proxyDomain:(NSString * _Nonnull)proxyDomain;

/*!
 @method
 
 @abstract
 Sets the CleverTap AccountID, token, proxy domain URL for APIs and spiky proxy domain URL for push impression APIs
 
 @discussion
 Sets the CleverTap account credentials and proxy domain URL. Once the default shared instance is intialized subsequent calls will be ignored.
 Only has effect on the default shared instance.
 
 @param accountID  the CleverTap account id
 @param token the CleverTap account token
 @param proxyDomain the domain of the proxy server eg: example.com or subdomain.example.com
 @param spikyProxyDomain the domain of the proxy server for push impression eg: example.com or subdomain.example.com
 */
+ (void)setCredentialsWithAccountID:(NSString * _Nonnull)accountID token:(NSString * _Nonnull)token proxyDomain:(NSString * _Nonnull)proxyDomain spikyProxyDomain:(NSString * _Nonnull)spikyProxyDomain;

/*!
 @method
 
 @abstract
 Sets the CleverTap AccountID, token, proxy domain URL for APIs and spiky proxy domain URL for push impression APIs
 
@discussion
Sets the CleverTap account credentials and proxy domain URL. Once the default shared instance is intialized subsequent calls will be ignored.
Only has effect on the default shared instance.

@param accountID  the CleverTap account id
@param token the CleverTap account token
@param proxyDomain the domain of the proxy server eg: example.com or subdomain.example.com
@param spikyProxyDomain the domain of the proxy server for push impression eg: example.com or subdomain.example.com
@param handshakeDomain the domain to be used for clevertap handshake
 */
+ (void)setCredentialsWithAccountID:(NSString * _Nonnull)accountID token:(NSString * _Nonnull)token proxyDomain:(NSString * _Nonnull)proxyDomain spikyProxyDomain:(NSString * _Nonnull)spikyProxyDomain handshakeDomain:(NSString * _Nonnull)handshakeDomain;

/*!
 @method
 
 @abstract
 notify the SDK instance of application launch
 
 */
- (void)notifyApplicationLaunchedWithOptions:launchOptions;

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
 Store the users location on the default shared CleverTap instance.
 
 @discussion
 Optional.  If you're application is collection the user location you can pass it to CleverTap
 for, among other things, more fine-grained geo-targeting and segmentation purposes.
 
 @param location       CLLocationCoordiate2D
 */
+ (void)setLocation:(CLLocationCoordinate2D)location;

/*!
 @method
 
 @abstract
 Store the users location on a particular CleverTap SDK instance.
 
 @discussion
 Optional.  If you're application is collection the user location you can pass it to CleverTap
 for, among other things, more fine-grained geo-targeting and segmentation purposes.
 
 @param location       CLLocationCoordiate2D
 */
- (void)setLocation:(CLLocationCoordinate2D)location;

/*!
 
 @abstract
 Posted when the CleverTap Geofences are updated.
 
 @discussion
 Useful for accessing the CleverTap geofences
 
 */
extern NSString * _Nonnull const CleverTapGeofencesDidUpdateNotification;

/*!
 @method
 
 @abstract
 Creates a separate and distinct user profile identified by one or more of Identity or Email values,
 and populated with the key-values included in the properties dictionary.
 
 @discussion
 If your app is used by multiple users, you can use this method to assign them each a unique profile to track them separately.
 
 If instead you wish to assign multiple Identity and/or Email values to the same user profile,
 use profilePush rather than this method.
 
 If none of Identity or Email is included in the properties dictionary,
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
- (void)onUserLogin:(NSDictionary *_Nonnull)properties;

/*!
 @method
 
 @abstract
 Creates a separate and distinct user profile identified by one or more of Identity, Email, FBID or GPID values,
 and populated with the key-values included in the properties dictionary.
 
 @discussion
 If your app is used by multiple users, you can use this method to assign them each a unique profile to track them separately.
 
 If instead you wish to assign multiple Identity and/or Email values to the same user profile,
 use profilePush rather than this method.
 
 If none of Identity or Email is included in the properties dictionary,
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
 
 CleverTapUseCustomId key should be set to YES in apps info.plist to enable support for setting custom cleverTapID.
 
 @param properties       properties dictionary
 @param cleverTapID        the CleverTap id
 
 */
- (void)onUserLogin:(NSDictionary *_Nonnull)properties withCleverTapID:(NSString * _Nonnull)cleverTapID;

/*!
 @method
 
 @abstract
 Enables tracking opt out for the currently active user.
 
 @discussion
 Use this method to opt the current user out of all event/profile tracking.
 You must call this method separately for each active user profile (e.g. when switching user profiles using onUserLogin).
 Once enabled, no events will be saved remotely or locally for the current user. To re-enable tracking call this method with enabled set to NO.
 
 @param enabled         BOOL Whether tracking opt out should be enabled/disabled.
 */
- (void)setOptOut:(BOOL)enabled;

/*!
 @method
 
 @abstract
 Disables/Enables sending events to the server.
 
 @discussion
 If you want to stop recorded events from being sent to the server, use this method to set the SDK instance to offline. Once offline, events will be recorded and queued locally but will not be sent to the server until offline is disabled. Calling this method again with offline set to NO will allow events to be sent to server and the SDK instance will immediately attempt to send events that have been queued while offline.
 
 @param offline         BOOL Whether sending events to servers should be disabled(TRUE)/enabled(FALSE).
 */
- (void)setOffline:(BOOL)offline;

/*!
 @method
 
 @abstract
 Enables the reporting of device network-related information, including IP address.  This reporting is disabled by default.
 
 @discussion
 Use this method to enable device network-related information tracking, including IP address.
 This reporting is disabled by default.  To re-disable tracking call this method with enabled set to NO.
 
 @param enabled         BOOL Whether device network info reporting should be enabled/disabled.
 */
- (void)enableDeviceNetworkInfoReporting:(BOOL)enabled;

#pragma mark Profile API

/*!
 @method
 
 @abstract
 Set properties on the current user profile.
 
 @discussion
 Property keys must be NSString and values must be one of NSString, NSNumber, BOOL, NSDate.
 
 To add a multi-value (array) property value type please use profileAddValueToSet: forKey:
 
 @param properties       properties dictionary
 */
- (void)profilePush:(NSDictionary *_Nonnull)properties;

/*!
 @method
 
 @abstract
 Remove the property specified by key from the user profile.
 
 @param key       key string
 
 */
- (void)profileRemoveValueForKey:(NSString *_Nonnull)key;

/*!
 @method
 
 @abstract
 Method for setting a multi-value user profile property.
 
 Any existing value(s) for the key will be overwritten.
 
 @discussion
 Key must be NSString.
 Values must be NSStrings.
 Max 100 values, on reaching 100 cap, oldest value(s) will be removed.
 
 
 @param key       key string
 @param values    values NSArray<NSString *>
 
 */
- (void)profileSetMultiValues:(NSArray<NSString *> *_Nonnull)values forKey:(NSString *_Nonnull)key;

/*!
 @method
 
 @abstract
 Method for adding a unique value to a multi-value profile property (or creating if not already existing).
 
 If the key currently contains a scalar value, the key will be promoted to a multi-value property
 with the current value cast to a string and the new value(s) added
 
 @discussion
 Key must be NSString.
 Values must be NSStrings.
 Max 100 values, on reaching 100 cap, oldest value(s) will be removed.
 
 
 @param key       key string
 @param value     value string
 */
- (void)profileAddMultiValue:(NSString * _Nonnull)value forKey:(NSString *_Nonnull)key;

/*!
 @method
 
 @abstract
 Method for adding multiple unique values to a multi-value profile property (or creating if not already existing).
 
 If the key currently contains a scalar value, the key will be promoted to a multi-value property
 with the current value cast to a string and the new value(s) added.
 
 @discussion
 Key must be NSString.
 Values must be NSStrings.
 Max 100 values, on reaching 100 cap, oldest value(s) will be removed.
 
 
 @param key       key string
 @param values    values NSArray<NSString *>
 */
- (void)profileAddMultiValues:(NSArray<NSString *> *_Nonnull)values forKey:(NSString *_Nonnull)key;

/*!
 @method
 
 @abstract
 Method for removing a unique value from a multi-value profile property.
 
 If the key currently contains a scalar value, prior to performing the remove operation the key will be promoted to a multi-value property with the current value cast to a string.
 
 If the multi-value property is empty after the remove operation, the key will be removed.
 
 @param key       key string
 @param value     value string
 */
- (void)profileRemoveMultiValue:(NSString *_Nonnull)value forKey:(NSString *_Nonnull)key;

/*!
 @method
 
 @abstract
 Method for removing multiple unique values from a multi-value profile property.
 
 If the key currently contains a scalar value, prior to performing the remove operation the key will be promoted to a multi-value property with the current value cast to a string.
 
 If the multi-value property is empty after the remove operation, the key will be removed.
 
 @param key       key string
 @param values    values NSArray<NSString *>
 */
- (void)profileRemoveMultiValues:(NSArray<NSString *> * _Nonnull)values forKey:(NSString * _Nonnull)key;

/*!
 @method
 
 @abstract
 Method for incrementing a value for a single-value profile property (if it exists).
 
 @param key       key string
 @param value     value number
 */
- (void)profileIncrementValueBy:(NSNumber *_Nonnull)value forKey:(NSString *_Nonnull)key;

/*!
 @method
 
 @abstract
 Method for decrementing a value for a single-value profile property (if it exists).
 
 @param key       key string
 @param value     value number
 */
- (void)profileDecrementValueBy:(NSNumber *_Nonnull)value forKey:(NSString *_Nonnull)key;

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
- (id _Nullable )profileGet:(NSString *_Nonnull)propertyName;

/*!
 @method
 
 @abstract
 Get the CleverTap ID of the User Profile.
 
 @discussion
 The CleverTap ID is the unique identifier assigned to the User Profile by CleverTap.
 
 */
- (NSString *_Nullable)profileGetCleverTapID;

/*!
 @method
 
 @abstract
 Get CleverTap account Id.
 
 @discussion
 The CleverTap account Id is the unique identifier assigned to the Account by CleverTap.
 
 */
- (NSString *_Nullable)getAccountID;

/*!
 @method
 
 @abstract
 Returns a unique CleverTap identifier suitable for use with install attribution providers.
 
 */
- (NSString *_Nullable)profileGetCleverTapAttributionIdentifier;

#pragma mark User Action Events API

/*!
 @method
 
 @abstract
 Record an event.
 
 Reserved event names: "Stayed", "Notification Clicked", "Notification Viewed", "UTM Visited", "Notification Sent", "App Launched", "wzrk_d", are prohibited.
 
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 
 @param event           event name
 */
- (void)recordEvent:(NSString *_Nonnull)event;

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
- (void)recordEvent:(NSString *_Nonnull)event withProps:(NSDictionary *_Nonnull)properties;

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
- (void)recordChargedEventWithDetails:(NSDictionary *_Nonnull)chargeDetails andItems:(NSArray *_Nonnull)items;

/*!
 @method
 
 @abstract
 Record an error event.
 
 @param message           error message
 @param code              int error code
 */

- (void)recordErrorWithMessage:(NSString *_Nonnull)message andErrorCode:(int)code;

/*!
 @method
 
 @abstract
 Record a screen view.
 
 @param screenName           the screen name
 */
- (void)recordScreenView:(NSString *_Nonnull)screenName;

/*!
 @method
 
 @abstract
 Record Notification Viewed for Push Notifications.
 
 @param notificationData       notificationData id
 */
- (void)recordNotificationViewedEventWithData:(id _Nonnull)notificationData;

/*!
 @method
 
 @abstract
 Record Notification Clicked for Push Notifications.
 
 @param notificationData       notificationData id
 */
- (void)recordNotificationClickedEventWithData:(id _Nonnull)notificationData;

/*!
 @method
 
 @abstract
 Get the time of the first recording of the event.
 
 Be sure to call enablePersonalization prior to invoking this method.
 
 @param event           event name
 */
- (NSTimeInterval)eventGetFirstTime:(NSString *_Nonnull)event;

/*!
 @method
 
 @abstract
 Get the time of the last recording of the event.
 Be sure to call enablePersonalization prior to invoking this method.
 
 @param event           event name
 */

- (NSTimeInterval)eventGetLastTime:(NSString *_Nonnull)event;

/*!
 @method
 
 @abstract
 Get the number of occurrences of the event.
 Be sure to call enablePersonalization prior to invoking this method.
 
 @param event           event name
 */
- (int)eventGetOccurrences:(NSString *_Nonnull)event;

/*!
 @method
 
 @abstract
 Get the user's event history.
 
 @discussion
 Returns a dictionary of CleverTapEventDetail objects (eventName, firstTime, lastTime, occurrences), keyed by eventName.
 
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 
 */
- (NSDictionary *_Nullable)userGetEventHistory;

/*!
 @method
 
 @abstract
 Get the details for the event.
 
 @discussion
 Returns a CleverTapEventDetail object (eventName, firstTime, lastTime, occurrences)
 
 Be sure to call enablePersonalization (typically once at app launch) prior to using this method.
 
 @param event           event name
 */
- (CleverTapEventDetail *_Nullable)eventGetDetail:(NSString *_Nullable)event;


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
- (CleverTapUTMDetail *_Nullable)sessionGetUTMDetails;

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
extern NSString * _Nonnull const CleverTapProfileDidChangeNotification;

/*!
 
 @abstract
 Posted when the CleverTap User Profile is initialized.
 
 @discussion
 Useful for accessing the CleverTap ID of the User Profile.
 
 The CleverTap ID is the unique identifier assigned to the User Profile by CleverTap.
 
 The CleverTap ID and cooresponding CleverTapAccountID will be returned in the userInfo property of the NSNotifcation in the form: {@"CleverTapID":CleverTapID, @"CleverTapAccountID":CleverTapAccountID}.
 
 */
extern NSString * _Nonnull const CleverTapProfileDidInitializeNotification;


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
- (void)setSyncDelegate:(id <CleverTapSyncDelegate> _Nullable)delegate;


/*!
 
 @method
 
 @abstract
 The `CleverTapPushNotificationDelegate` protocol provides methods for notifying
 your application (the adopting delegate) about push notifications.
 
 @see CleverTapPushNotificationDelegate.h
 
 @discussion
 This sets the CleverTapPushNotificationDelegate.
 
 @param delegate     an object conforming to the CleverTapPushNotificationDelegate Protocol
 */

- (void)setPushNotificationDelegate:(id <CleverTapPushNotificationDelegate> _Nullable)delegate;

#if !CLEVERTAP_NO_INAPP_SUPPORT
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
- (void)setInAppNotificationDelegate:(id <CleverTapInAppNotificationDelegate> _Nullable)delegate;

/*!
 @method
 
 @abstract
 Forces inapps to update from the server.
 
 @discussion
 Forces inapps to update from the server.
 
 @param block a callback with a boolean flag whether the update was successful.
 */
- (void)fetchInApps:(CleverTapFetchInAppsBlock _Nullable)block;

#endif

/*!
 
 @method
 
 @abstract
 The `CleverTapURLDelegate` protocol provides a method for the confirming class to implement custom handling for URLs in case of in-app notification CTAs, push notifications and App inbox.
 
 @see CleverTapURLDelegate.h
 
 @discussion
 This sets the CleverTapURLDelegate.
 
 @param delegate     an object conforming to the CleverTapURLDelegate Protocol
 */
- (void)setUrlDelegate:(id <CleverTapURLDelegate> _Nullable)delegate;

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
- (void)setPushToken:(NSData *_Nonnull)pushToken;

/*!
 @method
 
 @abstract
 Convenience method to register the device push token as as string.
 
 @discussion
 This will associate the device token with the current user to allow push notifications to the user.
 
 @param pushTokenString     device token as returned from application:didRegisterForRemoteNotificationsWithDeviceToken: converted to an NSString.
 */
- (void)setPushTokenAsString:(NSString *_Nonnull)pushTokenString;

/*!
 @method
 
 @abstract
 Track and process a push notification based on its payload.
 
 @discussion
 By calling this method, CleverTap will automatically track user notification interaction for you.
 If the push notification contains a deep link, CleverTap will handle the call to application:openUrl: with the deep link, as long as the application is not in the foreground.
 
 @param data         notification payload
 */
- (void)handleNotificationWithData:(id _Nonnull )data;

/*!
 @method
 
 @abstract
 Track and process a push notification based on its payload.
 
 @discussion
 By calling this method, CleverTap will automatically track user notification interaction for you.
 If the push notification contains a deep link, CleverTap will handle the call to application:openUrl: with the deep link, as long as the application is not in the foreground or you pass TRUE in the openInForeground param.
 
 @param data                     notification payload
 @param openInForeground         Boolean as to whether the SDK should open any deep link attached to the notification while the application is in the foreground.
 */
- (void)handleNotificationWithData:(id _Nonnull )data openDeepLinksInForeground:(BOOL)openInForeground;

/*!
 @method
 
 @abstract
 Convenience method when using multiple SDK instances to track and process a push notification based on its payload.
 
 @discussion
 By calling this method, CleverTap will automatically track user notification interaction for you; the specific instance of the CleverTap SDK to process the call is determined based on the CleverTap AccountID included in the notification payload and, if not present, will default to the shared instance.
 
 If the push notification contains a deep link, CleverTap will handle the call to application:openUrl: with the deep link, as long as the application is not in the foreground or you pass TRUE in the openInForeground param.
 
 @param notification             notification payload
 @param openInForeground         Boolean as to whether the SDK should open any deep link attached to the notification while the application is in the foreground.
 */
+ (void)handlePushNotification:(NSDictionary*_Nonnull)notification openDeepLinksInForeground:(BOOL)openInForeground;

/*!
 @method
 
 @abstract
 Determine whether a notification originated from CleverTap
 
 @param payload  notification payload
 */
- (BOOL)isCleverTapNotification:(NSDictionary *_Nonnull)payload;

#if !CLEVERTAP_NO_INAPP_SUPPORT
/*!
 @method
 
 @abstract
 Manually initiate the display of any pending in app notifications.
 
 */
- (void)showInAppNotificationIfAny __attribute__((deprecated("Use resumeInAppNotifications to show pending InApp notifications. This will be removed soon.")));

#endif

/* ------------------------------------------------------------------------------------------------------
 * Referrer tracking
 */

/*!
 @method
 
 @abstract
 Track incoming referrers on a specific SDK instance.
 
 @discussion
 By calling this method, the specific CleverTap instance will automatically track incoming referrer utm details.
 When implementing multiple SDK instances, consider using +handleOpenURL: instead.
 
 
 @param url                     the incoming NSURL
 @param sourceApplication       the source application
 */
- (void)handleOpenURL:(NSURL *_Nonnull)url sourceApplication:(NSString *_Nullable)sourceApplication;

/*!
 @method
 
 @abstract
 Convenience method to track incoming referrers when using multile SDK instances.
 
 @discussion
 By calling this method, if the url contains a query parameter with a CleverTap AccountID, the SDK will pass the URL to that specific instance for processing.
 If no CleverTap AccountID param is present, the SDK will default to passing the URL to the shared instance.
 
 @param url                     the incoming NSURL
 */
+ (void)handleOpenURL:(NSURL*_Nonnull)url;


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
- (void)pushInstallReferrerSource:(NSString *_Nullable)source
                           medium:(NSString *_Nullable)medium
                         campaign:(NSString *_Nullable)campaign;

/* ------------------------------------------------------------------------------------------------------
 * Admin
 */

/*!
 @method
 
 @abstract
 Set the debug logging level
 
 @discussion
 Set using CleverTapLogLevel enum values (or the corresponding int values).
 SDK logging defaults to CleverTapLogInfo, which prints minimal SDK integration-related messages
 
 CleverTapLogOff - turns off all SDK logging.
 CleverTapLogInfo - default, prints minimal SDK integration related messages.
 CleverTapLogDebug - enables verbose debug logging.
 In Swift, use the respective rawValues:  CleverTapLogLevel.off.rawValue, CleverTapLogLevel.info.rawValue,
 CleverTapLogLevel.debug.rawValue.
 
 @param level  the level to set
 */
+ (void)setDebugLevel:(int)level;

/*!
 @method
 
 @abstract
 Get the debug logging level
 
 @discussion
 Returns the currently set debug logging level.
 */
+ (CleverTapLogLevel)getDebugLevel;

/*!
 @method
 
 @abstract
 Set the Library name for Auxiliary SDKs
 
 @discussion
 Call this to method to set library name in the Auxiliary SDK
 */
- (void)setLibrary:(NSString * _Nonnull)name;

/*!
 @method
 
 @abstract
 Set the Library name and version for Auxiliary SDKs
 
 @discussion
 Call this to method to set library name and version in the Auxiliary SDK
 */
- (void)setCustomSdkVersion:(NSString * _Nonnull)name version:(int)version;

/*!
 @method
 
 @abstract
 Updates a user locale after session start.
 
 @discussion
 Call this to method to set locale
 */
- (void)setLocale:(NSLocale * _Nonnull)locale;

/*!
 @method
 
 @abstract
 Store the users location for geofences on the default shared CleverTap instance.
 
 @discussion
 Optional.  If you're application is collection the user location you can pass it to CleverTap
 for, among other things, more fine-grained geo-targeting and segmentation purposes.
 
 @param location       CLLocationCoordiate2D
 */
- (void)setLocationForGeofences:(CLLocationCoordinate2D)location withPluginVersion:(NSString *_Nullable)version;

/*!
 @method
 
 @abstract
 Record the error for geofences
 
 @param error       NSError
 */
- (void)didFailToRegisterForGeofencesWithError:(NSError *_Nullable)error;

/*!
 @method
 
 @abstract
 Record Geofence Entered Event.
 
 @param geofenceDetails      details of the Geofence
 */
- (void)recordGeofenceEnteredEvent:(NSDictionary *_Nonnull)geofenceDetails;

/*!
 @method
 
 @abstract
 Record Geofence Exited Event.
 
 @param geofenceDetails       details of the Geofence
 */
- (void)recordGeofenceExitedEvent:(NSDictionary *_Nonnull)geofenceDetails;

#if defined(CLEVERTAP_HOST_WATCHOS)
/** HostWatchOS
 */
- (BOOL)handleMessage:(NSDictionary<NSString *, id> *_Nonnull)message forWatchSession:(WCSession *_Nonnull)session API_AVAILABLE(ios(9.0));
#endif

/*!
 @method
 
 @abstract
 Record Signed Call System Events.
 
 @param calldetails call details dictionary
 */
- (void)recordSignedCallEvent:(int)eventRawValue forCallDetails:(NSDictionary *_Nonnull)calldetails;

/*!
 @method
 
 @abstract
 The `CTDomainDelegate` protocol provides methods for notifying your application (the adopting delegate) about domain/ region changes.
 
 @see CleverTap+DCDomain.h
 
 @discussion
 This sets the CTDomainDelegate
 
 @param delegate  an object conforming to the CTDomainDelegate Protocol
 */
- (void)setDomainDelegate:(id <CleverTapDomainDelegate> _Nullable)delegate;

/*!
 @method
 
 @abstract
 Get region/ domain string value
 */
- (NSString *_Nullable)getDomainString;

/*!
 @method
 
 @abstract
 Checks if a custom CleverTapID is valid
 */
+ (BOOL)isValidCleverTapId:(NSString *_Nullable)cleverTapID;

#pragma mark Product Experiences - Vars

/*!
 @method
 
 @abstract
 Adds a callback to be invoked when variables are initialised with server values. Will be called each time new values are fetched.
 
 @param block a callback to add.
 */
- (void)onVariablesChanged:(CleverTapVariablesChangedBlock _Nonnull )block;

/*!
 @method
 
 @abstract
 Adds a callback to be invoked only once when variables are initialised with server values.
 
 @param block a callback to add.
 */
- (void)onceVariablesChanged:(CleverTapVariablesChangedBlock _Nonnull )block;
 
/*!
 @method
 
 @abstract
 Uploads variables to the server. Requires Development/Debug build/configuration.
 */
- (void)syncVariables;

/*!
 @method
 
 @abstract
 Uploads variables to the server.
 
 @param isProduction Provide `true` if variables must be sync in Productuon build/configuration.
 */
- (void)syncVariables:(BOOL)isProduction;

/*!
 @method
 
 @abstract
 Forces variables to update from the server.
 
 @discussion
 Forces variables to update from the server. If variables have changed, the appropriate callbacks will fire. Use sparingly as if the app is updated, you'll have to deal with potentially inconsistent state or user experience.
 The provided callback has a boolean flag whether the update was successful or not. The callback fires regardless
 of whether the variables have changed.
 
 @param block a callback with a boolean flag whether the update was successful.
 */
- (void)fetchVariables:(CleverTapFetchVariablesBlock _Nullable)block;

/*!
 @method
 
 @abstract
 Get an instance of a variable or a group.
 
 @param name The name of the variable or the group.
 
 @return
 The instance of the variable or the group, or nil if not created yet.

 */
- (CTVar * _Nullable)getVariable:(NSString * _Nonnull)name;

/*!
 @method
 
 @abstract
 Get a copy of the current value of a variable or a group.
 
 @param name The name of the variable or the group.
 */
- (id _Nullable)getVariableValue:(NSString * _Nonnull)name;

/*!
 @method
 
 @abstract
 Adds a callback to be invoked when no more file downloads are pending (either when no files needed to be downloaded or all downloads have been completed).
 
 @param block a callback to add.
 */
- (void)onVariablesChangedAndNoDownloadsPending:(CleverTapVariablesChangedBlock _Nonnull )block;

/*!
 @method
 
 @abstract
 Adds a callback to be invoked only once when no more file downloads are pending (either when no files needed to be downloaded or all downloads have been completed).
 
 @param block a callback to add.
 */
- (void)onceVariablesChangedAndNoDownloadsPending:(CleverTapVariablesChangedBlock _Nonnull )block;

#if !CLEVERTAP_NO_INAPP_SUPPORT
#pragma mark Custom Templates and Functions

/*!
 Register ``CTCustomTemplate`` templates through a ``CTTemplateProducer``.
 See ``CTCustomTemplateBuilder``. Templates must be registered before the ``CleverTap`` instance, that would use
 them, is created.
 
 Typically, this method is called from `UIApplicationDelegate/application:didFinishLaunchingWithOptions:`.
 If your application uses multiple ``CleverTap`` instances, use the ``CleverTapInstanceConfig`` within the
 ``CTTemplateProducer/defineTemplates:`` method to differentiate which templates should be registered to which instances.
 
 This method can be called multiple times with different ``CTTemplateProducer`` producers, however all of the
 produced templates must have unique names.
 
 @param producer A ``CTTemplateProducer`` to register and define templates with.
 */
+ (void)registerCustomInAppTemplates:(id<CTTemplateProducer> _Nonnull)producer;

/*!
 @method
 
 @abstract
 Uploads Custom in-app templates and app functions to the server. Requires Development/Debug build/configuration.
 */
- (void)syncCustomTemplates;

/*!
 @method
 
 @abstract
 Uploads Custom in-app templates and app functions to the server.
 
 @param isProduction Provide `true` if Custom in-app templates and app functions must be sync in Productuon build/configuration.
 */
- (void)syncCustomTemplates:(BOOL)isProduction;

/*!
 @method
 
 @abstract
 Retrieves the active context for a template that is currently displaying. If the provided template
 name is not of a currently active template, this method returns nil.
 
 @param templateName The template name to get the active context for.
 
 @return
 A CTTemplateContext object representing the active context for the given template name, or nil if no active context exists.
 
 */
- (CTTemplateContext * _Nullable)activeContextForTemplate:(NSString * _Nonnull)templateName;

#endif

@end

#pragma clang diagnostic pop

#import <Foundation/Foundation.h>
#import "CleverTap.h"
#if !CLEVERTAP_NO_INAPP_SUPPORT
#import "CTInAppDisplayManager.h"
#import "CTInAppEvaluationManager.h"
#import "CTInAppFCManager.h"
#import "CTInAppStore.h"
#endif
#import "CTCryptMigrator.h"

@class CTInAppDisplayManager;
@class CTFileDownloader;
@class CTValidationResult;
@class CTSessionManager;
@protocol CTSwitchUserDelegate;

@interface CleverTap (Internal)

typedef NS_ENUM(NSInteger, CleverTapEventType) {
    CleverTapEventTypePage,
    CleverTapEventTypePing,
    CleverTapEventTypeProfile,
    CleverTapEventTypeRaised,
    CleverTapEventTypeData,
    CleverTapEventTypeNotificationViewed,
    CleverTapEventTypeFetch,
};

#if !CLEVERTAP_NO_INAPP_SUPPORT
@property (strong, nonatomic, nullable) CleverTapFetchInAppsBlock fetchInAppsBlock;
@property (nonatomic, strong, readonly) CTInAppDisplayManager * _Nullable inAppDisplayManager;
@property (nonatomic, strong, readonly) CTInAppEvaluationManager * _Nullable inAppEvaluationManager;
@property (nonatomic, strong, readonly) CTInAppFCManager * _Nullable inAppFCManager;
@property (nonatomic, strong, readonly) CTInAppStore * _Nullable inAppStore;
@property (nonatomic, strong, readonly) CTImpressionManager * _Nullable impressionManager;
@property (nonatomic, assign, readonly) BOOL isAppForeground;
@property (nonatomic, strong, readonly) CTDeviceInfo * _Nonnull deviceInfo;
@property (nonatomic, strong, readonly) CTCryptMigrator * _Nonnull cryptMigrator;
@property (atomic, strong, readonly) CTSessionManager * _Nonnull sessionManager;
@property (nonatomic, strong, readonly) CTCustomTemplatesManager * _Nullable customTemplatesManager;
#endif

@property (nonatomic, strong, readonly) CTFileDownloader * _Nullable fileDownloader;

@property (atomic, assign, readonly) BOOL isUserSwitching;

+ (NSMutableDictionary<NSString *, CleverTap *> * _Nullable)getInstances;

- (void)recordInAppNotificationStateEvent:(BOOL)clicked
                          forNotification:(CTInAppNotification * _Nonnull)notification andQueryParameters:(NSDictionary * _Nullable)params;

#if !CLEVERTAP_NO_INAPP_SUPPORT
- (void)recordInAppNotificationMediaError:(CTValidationResult * _Nonnull)error
                          forNotification:(CTInAppNotification * _Nonnull)notification;
#endif

- (void)fetchInAppPreviewContent:(NSString* _Nullable)url onSuccess:(void(^ _Nonnull)(NSDictionary* _Nullable inappJSON))completion;

- (id <CleverTapURLDelegate> _Nullable)urlDelegate;

/*!
 @method
 
 @abstract
 Fetch in-action in-app content from backend after inactionDuration expires
 
 @discussion
 Sends wzrk_fetch event with t=6 and target ID
 
 @param inAppId the campaign ID (ti) to fetch content for
 */
- (void)fetchInactionInApps:(NSString *_Nonnull)inAppId;

// MARK: - Live Activities (iOS only; excluded from tvOS)
#if !TARGET_OS_TV
/*!
 @method

 @abstract
 Queues a Live Activity data event (PTS token, activity registration, token update, or
 activity end) to be sent to the CleverTap backend. The `data` dictionary becomes the
 value of the top-level `"data"` key in the event payload.

 @discussion
 This is an internal helper used by the `CleverTap (LiveActivities)` category.
 It must not be called from app code.

 @param data A non-empty dictionary containing the Live Activity payload fields.
 */
- (void)pushLiveActivityData:(NSDictionary *_Nonnull)data;

/*!
 @method

 @abstract
 Records a Live Activity analytics event (lifecycle / impression / click) through the same
 pipeline as a push "Notification Viewed" event. `eventName` becomes the event's `evtName`
 and `data` its `evtData`, queued as a `CleverTapEventTypeNotificationViewed` event.

 @discussion
 Internal helper used by the `CleverTap (LiveActivities)` category. Must not be called
 from app code. These events intentionally do NOT go through the public `recordEvent:` API.

 @param eventName The event name (e.g. "Live Activity").
 @param data A dictionary of event properties (activity id, activity type, campaign id, etc.).
 */
- (void)pushLiveActivityEventNamed:(NSString *_Nonnull)eventName data:(NSDictionary *_Nonnull)data;

/*!
 @method

 @abstract
 Records a Live Activity impression / click identical to a push "Notification Viewed" /
 "Notification Clicked" event. The impression is queued as `CleverTapEventTypeNotificationViewed`
 and the click as `CleverTapEventTypeRaised`; `wzrk` (the activity payload's campaign dictionary)
 becomes the event's `evtData`.

 @discussion Internal helpers used by the `CleverTap (LiveActivities)` category.
 */
- (void)pushLiveActivityViewedEventWithData:(NSDictionary *_Nonnull)wzrk;
- (void)pushLiveActivityClickedEventWithData:(NSDictionary *_Nonnull)wzrk;

/*!
 @method

 @abstract
 Registers a switch-user delegate so the Live Activity manager can re-send its cached
 tokens to the backend when the device ID (CleverTap ID) changes after `onUserLogin`.

 @param delegate An object implementing `CTSwitchUserDelegate` (the Live Activity manager).
 */
- (void)addLiveActivitySwitchUserDelegate:(id<CTSwitchUserDelegate> _Nonnull)delegate;
#endif // !TARGET_OS_TV — Live Activities

@end

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
@class CTNdStore;
@class CTNdFCManager;
@class CTNdEvaluationManager;
@class CTImpressionManager;
@class CTInAppTriggerManager;

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

#if !CLEVERTAP_NO_DISPLAY_UNIT_SUPPORT
@property (nonatomic, strong, readonly) CTNdStore * _Nullable ndStore;
@property (nonatomic, strong, readonly) CTNdFCManager * _Nullable ndFCManager;
@property (nonatomic, strong, readonly) CTNdEvaluationManager * _Nullable ndEvaluationManager;
@property (nonatomic, strong, readonly) CTImpressionManager * _Nullable ndImpressionManager;
@property (nonatomic, strong, readonly) CTInAppTriggerManager * _Nullable ndTriggerManager;
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

#if !CLEVERTAP_NO_DISPLAY_UNIT_SUPPORT
/*!
 @method

 @abstract
 Asks the server for a fresh Native Display rule bundle in the middle of a session.

 @discussion
 Sends a wzrk_fetch event with t set to kCTNdFetchTypeMeta. The server answers with
 adUnit_notifs_ss. handleDisplayUnitResponse: already reads that key. Rules normally arrive with App
 Launched. This is the way to get them without waiting for the next launch.

 It is internal, not public. The t value is still a placeholder. A public method would make that
 number a promise to customers before the backend team has settled it. The Android SDK keeps its
 fetchNativeDisplayMeta internal for the same reason.
 */
- (void)fetchNativeDisplayMeta;
#endif

@end

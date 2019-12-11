#import "CleverTap.h"
#import "CTConstants.h"
#import "CTLogger.h"
#import "CTPlistInfo.h"
#import "CTDeviceInfo.h"
#import "CTPreferences.h"
#import "CleverTapEventDetail.h"
#import "CleverTapUTMDetail.h"
#import "CleverTapInstanceConfig.h"
#import "CleverTapInstanceConfigPrivate.h"
#import "CleverTapSyncDelegate.h"
#import "CleverTapInAppNotificationDelegate.h"
#import "CTSwizzle.h"
#import "CTUtils.h"
#import "CTUriHelper.h"
#import "CTValidationResult.h"
#import "CTValidator.h"
#import "CTEventBuilder.h"
#import "CTProfileBuilder.h"
#import "CTLocalDataStore.h"
#import "CTInAppUtils.h"
#import "CTInAppFCManager.h"
#import "CTInAppNotification.h"
#import "CTInAppDisplayViewController.h"
#if !CLEVERTAP_NO_INAPP_SUPPORT
#import "CleverTapJSInterface.h"
#import "CTInAppHTMLViewController.h"
#import "CTInterstitialViewController.h"
#import "CTHalfInterstitialViewController.h"
#import "CTCoverViewController.h"
#import "CTHeaderViewController.h"
#import "CTFooterViewController.h"
#import "CTAlertViewController.h"
#import "CTCoverImageViewController.h"
#import "CTInterstitialImageViewController.h"
#import "CTHalfInterstitialImageViewController.h"
#endif
#import "CTLocationManager.h"
#if !CLEVERTAP_NO_INBOX_SUPPORT
#import "CTInboxController.h"
#import "CleverTap+Inbox.h"
#import "CleverTapInboxViewControllerPrivate.h"
#endif
#if CLEVERTAP_SSL_PINNING
#import "CTPinnedNSURLSessionDelegate.h"
static NSArray* sslCertNames;
#endif

#if !CLEVERTAP_NO_AB_SUPPORT
#import "CTABTestController.h"
#import "CleverTap+ABTesting.h"
#import "CTABVariant.h"
#endif

#if !CLEVERTAP_NO_DISPLAY_UNIT_SUPPORT
#import "CTDisplayUnitController.h"
#import "CleverTap+DisplayUnit.h"
#endif

#import <objc/runtime.h>

static const void *const kQueueKey = &kQueueKey;
static const void *const kNotificationQueueKey = &kNotificationQueueKey;

static const int kMaxBatchSize = 49;
NSString* const kQUEUE_NAME_PROFILE = @"net_queue_profile";
NSString* const kQUEUE_NAME_EVENTS = @"events";
NSString* const kQUEUE_NAME_NOTIFICATIONS = @"notifications";

NSString* const kHANDSHAKE_URL = @"https://wzrkt.com/hello";

NSString* const kREDIRECT_DOMAIN_KEY = @"CLTAP_REDIRECT_DOMAIN_KEY";
NSString* const kREDIRECT_NOTIF_VIEWED_DOMAIN_KEY = @"CLTAP_REDIRECT_NOTIF_VIEWED_DOMAIN_KEY";
NSString* const kMUTED_TS_KEY = @"CLTAP_MUTED_TS_KEY";

NSString* const kREDIRECT_HEADER = @"X-WZRK-RD";
NSString* const kREDIRECT_NOTIF_VIEWED_HEADER = @"X-WZRK-SPIKY-RD";
NSString* const kMUTE_HEADER = @"X-WZRK-MUTE";

NSString* const kACCOUNT_ID_HEADER = @"X-CleverTap-Account-Id";
NSString* const kACCOUNT_TOKEN_HEADER = @"X-CleverTap-Token";

NSString* const kI_KEY = @"CLTAP_I_KEY";
NSString* const kJ_KEY = @"CLTAP_J_KEY";

NSString* const kFIRST_TS_KEY = @"CLTAP_FIRST_TS_KEY";
NSString* const kLAST_TS_KEY = @"CLTAP_LAST_TS_KEY";

NSString *const kMultiUserPrefix = @"mt_";

NSString *const kNetworkInfoReportingKey = @"NetworkInfo";

NSString *const kLastSessionPing = @"last_session_ping";
NSString *const kLastSessionTime = @"lastSessionTime";
NSString *const kSessionId = @"sessionId";

NSString *const kWR_KEY_PERSONALISATION_ENABLED = @"boolPersonalisationEnabled";
NSString *const kWR_KEY_AB_TEST_EDITOR_ENABLED = @"boolABTestEditorEnabled";
NSString *const CleverTapProfileDidInitializeNotification = CLTAP_PROFILE_DID_INITIALIZE_NOTIFICATION;
NSString* const CleverTapProfileDidChangeNotification = CLTAP_PROFILE_DID_CHANGE_NOTIFICATION;

NSString *const kCachedGUIDS = @"CachedGUIDS";
NSString *const kOnUserLoginAction = @"onUserLogin";
NSString *const kInstanceWithCleverTapIDAction = @"instanceWithCleverTapID";

static int currentRequestTimestamp = 0;
static int initialAppEnteredForegroundTime = 0;

static BOOL isAutoIntegrated;

typedef NS_ENUM(NSInteger, CleverTapEventType) {
    CleverTapEventTypePage,
    CleverTapEventTypePing,
    CleverTapEventTypeProfile,
    CleverTapEventTypeRaised,
    CleverTapEventTypeData,
    CleverTapEventTypeNotificationViewed,
};

typedef NS_ENUM(NSInteger, CleverTapPushTokenRegistrationAction) {
    CleverTapPushTokenRegister,
    CleverTapPushTokenUnregister,
};

#if !CLEVERTAP_NO_INBOX_SUPPORT
@interface CleverTapInboxMessage ()
- (instancetype) init __unavailable;
- (instancetype)initWithJSON:(NSDictionary *)json;
@end
#endif

#if !CLEVERTAP_NO_INBOX_SUPPORT
@interface CleverTap () <CTInboxDelegate, CleverTapInboxViewControllerAnalyticsDelegate> {}
@property(atomic, strong) CTInboxController *inboxController;
@property(nonatomic, strong) NSMutableArray<CleverTapInboxUpdatedBlock> *inboxUpdateBlocks;
@end
#endif

#if !CLEVERTAP_NO_AB_SUPPORT
@interface CleverTap () <CTABTestingDelegate> {}
@property (nonatomic, strong) CTABTestController *abTestController;
@property (nonatomic, strong) NSMutableArray<CleverTapExperimentsUpdatedBlock> *experimentsUpdateBlocks;

@end
#endif

@interface CleverTap () <CTInAppNotificationDisplayDelegate> {}
#if CLEVERTAP_SSL_PINNING
@property(nonatomic, strong) CTPinnedNSURLSessionDelegate *urlSessionDelegate;
#endif
@end

#if !CLEVERTAP_NO_DISPLAY_UNIT_SUPPORT
@interface CleverTap () <CTDisplayUnitDelegate> {}
@property (nonatomic, strong) CTDisplayUnitController *displayUnitController;
@property (atomic, weak) id <CleverTapDisplayUnitDelegate> displayUnitDelegate;
@end
#endif

#import <UserNotifications/UserNotifications.h>

@interface CleverTap () <UIApplicationDelegate> {
    dispatch_queue_t _serialQueue;
    dispatch_queue_t _notificationQueue;
}

@property (nonatomic, strong, readwrite) CleverTapInstanceConfig *config;
@property (nonatomic, assign) NSTimeInterval lastAppLaunchedTime;
@property (nonatomic, strong) CTDeviceInfo *deviceInfo;
@property (nonatomic, strong) CTLocalDataStore *localDataStore;
@property (nonatomic, strong) CTInAppFCManager *inAppFCManager;
@property (nonatomic, assign) BOOL isAppForeground;

@property (nonatomic, strong) NSMutableArray *eventsQueue;
@property (nonatomic, strong) NSMutableArray *profileQueue;
@property (nonatomic, strong) NSMutableArray *notificationsQueue;
@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) NSString *redirectDomain;
@property (nonatomic, strong) NSString *explictEndpointDomain;
@property (nonatomic, strong) NSString *redirectNotifViewedDomain;
@property (nonatomic, strong) NSString *explictNotifViewedEndpointDomain;
@property (nonatomic, assign) NSTimeInterval lastMutedTs;
@property (nonatomic, assign) int sendQueueFails;

@property (nonatomic, assign) BOOL pushedAPNSId;
@property (atomic, assign) BOOL currentUserOptedOut;
@property (atomic, assign) BOOL offline;
@property (atomic, assign) BOOL enableNetworkInfoReporting;
@property (atomic, assign) BOOL appLaunchProcessed;
@property (atomic, assign) BOOL initialEventsPushed;
@property (atomic, assign) CLLocationCoordinate2D userSetLocation;
@property (nonatomic, assign) double lastLocationPingTime;

@property (nonatomic, assign) long minSessionSeconds;
@property (atomic, assign) long sessionId;
@property (atomic, assign) int screenCount;
@property (atomic, assign) BOOL firstSession;
@property (atomic, assign) int lastSessionLengthSeconds;

@property (atomic, retain) NSString *source;
@property (atomic, retain) NSString *medium;
@property (atomic, retain) NSString *campaign;
@property (atomic, retain) NSDictionary *wzrkParams;
@property (atomic, retain) NSDictionary *lastUTMFields;
@property (atomic, strong) NSString *currentViewControllerName;

@property(atomic, strong) NSMutableArray<CTValidationResult *> *pendingValidationResults;

@property(atomic, weak) id <CleverTapSyncDelegate> syncDelegate;
@property(atomic, weak) id <CleverTapInAppNotificationDelegate> inAppNotificationDelegate;

@property (atomic, strong) NSString *processingLoginUserIdentifier;

@property (nonatomic, assign, readonly) BOOL sslPinningEnabled;

- (instancetype)init __unavailable;

@end

@implementation CleverTap

@synthesize sessionId=_sessionId;
@synthesize source=_source;
@synthesize medium=_medium;
@synthesize campaign=_campaign;
@synthesize wzrkParams=_wzrkParams;
@synthesize syncDelegate=_syncDelegate;
@synthesize inAppNotificationDelegate=_inAppNotificationDelegate;
@synthesize userSetLocation=_userSetLocation;
@synthesize offline=_offline;

#if !CLEVERTAP_NO_DISPLAY_UNIT_SUPPORT
@synthesize displayUnitDelegate=_displayUnitDelegate;
#endif

static CTPlistInfo* _plistInfo;
static NSMutableDictionary<NSString*, CleverTap*> *_instances;
static CleverTapInstanceConfig *_defaultInstanceConfig;
static BOOL sharedInstanceErrorLogged;
static CLLocationCoordinate2D emptyLocation = {-1000.0, -1000.0}; // custom empty definition; will fail the CLLocationCoordinate2DIsValid test

// static here as we may have multiple instances handling inapps
static CTInAppDisplayViewController *currentDisplayController;
static NSMutableArray<CTInAppDisplayViewController*> *pendingNotificationControllers;

#pragma mark Lifecycle


+ (void)load {
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidFinishLaunchingNotification:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instances = [NSMutableDictionary new];
        _plistInfo = [CTPlistInfo sharedInstance];
        pendingNotificationControllers = [NSMutableArray new];
#if CLEVERTAP_SSL_PINNING
        // Only pin anchor/CA certificates
        sslCertNames = @[@"DigiCertGlobalRootCA", @"DigiCertSHA2SecureServerCA"];
#endif
    });
}

+ (void)onDidFinishLaunchingNotification:(NSNotification *)notification {
    if (initialAppEnteredForegroundTime <= 0) {
        initialAppEnteredForegroundTime = (int) [[[NSDate alloc] init] timeIntervalSince1970];
    }
    NSDictionary *launchOptions = notification.userInfo;
    if (!_instances || [_instances count] <= 0) {
        [[self sharedInstance] notifyApplicationLaunchedWithOptions:launchOptions];
        return;
    }
    for (CleverTap *instance in [_instances allValues]) {
        [instance notifyApplicationLaunchedWithOptions:launchOptions];
    }
}

+ (nullable instancetype)autoIntegrate {
    return [self _autoIntegrateWithCleverTapID:nil];
}

+ (nullable instancetype)autoIntegrateWithCleverTapID:(NSString *)cleverTapID {
   return [self _autoIntegrateWithCleverTapID:cleverTapID];
}

+ (nullable instancetype)_autoIntegrateWithCleverTapID:(NSString *)cleverTapID {
    CleverTapLogStaticDebug("%@: Auto Integration enabled", self);
    isAutoIntegrated = YES;
    [self swizzleAppDelegate];
    CleverTap *instance = cleverTapID ? [CleverTap sharedInstanceWithCleverTapID:cleverTapID] : [CleverTap sharedInstance];
    return instance;
}

+ (void)swizzleAppDelegate {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIApplication *sharedApplication = [self getSharedApplication];
        if (sharedApplication == nil) {
            return;
        }
        
        __strong id appDelegate = [sharedApplication delegate];
        Class cls = [sharedApplication.delegate class];
        SEL sel;
        
        // Token Handling
        sel = NSSelectorFromString(@"application:didFailToRegisterForRemoteNotificationsWithError:");
        if (!class_getInstanceMethod(cls, sel)) {
            SEL newSel = @selector(ct_application:didFailToRegisterForRemoteNotificationsWithError:);
            Method newMeth = class_getClassMethod([self class], newSel);
            IMP imp = method_getImplementation(newMeth);
            const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
            class_addMethod(cls, sel, imp, methodTypeEncoding);
        } else {
            __block NSInvocation *invocation = nil;
            invocation = [cls ct_swizzleMethod:sel withBlock:^(id obj, UIApplication *application, NSError *error) {
                [self ct_application:application didFailToRegisterForRemoteNotificationsWithError:error];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&error atIndex:3];
                [invocation invokeWithTarget:obj];
            } error:nil];
        }
        
        sel = NSSelectorFromString(@"application:didRegisterForRemoteNotificationsWithDeviceToken:");
        if (!class_getInstanceMethod(cls, sel)) {
            SEL newSel = @selector(ct_application:didRegisterForRemoteNotificationsWithDeviceToken:);
            Method newMeth = class_getClassMethod([self class], newSel);
            IMP imp = method_getImplementation(newMeth);
            const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
            class_addMethod(cls, sel, imp, methodTypeEncoding);
        } else {
            __block NSInvocation *invocation = nil;
            invocation = [cls ct_swizzleMethod:sel withBlock:^(id obj, UIApplication *application, NSData *token) {
                [self ct_application:application didRegisterForRemoteNotificationsWithDeviceToken:token];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&token atIndex:3];
                [invocation invokeWithTarget:obj];
            } error:nil];
        }
        
        // Notification Handling
#if !defined(CLEVERTAP_TVOS)
        if (@available(iOS 10.0, *)) {
            Class ncdCls = [[UNUserNotificationCenter currentNotificationCenter].delegate class];
            if ([UNUserNotificationCenter class] && !ncdCls) {
                [[UNUserNotificationCenter currentNotificationCenter] addObserver:[self sharedInstance] forKeyPath:@"delegate" options:0 context:nil];
            } else if (class_getInstanceMethod(ncdCls, NSSelectorFromString(@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"))) {
                sel = NSSelectorFromString(@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:");
                __block NSInvocation *invocation = nil;
                invocation = [ncdCls ct_swizzleMethod:sel withBlock:^(id obj, UNUserNotificationCenter *center, UNNotificationResponse *response, void (^completion)(UIBackgroundFetchResult result) ) {
                    [CleverTap handlePushNotification:response.notification.request.content.userInfo openDeepLinksInForeground:YES];
                    [invocation setArgument:&center atIndex:2];
                    [invocation setArgument:&response atIndex:3];
                    [invocation setArgument:&completion atIndex:4];
                    [invocation invokeWithTarget:obj];
                } error:nil];
            }
        }
        if (class_getInstanceMethod(cls, NSSelectorFromString(@"application:didReceiveRemoteNotification:fetchCompletionHandler:"))) {
            sel = NSSelectorFromString(@"application:didReceiveRemoteNotification:fetchCompletionHandler:");
            __block NSInvocation *invocation = nil;
            invocation = [cls ct_swizzleMethod:sel withBlock:^(id obj, UIApplication *application, NSDictionary *userInfo, void (^completion)(void) ) {
                [CleverTap handlePushNotification:userInfo openDeepLinksInForeground:NO];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&userInfo atIndex:3];
                [invocation setArgument:&completion atIndex:4];
                [invocation invokeWithTarget:obj];
            } error:nil];
        } else if (class_getInstanceMethod(cls, NSSelectorFromString(@"application:didReceiveRemoteNotification:"))) {
            sel = NSSelectorFromString(@"application:didReceiveRemoteNotification:");
            __block NSInvocation *invocation = nil;
            invocation = [cls ct_swizzleMethod:sel withBlock:^(id obj, UIApplication *application, NSDictionary *userInfo) {
                [CleverTap handlePushNotification:userInfo openDeepLinksInForeground:NO];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&userInfo atIndex:3];
                [invocation invokeWithTarget:obj];
            } error:nil];
        } else {
            sel = NSSelectorFromString(@"application:didReceiveRemoteNotification:");
            SEL newSel = @selector(ct_application:didReceiveRemoteNotification:);
            Method newMeth = class_getClassMethod([self class], newSel);
            IMP imp = method_getImplementation(newMeth);
            const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
            class_addMethod(cls, sel, imp, methodTypeEncoding);
        }
#endif
        
        // URL handling
        if (class_getInstanceMethod(cls, NSSelectorFromString(@"application:openURL:sourceApplication:annotation:"))) {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
            sel = NSSelectorFromString(@"application:openURL:sourceApplication:annotation:");
            __block NSInvocation *invocation = nil;
            invocation = [cls ct_swizzleMethod:sel withBlock:^(id obj, UIApplication *application, NSURL *url, NSString *sourceApplication, id annotation ) {
                [[self class] ct_application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&url atIndex:3];
                [invocation setArgument:&sourceApplication atIndex:4];
                [invocation setArgument:&annotation atIndex:5];
                [invocation invokeWithTarget:obj];
            } error:nil];
#endif
        } else if (class_getInstanceMethod(cls, NSSelectorFromString(@"application:openURL:options:"))) {
            sel = NSSelectorFromString(@"application:openURL:options:");
            __block NSInvocation *invocation = nil;
            invocation = [cls ct_swizzleMethod:sel withBlock:^(id obj, UIApplication *application, NSURL *url, NSDictionary<UIApplicationOpenURLOptionsKey, id> *options ) {
                [[self class] ct_application:application openURL:url options:options];
                [invocation setArgument:&application atIndex:2];
                [invocation setArgument:&url atIndex:3];
                [invocation setArgument:&options atIndex:4];
                [invocation invokeWithTarget:obj];
            } error:nil];
        } else {
            if (@available(iOS 9.0, *)) {
                sel = NSSelectorFromString(@"application:openURL:options:");
                SEL newSel = @selector(ct_application:openURL:options:);
                Method newMeth = class_getClassMethod([self class], newSel);
                IMP imp = method_getImplementation(newMeth);
                const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
                class_addMethod(cls, sel, imp, methodTypeEncoding);
            } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
                sel = NSSelectorFromString(@"application:openURL:sourceApplication:annotation:");
                SEL newSel = @selector(ct_application:openURL:sourceApplication:annotation:);
                Method newMeth = class_getClassMethod([self class], newSel);
                IMP imp = method_getImplementation(newMeth);
                const char* methodTypeEncoding = method_getTypeEncoding(newMeth);
                class_addMethod(cls, sel, imp, methodTypeEncoding);
#endif
            }
            // UIApplication caches whether or not the delegate responds to certain selectors. Clearing out the delegate and resetting it gaurantees that gets updated
            [sharedApplication setDelegate:nil];
            // UIApplication won't assume ownership of AppDelegate for setDelegate calls add a retain here
            [sharedApplication setDelegate:(__bridge id)CFRetain((__bridge CFTypeRef)appDelegate)];
        }
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
#if !defined(CLEVERTAP_TVOS)
    if ([keyPath isEqualToString:@"delegate"]) {
        if (@available(iOS 10.0, *)) {
            Class cls = [[UNUserNotificationCenter currentNotificationCenter].delegate class];
            if (class_getInstanceMethod(cls, NSSelectorFromString(@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"))) {
                SEL sel = NSSelectorFromString(@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:");
                if (sel) {
                    __block NSInvocation *invocation = nil;
                    invocation = [cls ct_swizzleMethod:sel withBlock:^(id obj, UNUserNotificationCenter *center, UNNotificationResponse *response, void (^completion)(void) ) {
                        [CleverTap handlePushNotification:response.notification.request.content.userInfo openDeepLinksInForeground:YES];
                        [invocation setArgument:&center atIndex:2];
                        [invocation setArgument:&response atIndex:3];
                        [invocation setArgument:&completion atIndex:4];
                        [invocation invokeWithTarget:obj];
                    } error:nil];
                }
            }
        }
    }
#endif
}

#pragma mark AppDelegate Swizzles and Related

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0
#if !defined(CLEVERTAP_TVOS)
+ (BOOL)ct_application:(UIApplication *)application
               openURL:(NSURL *)url
     sourceApplication:(NSString *)sourceApplication
            annotation:(id)annotation {
    CleverTapLogStaticDebug(@"Handling openURL:sourceApplication: %@", url);
    [CleverTap handleOpenURL:url];
    return NO;
}
#endif
#endif
+ (BOOL)ct_application:(UIApplication *)application
               openURL:(NSURL *)url
               options:(NSDictionary<NSString*, id> *)options {
    CleverTapLogStaticDebug(@"Handling openURL:options: %@", url);
    [CleverTap handleOpenURL:url];
    return NO;
}

+ (void)ct_application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *deviceTokenString = [CTUtils deviceTokenStringFromData:deviceToken];
    if (!_instances || [_instances count] <= 0) {
        [[CleverTap sharedInstance] setPushTokenAsString:deviceTokenString];
        return;
    }
    for (CleverTap *instance in [_instances allValues]) {
        [instance setPushTokenAsString:deviceTokenString];
    }
}
+ (void)ct_application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    CleverTapLogStaticDebug(@"Application failed to register for remote notification: %@", error);
}
+ (void)ct_application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [CleverTap handlePushNotification:userInfo openDeepLinksInForeground:NO];
}

#pragma clang diagnostic pop

#pragma mark instance lifecycle

+ (nullable instancetype)sharedInstance {
    return [self _sharedInstanceWithCleverTapID:nil];
}

+ (nullable instancetype)sharedInstanceWithCleverTapID:(NSString *)cleverTapID {
     return [self _sharedInstanceWithCleverTapID:cleverTapID];
}

+ (nullable instancetype)_sharedInstanceWithCleverTapID:(NSString *)cleverTapID {
    if (_defaultInstanceConfig == nil) {
        if (!_plistInfo.accountId || !_plistInfo.accountToken) {
            if (!sharedInstanceErrorLogged) {
                sharedInstanceErrorLogged = YES;
                CleverTapLogStaticInfo(@"Unable to initialize default CleverTap SDK instance. %@: %@ %@: %@", CLTAP_ACCOUNT_ID_LABEL, _plistInfo.accountId, CLTAP_TOKEN_LABEL, _plistInfo.accountToken);
            }
            return nil;
        }
        
        _defaultInstanceConfig = [[CleverTapInstanceConfig alloc] initWithAccountId:_plistInfo.accountId accountToken:_plistInfo.accountToken accountRegion:_plistInfo.accountRegion isDefaultInstance:YES];
        
        if (_defaultInstanceConfig == nil) {
            return nil;
        }
        _defaultInstanceConfig.enablePersonalization = [CleverTap isPersonalizationEnabled];
        _defaultInstanceConfig.logLevel = [self getDebugLevel];
        CleverTapLogStaticInfo(@"Initializing default CleverTap SDK instance. %@: %@ %@: %@ %@: %@", CLTAP_ACCOUNT_ID_LABEL, _plistInfo.accountId, CLTAP_TOKEN_LABEL, _plistInfo.accountToken, CLTAP_REGION_LABEL, (!_plistInfo.accountRegion || _plistInfo.accountRegion.length < 1) ? @"default" : _plistInfo.accountRegion);
    }
    return [self instanceWithConfig:_defaultInstanceConfig andCleverTapID:cleverTapID];
}

+ (instancetype)instanceWithConfig:(CleverTapInstanceConfig*)config {
    return [self _instanceWithConfig:config andCleverTapID:nil];
}

+ (instancetype)instanceWithConfig:(CleverTapInstanceConfig *)config andCleverTapID:(NSString *)cleverTapID {
    return [self _instanceWithConfig:config andCleverTapID:cleverTapID];
}

+ (instancetype)_instanceWithConfig:(CleverTapInstanceConfig *)config andCleverTapID:(NSString *)cleverTapID {
    if (!_instances) {
        _instances = [[NSMutableDictionary alloc] init];
    }
    __block CleverTap *instance = [_instances objectForKey:config.accountId];
    if (instance == nil) {
#if !CLEVERTAP_NO_AB_SUPPORT
        // Default or first non-default instance gets the ABTestController
        config.enableABTesting =  (config.isDefaultInstance || [_instances count] <= 0);
#endif
        instance = [[self alloc] initWithConfig:config andCleverTapID:cleverTapID];
        _instances[config.accountId] = instance;
        [instance recordDeviceErrors];
    } else {
        if ([instance.deviceInfo isErrorDeviceID] && instance.config.useCustomCleverTapId && cleverTapID != nil && [CTValidator isValidCleverTapId:cleverTapID]) {
            [instance _asyncSwitchUser:nil withCachedGuid:nil andCleverTapID:cleverTapID forAction:kInstanceWithCleverTapIDAction];
        }
    }
    return instance;
}

- (instancetype)initWithConfig:(CleverTapInstanceConfig*)config andCleverTapID:(NSString *)cleverTapID {
    if ((self = [super init])) {
        _config = [config copy];
        if (_config.analyticsOnly) {
            CleverTapLogDebug(_config.logLevel, @"%@ is configured as analytics only!", self);
        }
        _deviceInfo = [[CTDeviceInfo alloc] initWithConfig:_config andCleverTapID:cleverTapID];
        NSMutableDictionary *initialProfileValues = [NSMutableDictionary new];
        if (_deviceInfo.carrier && ![_deviceInfo.carrier isEqualToString:@""]) {
            initialProfileValues[CLTAP_SYS_CARRIER] = _deviceInfo.carrier;
        }
        if (_deviceInfo.countryCode && ![_deviceInfo.countryCode isEqualToString:@""]) {
            initialProfileValues[CLTAP_SYS_CC] = _deviceInfo.countryCode;
        }
        if (_deviceInfo.timeZone&& ![_deviceInfo.timeZone isEqualToString:@""]) {
            initialProfileValues[CLTAP_SYS_TZ] = _deviceInfo.timeZone;
        }
        _localDataStore = [[CTLocalDataStore alloc] initWithConfig:_config andProfileValues:initialProfileValues];
        
        _serialQueue = dispatch_queue_create([_config.queueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_serialQueue, kQueueKey, (__bridge void *)self, NULL);
        
        _lastAppLaunchedTime = [self eventGetLastTime:@"App Launched"];
        self.pendingValidationResults = [NSMutableArray array];
        self.userSetLocation = emptyLocation;
        self.minSessionSeconds =  CLTAP_SESSION_LENGTH_MINS * 60;
        [self _setDeviceNetworkInfoReportingFromStorage];
        [self _setCurrentUserOptOutStateFromStorage];
        [self initNetworking];
        [self inflateQueuesAsync];
        [self addObservers];
#if !CLEVERTAP_NO_INAPP_SUPPORT
        if (!_config.analyticsOnly && ![[self class] runningInsideAppExtension]) {
            _notificationQueue = dispatch_queue_create([[NSString stringWithFormat:@"com.clevertap.notificationQueue:%@", _config.accountId] UTF8String], DISPATCH_QUEUE_SERIAL);
            dispatch_queue_set_specific(_notificationQueue, kNotificationQueueKey, (__bridge void *)self, NULL);
            _inAppFCManager = [[CTInAppFCManager alloc] initWithConfig:_config];
        }
#endif
        int now = [[[NSDate alloc] init] timeIntervalSince1970];
        if (now - initialAppEnteredForegroundTime > 5) {
            _config.isCreatedPostAppLaunched = YES;
        }
    }
    
#if !CLEVERTAP_NO_AB_SUPPORT
    // Default (flag is set in the config init) or first non-default instance gets the ABTestController
    if (!_config.enableABTesting) {
        _config.enableABTesting = (!_instances || [_instances count] <= 0);
    }
    [self _initABTesting];
#endif
    
    [self notifyUserProfileInitialized];

    return self;
}

// notify application code once we have a device GUID
- (void)notifyUserProfileInitialized {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *deviceID = self.deviceInfo.deviceId;
        if (!deviceID) return;
        CleverTapLogInternal(self.config.logLevel, @"%@: Notifying user profile initialized with ID %@", self, deviceID);
        
        id <CleverTapSyncDelegate> apiDelegate = [self syncDelegate];
        
        if (apiDelegate && [apiDelegate respondsToSelector:@selector(profileDidInitialize:)]) {
            [apiDelegate profileDidInitialize:deviceID];
        }
        if (apiDelegate && [apiDelegate respondsToSelector:@selector(profileDidInitialize:forAccountId:)]) {
            [apiDelegate profileDidInitialize:deviceID forAccountId:self.config.accountId];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:CleverTapProfileDidInitializeNotification object:nil userInfo:@{@"CleverTapID" : deviceID, @"CleverTapAccountID":self.config.accountId}];
    });
}

- (void) dealloc {
    [self removeObservers];
}

#pragma mark Private
+ (void)_changeCredentialsWithAccountID:(NSString *)accountID token:(NSString *)token region:(NSString *)region {
    if (_defaultInstanceConfig) {
        CleverTapLogStaticDebug(@"CleverTap SDK already initialized with accountID: %@ and token: %@. Cannot change credentials to %@ : %@", _defaultInstanceConfig.accountId, _defaultInstanceConfig.accountToken, accountID, token);
        return;
    }
    accountID = [accountID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    token = [token stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (region != nil && ![region isEqualToString:@""]) {
        region = [region stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (region.length <= 0) {
            region = nil;
        }
    }
    [_plistInfo changeCredentialsWithAccountID:accountID token:token region:region];
}

+ (void)runSyncMainQueue:(void (^)(void))block {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

+ (UIApplication *)getSharedApplication {
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if (UIApplicationClass && [UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return [UIApplication performSelector:@selector(sharedApplication)];
    }
    return nil;
}

+ (BOOL)runningInsideAppExtension {
    return [self getSharedApplication] == nil;
}

- (void)addObservers {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"CleverTap.%@", self.config.accountId];
}

- (NSString *)storageKeyWithSuffix: (NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@", self.config.accountId, suffix];
}

- (void)initNetworking {
    if (self.config.isDefaultInstance) {
        self.lastMutedTs = [CTPreferences getIntForKey:[self storageKeyWithSuffix:kLAST_TS_KEY] withResetValue:[CTPreferences getIntForKey:kMUTED_TS_KEY withResetValue:0]];
    } else {
     self.lastMutedTs = [CTPreferences getIntForKey:[self storageKeyWithSuffix:kLAST_TS_KEY] withResetValue:0];
    }
    self.redirectDomain = [self loadRedirectDomain];
    self.redirectNotifViewedDomain = [self loadRedirectNotifViewedDomain];
    [self setUpUrlSession];
    [self doHandshakeAsync];
}

- (void)setUpUrlSession {
    if (!self.urlSession) {
        NSURLSessionConfiguration *sc = [NSURLSessionConfiguration defaultSessionConfiguration];
        [sc setHTTPAdditionalHeaders:@{
                                       @"Content-Type" : @"application/json; charset=utf-8"
                                       }];
        
        sc.timeoutIntervalForRequest = CLTAP_REQUEST_TIME_OUT_INTERVAL;
        sc.timeoutIntervalForResource = CLTAP_REQUEST_TIME_OUT_INTERVAL;
        [sc setHTTPShouldSetCookies:NO];
        [sc setRequestCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        
#if CLEVERTAP_SSL_PINNING
        _sslPinningEnabled = YES;
        self.urlSessionDelegate = [[CTPinnedNSURLSessionDelegate alloc] initWithConfig:self.config];
        NSMutableArray *domains = [NSMutableArray arrayWithObjects:kCTApiDomain, nil];
        if (self.redirectDomain && ![self.redirectDomain isEqualToString:kCTApiDomain]) {
            [domains addObject:self.redirectDomain];
        }
        [self.urlSessionDelegate pinSSLCerts:sslCertNames forDomains:domains];
        self.urlSession = [NSURLSession sessionWithConfiguration:sc delegate:self.urlSessionDelegate delegateQueue:nil];
#else
        _sslPinningEnabled = NO;
        self.urlSession = [NSURLSession sessionWithConfiguration:sc];
#endif
    }
}

- (void)setUserSetLocation:(CLLocationCoordinate2D)location {
    _userSetLocation = location;
    if (!self.isAppForeground) return;
    // if in foreground, queue the ping event to transmit location update to server
    // min 10 second interval between location pings
    double now = [[[NSDate alloc] init] timeIntervalSince1970];
    if (now > (self.lastLocationPingTime + CLTAP_LOCATION_PING_INTERVAL_SECONDS)) {
        [self queueEvent:@{} withType:CleverTapEventTypePing];
        self.lastLocationPingTime = now;
    }
}

- (CLLocationCoordinate2D)userSetLocation {
    return _userSetLocation;
}

# pragma mark Handshake handling

- (void)clearRedirectDomain {
    self.redirectDomain = nil;
    self.redirectNotifViewedDomain = nil;
    [self persistRedirectDomain]; // if nil persist will remove
    self.redirectDomain = [self loadRedirectDomain]; // reload explicit domain if we have one else will be nil
    self.redirectNotifViewedDomain = [self loadRedirectNotifViewedDomain]; // reload explicit notification viewe domain if we have one else will be nil
}

- (NSString *)loadRedirectDomain {
    NSString *region = self.config.accountRegion;
    if (region) {
        region = [region stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].lowercaseString;
        if (region.length > 0) {
            self.explictEndpointDomain = [NSString stringWithFormat:@"%@.%@", region, kCTApiDomain];
            return self.explictEndpointDomain;
        }
    }
    NSString *domain = nil;
    if (self.config.isDefaultInstance) {
        domain = [CTPreferences getStringForKey:[self storageKeyWithSuffix:kREDIRECT_DOMAIN_KEY] withResetValue:[CTPreferences getStringForKey:kREDIRECT_DOMAIN_KEY withResetValue:nil]];
    } else {
        domain = [CTPreferences getStringForKey:[self storageKeyWithSuffix:kREDIRECT_DOMAIN_KEY] withResetValue:nil];
    }
    return domain;
}

- (NSString *)loadRedirectNotifViewedDomain {
    NSString *region = self.config.accountRegion;
    if (region) {
        region = [region stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].lowercaseString;
        if (region.length > 0) {
            self.explictNotifViewedEndpointDomain = [NSString stringWithFormat:@"%@-%@", region, kCTNotifViewedApiDomain];
            return self.explictNotifViewedEndpointDomain;
        }
    }
    NSString *domain = nil;
    if (self.config.isDefaultInstance) {
        domain = [CTPreferences getStringForKey:[self storageKeyWithSuffix:kREDIRECT_NOTIF_VIEWED_DOMAIN_KEY] withResetValue:[CTPreferences getStringForKey:kREDIRECT_NOTIF_VIEWED_DOMAIN_KEY withResetValue:nil]];
    } else {
        domain = [CTPreferences getStringForKey:[self storageKeyWithSuffix:kREDIRECT_NOTIF_VIEWED_DOMAIN_KEY] withResetValue:nil];
    }
    return domain;
}

- (void)persistRedirectDomain {
    if (self.redirectDomain != nil) {
        [CTPreferences putString:self.redirectDomain forKey:[self storageKeyWithSuffix:kREDIRECT_DOMAIN_KEY]];
#if CLEVERTAP_SSL_PINNING
        [self.urlSessionDelegate pinSSLCerts:sslCertNames forDomains:@[kCTApiDomain, self.redirectDomain]];
#endif
    } else {
        [CTPreferences removeObjectForKey:kREDIRECT_DOMAIN_KEY];
        [CTPreferences removeObjectForKey:[self storageKeyWithSuffix:kREDIRECT_DOMAIN_KEY]];
    }
}

- (void)persistRedirectNotifViewedDomain {
    if (self.redirectNotifViewedDomain != nil) {
        [CTPreferences putString:self.redirectNotifViewedDomain forKey:[self storageKeyWithSuffix:kREDIRECT_NOTIF_VIEWED_DOMAIN_KEY]];
#if CLEVERTAP_SSL_PINNING
        [self.urlSessionDelegate pinSSLCerts:sslCertNames forDomains:@[kCTNotifViewedApiDomain, self.redirectNotifViewedDomain]];
#endif
    } else {
        [CTPreferences removeObjectForKey:kREDIRECT_NOTIF_VIEWED_DOMAIN_KEY];
        [CTPreferences removeObjectForKey:[self storageKeyWithSuffix:kREDIRECT_NOTIF_VIEWED_DOMAIN_KEY]];
    }
}
- (void)persistMutedTs {
    self.lastMutedTs = [NSDate new].timeIntervalSince1970;
    [CTPreferences putInt:self.lastMutedTs forKey:[self storageKeyWithSuffix:kMUTED_TS_KEY]];
}

- (BOOL)needHandshake {
    if ([self isMuted] || self.explictEndpointDomain) return NO;
    return self.redirectDomain == nil;
}

- (void)doHandshakeAsync {
    [self runSerialAsync:^{
        if (![self needHandshake]) return;
        CleverTapLogInternal(self.config.logLevel, @"%@: starting handshake with %@", self, kHANDSHAKE_URL);
        NSMutableURLRequest *request = [self createURLRequestFromURL:[[NSURL alloc] initWithString:kHANDSHAKE_URL]];
        request.HTTPMethod = @"GET";
        // Need to simulate a synchronous request
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSURLSessionDataTask *task = [self.urlSession
                                      dataTaskWithRequest:request
                                      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                          if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                              NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                              if (httpResponse.statusCode == 200) {
                                                  [self updateStateFromResponseHeadersShouldRedirect:httpResponse.allHeaderFields];
                                                  [self updateStateFromResponseHeadersShouldRedirectForNotif:httpResponse.allHeaderFields];
                                                  [self handleHandshakeSuccess];
                                              }
                                          }
                                          dispatch_semaphore_signal(semaphore);
                                      }];
        [task resume];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }];
}

- (BOOL)updateStateFromResponseHeadersShouldRedirectForNotif:(NSDictionary *)headers {
    CleverTapLogInternal(self.config.logLevel, @"%@: processing response with headers:%@", self, headers);
    BOOL shouldRedirect = NO;
    @try {
        NSString *redirectNotifViewedDomain = headers[kREDIRECT_NOTIF_VIEWED_HEADER];
        if (redirectNotifViewedDomain != nil) {
            NSString *currentDomain = self.redirectNotifViewedDomain;
            self.redirectNotifViewedDomain = redirectNotifViewedDomain;
            if (![self.redirectNotifViewedDomain isEqualToString:currentDomain]) {
                shouldRedirect = YES;
                self.redirectNotifViewedDomain = redirectNotifViewedDomain;
                [self persistRedirectNotifViewedDomain];
            }
        }
        NSString *mutedString = headers[kMUTE_HEADER];
        BOOL muted = (mutedString == nil ? NO : [mutedString boolValue]);
        if (muted) {
            [self persistMutedTs];
            [self clearQueues];
        }
    } @catch(NSException *e) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Error processing Notification Viewed response headers: %@", self, e.debugDescription);
    }
    return shouldRedirect;
}

- (BOOL)updateStateFromResponseHeadersShouldRedirect:(NSDictionary *)headers {
    CleverTapLogInternal(self.config.logLevel, @"%@: processing response with headers:%@", self, headers);
    BOOL shouldRedirect = NO;
    @try {
        NSString *redirectDomain = headers[kREDIRECT_HEADER];
        if (redirectDomain != nil) {
            NSString *currentDomain = self.redirectDomain;
            self.redirectDomain = redirectDomain;
            if (![self.redirectDomain isEqualToString:currentDomain]) {
                shouldRedirect = YES;
                self.redirectDomain = redirectDomain;
                [self persistRedirectDomain];
            }
        }
        NSString *mutedString = headers[kMUTE_HEADER];
        BOOL muted = (mutedString == nil ? NO : [mutedString boolValue]);
        if (muted) {
            [self persistMutedTs];
            [self clearQueues];
        }
    } @catch(NSException *e) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Error processing response headers: %@", self, e.debugDescription);
    }
    return shouldRedirect;
}

- (void)handleHandshakeSuccess {
    CleverTapLogInternal(self.config.logLevel, @"%@: handshake success", self);
    [self resetFailsCounter];
}

- (void)resetFailsCounter {
    self.sendQueueFails = 0;
}

- (void)handleSendQueueSuccess {
    [self setLastRequestTimestamp:currentRequestTimestamp];
    [self setFirstRequestTimestampIfNeeded:currentRequestTimestamp];
    [self resetFailsCounter];
}

- (void)handleSendQueueFail {
    self.sendQueueFails += 1;
    if (self.sendQueueFails > 5) {
        [self clearRedirectDomain];
        self.sendQueueFails = 0;
    }
}
#pragma mark Queue/Dispatch helpers

- (NSMutableURLRequest *)createURLRequestFromURL:(NSURL *)url {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    NSString *accountId = self.config.accountId;
    NSString *accountToken = self.config.accountToken;
    if (accountId) {
        [request setValue:accountId forHTTPHeaderField:kACCOUNT_ID_HEADER];
    }
    if (accountToken) {
        [request setValue:accountToken forHTTPHeaderField:kACCOUNT_TOKEN_HEADER];
    }
    return request;
}

- (NSString *)endpointForQueue: (NSMutableArray *)queue {
    if (!self.redirectDomain) return nil;
    NSString *accountId = self.config.accountId;
    NSString *sdkRevision = self.deviceInfo.sdkVersion;
    NSString *endpointDomain;
    if (queue == _notificationsQueue) {
        endpointDomain = self.redirectNotifViewedDomain;
    } else {
        endpointDomain = self.redirectDomain;
    }
    NSString *endpointUrl = [[NSString alloc] initWithFormat:@"https://%@/a1?os=iOS&t=%@&z=%@", endpointDomain, sdkRevision, accountId];
    currentRequestTimestamp = (int) [[[NSDate alloc] init] timeIntervalSince1970];
    endpointUrl = [endpointUrl stringByAppendingFormat:@"&ts=%d", currentRequestTimestamp];
    return endpointUrl;
}

- (NSDictionary *)batchHeader {
    NSDictionary *appFields = [self generateAppFields];
    NSMutableDictionary *header = [@{@"type" : @"meta", @"af" : appFields} mutableCopy];
    
    header[@"g"] = self.deviceInfo.deviceId;
    header[@"tk"] = self.config.accountToken;
    header[@"id"] = self.config.accountId;
    
    header[@"ddnd"] = @([self getStoredDeviceToken].length <= 0);
    
    int lastTS = [self getLastRequestTimeStamp];
    header[@"l_ts"] = @(lastTS);
    
    int firstTS = [self getFirstRequestTimestamp];
    header[@"f_ts"] = @(firstTS);
    
    NSArray *registeredURLSchemes = _plistInfo.registeredUrlSchemes;
    if (registeredURLSchemes && [registeredURLSchemes count] > 0) {
        header[@"regURLs"] = registeredURLSchemes;
    }
    
    @try {
        NSDictionary *arp = [self getARP];
        if (arp && [arp count] > 0) {
            header[@"arp"] = arp;
        }
    } @catch (NSException *ex) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Failed to attach ARP to batch header", self);
    }
    
    @try {
        NSMutableDictionary *ref = [NSMutableDictionary new];
        if (self.source != nil) {
            ref[@"us"] = self.source;
        }
        if (self.medium != nil) {
            ref[@"um"] = self.medium;
        }
        if (self.campaign != nil) {
            ref[@"uc"] = self.campaign;
        }
        if ([ref count] > 0) {
            header[@"ref"] = ref;
        }
        
    } @catch (NSException *ex) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Failed to attach ref to batch header", self);
    }
    
    @try {
        if (self.wzrkParams != nil && [self.wzrkParams count] > 0) {
            header[@"wzrk_ref"] = self.wzrkParams;
        }
        
    } @catch (NSException *ex) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Failed to attach wzrk_ref to batch header", self);
    }
#if !CLEVERTAP_NO_INAPP_SUPPORT
    if (!_config.analyticsOnly && ![[self class] runningInsideAppExtension]) {
        [self.inAppFCManager attachToHeader:header];
    }
#endif
    return header;
}

- (NSArray *)insertHeader:(NSDictionary *)header inBatch:(NSArray *)batch {
    if (batch == nil || header == nil) {
        return batch;
    }
    NSMutableArray *newBatch = [NSMutableArray arrayWithArray:batch];
    [newBatch insertObject:header atIndex:0];
    return newBatch;
}

- (NSDictionary *)generateAppFields {
    NSMutableDictionary *evtData = [NSMutableDictionary new];
    
    evtData[@"Version"] = self.deviceInfo.appVersion;
    
    evtData[@"Build"] = self.deviceInfo.appBuild;
    
    evtData[@"SDK Version"] = self.deviceInfo.sdkVersion;
    
    if (self.deviceInfo.model) {
        evtData[@"Model"] = self.deviceInfo.model;
    }
    
    if (CLLocationCoordinate2DIsValid(self.userSetLocation)) {
        evtData[@"Latitude"] = @(self.userSetLocation.latitude);
        evtData[@"Longitude"] = @(self.userSetLocation.longitude);
    }
    
    evtData[@"Make"] = self.deviceInfo.manufacturer;
    evtData[@"OS Version"] = self.deviceInfo.osVersion;
    
    if (self.deviceInfo.carrier) {
        evtData[@"Carrier"] = self.deviceInfo.carrier;
    }
    
    evtData[@"useIP"] = @(self.enableNetworkInfoReporting);
    if (self.enableNetworkInfoReporting) {
        if (self.deviceInfo.radio != nil) {
            evtData[@"Radio"] = self.deviceInfo.radio;
        }
        evtData[@"wifi"] = @(self.deviceInfo.wifi);
    }
    
    if (self.deviceInfo.advertisingIdentitier) {
        evtData[@"ifaA"] = @YES;
        evtData[@"ifaL"] = self.deviceInfo.advertisingTrackingEnabled ? @NO : @YES;
        NSString *ifaString = [self deviceIsMultiUser] ?  [NSString stringWithFormat:@"%@%@", kMultiUserPrefix, @"ifa"] : @"ifa";
        evtData[ifaString] = self.deviceInfo.advertisingIdentitier;
    } else {
        evtData[@"ifaA"] = @NO;
    }
    
    if (self.deviceInfo.vendorIdentifier) {
        NSString *ifvString = [self deviceIsMultiUser] ?  [NSString stringWithFormat:@"%@%@", kMultiUserPrefix, @"ifv"] : @"ifv";
        evtData[ifvString] = self.deviceInfo.vendorIdentifier;
    }
    
    if ([[self class] runningInsideAppExtension]) {
        evtData[@"appex"] = @1;
    }
    
    evtData[@"OS"] = self.deviceInfo.osName;
    evtData[@"wdt"] = self.deviceInfo.deviceWidth;
    evtData[@"hgt"] = self.deviceInfo.deviceHeight;
    NSString *cc = self.deviceInfo.countryCode;
    if (cc != nil && ![cc isEqualToString:@""]) {
        evtData[@"cc"] = cc;
    }

    if (self.deviceInfo.library) {
        evtData[@"lib"] = self.deviceInfo.library;
    }
    return evtData;
}

- (NSString *)jsonObjectToString:(id)object {
    if ([object isKindOfClass:[NSString class]]) {
        return object;
    }
    @try {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                           options:0
                                                             error:&error];
        if (error) {
            return @"";
        }
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return jsonString;
    }
    @catch (NSException *exception) {
        return @"";
    }
}

- (id)convertDataToPrimitive:(id)event {
    @try {
        if ([event isKindOfClass:[NSArray class]]) {
            NSMutableArray *eventData = [[NSMutableArray alloc] init];
            for (id value in event) {
                id obj = value;
                obj = [self convertDataToPrimitive:obj];
                if (obj != nil) {
                    [eventData addObject:obj];
                }
            }
            return eventData;
        } else if ([event isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *eventData = [[NSMutableDictionary alloc] init];
            for (id key in [event allKeys]) {
                id obj = [event objectForKey:key];
                if ([key isKindOfClass:[NSString class]]
                    && ([(NSString *) key isEqualToString:@"FBID"] || [(NSString *) key isEqualToString:@"GPID"])) {
                    if (obj != nil) {
                        eventData[key] = obj;
                    }
                } else {
                    obj = [self convertDataToPrimitive:obj];
                    if (obj != nil) {
                        eventData[key] = obj;
                    }
                }
            }
            return eventData;
        } else if ([event isKindOfClass:[NSString class]]) {
            // Try to convert it to a double first
            double forcedDoubleValue = [(NSString *) event doubleValue];
            if ([[@(forcedDoubleValue) stringValue] isEqualToString:(NSString *) event]) {
                return @(forcedDoubleValue);
            } else {
                int forcedIntValue = [(NSString *) event intValue];
                if ([[@(forcedIntValue) stringValue] isEqualToString:(NSString *) event]) {
                    return @(forcedIntValue);
                }
            }
            return event;
        } else if ([event isKindOfClass:[NSNumber class]]) {
            return event;
        } else {
            // Couldn't understand what it was
            return nil;
        }
    } @catch (NSException *exception) {
        // Ignore
    }
    return nil;
}

#pragma mark timestamp bookkeeping helpers

-(void)setLastRequestTimestamp:(double)ts {
    [CTPreferences putInt:ts forKey:kLAST_TS_KEY];
}

- (NSTimeInterval)getLastRequestTimeStamp {
    if (self.config.isDefaultInstance) {
        return [CTPreferences getIntForKey:[self storageKeyWithSuffix:kLAST_TS_KEY] withResetValue:[CTPreferences getIntForKey:kLAST_TS_KEY withResetValue:0]];
    } else {
        return [CTPreferences getIntForKey:[self storageKeyWithSuffix:kLAST_TS_KEY] withResetValue:0];
    }
}

-(void)clearLastRequestTimestamp {
    [CTPreferences putInt:0 forKey:[self storageKeyWithSuffix:kLAST_TS_KEY]];
}

-(void)setFirstRequestTimestampIfNeeded:(double)ts {
    NSTimeInterval firstRequestTS = [self getFirstRequestTimestamp];
    if (firstRequestTS > 0) return;
    [CTPreferences putInt:ts forKey:[self storageKeyWithSuffix:kFIRST_TS_KEY]];
}

- (NSTimeInterval)getFirstRequestTimestamp {
    if (self.config.isDefaultInstance) {
        return [CTPreferences getIntForKey:[self storageKeyWithSuffix:kFIRST_TS_KEY] withResetValue:[CTPreferences getIntForKey:kFIRST_TS_KEY withResetValue:0]];
    } else {
        return [CTPreferences getIntForKey:[self storageKeyWithSuffix:kFIRST_TS_KEY] withResetValue:0];
    }
}

-(void)clearFirstRequestTimestamp {
    [CTPreferences putInt:0 forKey:[self storageKeyWithSuffix:kFIRST_TS_KEY]];
}

-(BOOL)isMuted {
    return [NSDate new].timeIntervalSince1970 - _lastMutedTs < 24 * 60 * 60;
}

#pragma mark Lifecycle handling

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self _appEnteredForeground];
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    if ([self isMuted]) return;
    [self flushQueue];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    CleverTapLogInternal(self.config.logLevel, @"%@: applicationDidEnterBackground", self);
    [self _appEnteredBackground];
}

- (void)applicationWillEnterForeground:(NSNotificationCenter *)notification {
    if ([self needHandshake]) {
        [self doHandshakeAsync];
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    if ([self isMuted]) return;
    [self persistQueues];
}

- (void)_appEnteredForegroundWithLaunchingOptions:(NSDictionary *)launchOptions {
    CleverTapLogInternal(self.config.logLevel, @"%@: appEnteredForeground with options: %@", self, launchOptions);
    if ([[self class] runningInsideAppExtension]) return;
    [self _appEnteredForeground];
    
#if !defined(CLEVERTAP_TVOS)
    // check for a launching push and handle
    if (isAutoIntegrated) {
        if (@available(iOS 10.0, *)) {
            Class ncdCls = [[UNUserNotificationCenter currentNotificationCenter].delegate class];
            if ([UNUserNotificationCenter class] && ncdCls) {
                CleverTapLogDebug(self.config.logLevel, @"%@: CleverTap autoIntegration enabled in iOS10+ with a UNUserNotificationCenterDelegate, not manually checking for push notification at launch", self);
                return;
            }
        }
    }
    if (launchOptions && launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        NSDictionary *notification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
        CleverTapLogDebug(self.config.logLevel, @"%@: found push notification at launch: %@", self, notification);
        [self _handlePushNotification:notification];
    }
#endif
}

- (void)_appEnteredForeground {
    if ([[self class] runningInsideAppExtension]) return;
    [self updateSessionStateOnLaunch];
    if (!self.isAppForeground) {
        [self recordAppLaunched:@"appEnteredForeground"];
        [self scheduleQueueFlush];
        CleverTapLogInternal(self.config.logLevel, @"%@: app is in foreground", self);
    }
    self.isAppForeground = YES;
    
#if !CLEVERTAP_NO_INAPP_SUPPORT
    if (!_config.analyticsOnly && ![[self class] runningInsideAppExtension]) {
        [self.inAppFCManager checkUpdateDailyLimits];
    }
#endif
}

- (void)_appEnteredBackground {
    self.isAppForeground = NO;
    if (![self isMuted]) {
        [self persistQueues];
    }
    [self runSerialAsync:^{
        [self updateSessionTime:(long) [[NSDate date] timeIntervalSince1970]];
    }];
}

- (void)recordAppLaunched:(NSString *)caller {
    if ([[self class] runningInsideAppExtension]) return;
    
    if (self.appLaunchProcessed) {
        CleverTapLogInternal(self.config.logLevel, @"%@: App Launched already processed", self);
        return;
    }
    
    self.appLaunchProcessed = YES;
    
    if (self.config.disableAppLaunchedEvent) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Dropping App Launched event - reporting disabled in instance configuration", self);
        return;
    }
    
    CleverTapLogInternal(self.config.logLevel, @"%@: recording App Launched event from: %@", self, caller);
    
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    event[@"evtName"] = CLTAP_APP_LAUNCHED_EVENT;
    event[@"evtData"] = [self generateAppFields];
    
    if (self.lastUTMFields) {
        [event addEntriesFromDictionary:self.lastUTMFields];
    }
    [self queueEvent:event withType:CleverTapEventTypeRaised];
}

- (void)recordPageEventWithExtras:(NSDictionary *)extras {
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    @try {
        // Add the extras
        if (extras != nil && ((int) [extras count]) > 0) {
            for (NSString *key in [extras allKeys]) {
                @try {
                    jsonObject[key] = extras[key];
                } @catch (NSException *ignore) {
                    // no-op
                }
            }
        }
        [self queueEvent:jsonObject withType:CleverTapEventTypePage];
    } @catch (NSException *e) {
        //no-op
        CleverTapLogInternal(self.config.logLevel, @"%@: error recording page event: %@", self, e.debugDescription);
    }
}

- (void)pushInitialEventsIfNeeded {
    if (!self.initialEventsPushed) {
        self.initialEventsPushed = YES;
        [self pushInitialEvents];
    }
}

- (void)pushInitialEvents {
     if ([[self class] runningInsideAppExtension]) return;
     NSDate *d = [NSDate date];
     NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
     [dateFormatter setDateFormat:@"d"];
     
     if ([CTPreferences getIntForKey:[self storageKeyWithSuffix:CLTAP_PREFS_LAST_DAILY_PUSHED_EVENTS_DATE] withResetValue:0] != [[dateFormatter stringFromDate:d] intValue]) {
         CleverTapLogInternal(self.config.logLevel, @"%@: queuing daily events", self);
         [self _pushBaseProfile];
         if (!self.pushedAPNSId) {
             [self pushDeviceTokenWithAction:CleverTapPushTokenRegister];
         } else {
             CleverTapLogInternal(self.config.logLevel, @"%@: Skipped push of the APNS ID, already sent.", self);
         }
     }
     [CTPreferences putInt:[[dateFormatter stringFromDate:d] intValue] forKey:[self storageKeyWithSuffix:CLTAP_PREFS_LAST_DAILY_PUSHED_EVENTS_DATE]];
 }

#pragma mark Notifications Private

- (void)pushDeviceTokenWithAction:(CleverTapPushTokenRegistrationAction)action {
    if ([[self class] runningInsideAppExtension]) return;
    NSString *token = [self getStoredDeviceToken];
    if (token != nil && ![token isEqualToString:@""])
    [self pushDeviceToken:token forRegisterAction:action];
}

- (void)pushDeviceToken:(NSString *)deviceToken forRegisterAction:(CleverTapPushTokenRegistrationAction)action {
    if ([[self class] runningInsideAppExtension]) return;
    if (deviceToken == nil) return;
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *pushDetails = [[NSMutableDictionary alloc] init];
    pushDetails[@"action"] = (action == CleverTapPushTokenRegister ? @"register" : @"unregister");
    pushDetails[@"id"] = deviceToken;
    pushDetails[@"type"] = @"apns";
    event[@"data"] = pushDetails;
    [self queueEvent:event withType:CleverTapEventTypeData];
    self.pushedAPNSId = (action == CleverTapPushTokenRegister);
}

- (void)storeDeviceToken:(NSString *)deviceToken {
    CleverTapLogInternal(self.config.logLevel, @"%@: Saving APNS token for app version %@", self, self.deviceInfo.appVersion);
    [CTPreferences putString:deviceToken forKey:CLTAP_APNS_PROPERTY_DEVICE_TOKEN];
}

- (NSString *)getStoredDeviceToken {
    NSString *deviceToken = [CTPreferences getStringForKey:CLTAP_APNS_PROPERTY_DEVICE_TOKEN withResetValue:@""];
    if (!deviceToken || [deviceToken isEqualToString:@""]) {
        CleverTapLogInternal(self.config.logLevel, @"%@: APNS Push Token not found", self);
        return @"";
    }
    return deviceToken;
}
- (void)_handlePushNotification:(id)object {
    [self _handlePushNotification:object openDeepLinksInForeground:NO];
}

- (void)_handlePushNotification:(id)object openDeepLinksInForeground:(BOOL)openInForeground {
    if ([[self class] runningInsideAppExtension]) return;
    
    if (!object) return;
    
#if !defined(CLEVERTAP_TVOS)
    // normalize the notification data
    NSDictionary *notification;
    if ([object isKindOfClass:[UILocalNotification class]]) {
        notification = [((UILocalNotification *) object) userInfo];
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        notification = object;
    }
    
    if (!notification || [notification count] <= 0) return;
    
    // make sure its our notification before processing
    
    BOOL shouldHandlePush = [self _isCTPushNotification:notification];
    if (!shouldHandlePush) {
        CleverTapLogDebug(self.config.logLevel, @"%@: push notification not from CleverTap, not processing: %@", self, notification);
        return;
    }
    shouldHandlePush = !self.config.analyticsOnly;
    if (!shouldHandlePush) {
        CleverTapLogInternal(self.config.logLevel, @"%@: instance is analyticsOnly, not processing push notification %@", self, notification);
        return;
    }
    
    // this is push generated for this instance of the SDK
    NSString *accountId = (NSString *) notification[@"wzrk_acct_id"];
    // if there is no accountId then only process if its the default instance
    shouldHandlePush = accountId ? [accountId isEqualToString:self.config.accountId]: self.config.isDefaultInstance;
    if (!shouldHandlePush) {
        CleverTapLogInternal(self.config.logLevel, @"%@: push notification not targeted as this instance, not processing %@", self, notification);
        return;
    }
    
    CleverTapLogDebug(self.config.logLevel, @"%@: handling push notification: %@", self, notification);
    
    // check to see whether the push includes a test in-app notification, if so don't process further
    if ([self didHandleInAppTestFromPushNotificaton:notification]) return;
    
    // check to see whether the push includes a test inbox message, if so don't process further
    if ([self didHandleInboxMessageTestFromPushNotificaton:notification]) return;
    
    // check to see whether the push includes a test display unit, if so don't process further
    if ([self didHandleDisplayUnitTestFromPushNotificaton:notification]) return;
        
    // determine application state
    UIApplication *application = [[self class] getSharedApplication];
    if (application != nil) {
        BOOL inForeground = !(application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground);
        
        // should we open a deep link ?
        // if the app is in foreground and force flag is off, then don't fire any deep link
        if (inForeground && !openInForeground) {
            CleverTapLogDebug(self.config.logLevel, @"%@: app in foreground and openInForeground flag is FALSE, will not process any deep link for notification: %@", self, notification);
        } else {
            [self _checkAndFireDeepLinkForNotification:notification];
        }
        [self runSerialAsync:^{
            [CTEventBuilder buildPushNotificationEvent:YES forNotification:notification completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
                if (event) {
                    self.wzrkParams = [event[@"evtData"] copy];
                    [self queueEvent:event withType:CleverTapEventTypeRaised];
                };
                if (errors) {
                    [self pushValidationResults:errors];
                }
            }];
        }];
    }
#endif
}

- (void)_checkAndFireDeepLinkForNotification:(NSDictionary *)notification {
    UIApplication *application = [[self class] getSharedApplication];
    if (application != nil) {
        @try {
            NSString *dl = (NSString *) notification[@"wzrk_dl"];
            if (dl) {
                __block NSURL *dlURL = [NSURL URLWithString:dl];
                if (dlURL) {
                    [[self class] runSyncMainQueue:^{
                        CleverTapLogDebug(self.config.logLevel, @"%@: Firing deep link: %@", self, dl);
                        if (@available(iOS 10.0, *)) {
                            if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
                                NSMethodSignature *signature = [UIApplication
                                                                instanceMethodSignatureForSelector:@selector(openURL:options:completionHandler:)];
                                NSInvocation *invocation = [NSInvocation
                                                            invocationWithMethodSignature:signature];
                                [invocation setTarget:application];
                                [invocation setSelector:@selector(openURL:options:completionHandler:)];
                                NSDictionary *options = @{};
                                id completionHandler = nil;
                                [invocation setArgument:&dlURL atIndex:2];
                                [invocation setArgument:&options atIndex:3];
                                [invocation setArgument:&completionHandler atIndex:4];
                                [invocation invoke];
                            } else {
                                if ([application respondsToSelector:@selector(openURL:)]) {
                                    [application performSelector:@selector(openURL:) withObject:dlURL];
                                }
                            }
                        } else {
                            if ([application respondsToSelector:@selector(openURL:)]) {
                                [application performSelector:@selector(openURL:) withObject:dlURL];
                            }
                        }
                    }];
                }
            }
        }
        @catch (NSException *exception) {
            CleverTapLogDebug(self.config.logLevel, @"%@: Unable to fire deep link: %@", self, [exception reason]);
        }
    }
}

- (void)_pushDeepLink:(NSString *)uri withSourceApp:(NSString *)sourceApp andInstall:(BOOL)install {
    if (uri == nil)
        return;
    if (!sourceApp) sourceApp = uri;
    NSDictionary *referrer = [CTUriHelper getUrchinFromUri:uri withSourceApp:sourceApp];
    if ([referrer count] == 0) {
        return;
    }
    [self setSource:referrer[@"us"]];
    [self setMedium:referrer[@"um"]];
    [self setCampaign:referrer[@"uc"]];
    [referrer setValue:@(install) forKey:@"install"];
    self.lastUTMFields = [[NSMutableDictionary alloc] initWithDictionary:referrer];
    [self recordPageEventWithExtras:self.lastUTMFields];
}

- (void)_pushDeepLink:(NSString *)uri withSourceApp:(NSString *)sourceApp {
    [self _pushDeepLink:uri withSourceApp:sourceApp andInstall:false];
}

- (BOOL)_isCTPushNotification:(NSDictionary *)notification {
    BOOL isOurs = NO;
    @try {
        for (NSString *key in [notification allKeys]) {
            if (([CTUtils doesString:key startWith:CLTAP_NOTIFICATION_TAG] || [CTUtils doesString:key startWith:CLTAP_NOTIFICATION_TAG_SECONDARY])) {
                isOurs = YES;
                break;
            }
        }
    } @catch (NSException *e) {
        // no-op
    }
    
    return isOurs;
}

#pragma mark InApp Notifications private

- (BOOL)didHandleInAppTestFromPushNotificaton:(NSDictionary*)notification {
#if !CLEVERTAP_NO_INAPP_SUPPORT
    if ([[self class] runningInsideAppExtension]) {
        return NO;
    }
    
    if (!notification || [notification count] <= 0 || !notification[@"wzrk_inapp"]) return NO;
    
    @try {
        [self.inAppFCManager resetSession];
        CleverTapLogDebug(self.config.logLevel, @"%@: Received in-app notification from push payload: %@", self, notification);
        
        NSString *jsonString = notification[@"wzrk_inapp"];
        
        NSDictionary *inapp = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                              options:0
                                                                error:nil];
        
        if (inapp) {
            float delay = self.isAppForeground ? 0.5 : 2.0;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @try {
                    [self prepareNotificationForDisplay:inapp];
                } @catch (NSException *e) {
                    CleverTapLogDebug(self.config.logLevel, @"%@: Failed to display the inapp notifcation from payload: %@", self, e.debugDescription);
                }
            });
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Failed to parse the inapp notification as JSON", self);
            return YES;
        }
        
    } @catch (NSException *e) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Failed to display the inapp notifcation from payload: %@", self, e.debugDescription);
        return YES;
    }
    
#endif
    return YES;
}

// static display handling as we may have more than one instance competing to show an inapp
+ (void)checkPendingNotifications {
    if (pendingNotificationControllers && [pendingNotificationControllers count] > 0) {
        CTInAppDisplayViewController *controller = [pendingNotificationControllers objectAtIndex:0];
        [pendingNotificationControllers removeObjectAtIndex:0];
        [self displayInAppDisplayController:controller];
    }
}

+ (void)displayInAppDisplayController:(CTInAppDisplayViewController*)controller {
    // if we are currently displaying a notification, cache this notification for later display
    if (currentDisplayController) {
        [pendingNotificationControllers addObject:controller];
        return;
    }
    // no current notification so display
    currentDisplayController = controller;
    [controller show:YES];
}

+ (void)inAppDisplayControllerDidDismiss:(CTInAppDisplayViewController*)controller {
    if (currentDisplayController && currentDisplayController == controller) {
        currentDisplayController = nil;
        [self checkPendingNotifications];
    }
}

- (void)runOnNotificationQueue:(void (^)(void))taskBlock {
    if ([self inNotificationQueue]) {
        taskBlock();
    } else {
        dispatch_async(_notificationQueue, taskBlock);
    }
}

- (BOOL)inNotificationQueue {
    CleverTap *currentQueue = (__bridge id) dispatch_get_specific(kNotificationQueueKey);
    return currentQueue == self;
}

- (void)_showNotificationIfAvailable {
    if ([[self class] runningInsideAppExtension]) return;
    
    @try {
        NSMutableArray *inapps = [[NSMutableArray alloc] initWithArray:[CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY]]];
        if ([inapps count] < 1) {
            return;
        }
        [self prepareNotificationForDisplay:inapps[0]];
        [inapps removeObjectAtIndex:0];
        [CTPreferences putObject:inapps forKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY]];
    } @catch (NSException *e) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Problem showing InApp: %@", self, e.debugDescription);
    }
}

- (void)prepareNotificationForDisplay:(NSDictionary*)jsonObj {
    if (!self.isAppForeground) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Application is not in the foreground, won't prepare in-app: %@", self, jsonObj);
        return;
    }
    
    [self runOnNotificationQueue:^{
        CleverTapLogInternal(self.config.logLevel, @"%@: processing inapp notification: %@", self, jsonObj);
        __block CTInAppNotification *notification = [[CTInAppNotification alloc] initWithJSON:jsonObj];
        if (notification.error) {
            CleverTapLogInternal(self.config.logLevel, @"%@: unable to parse inapp notification: %@ error: %@", self, jsonObj, notification.error);
            return;
        }
        [notification prepareWithCompletionHandler:^{
            [[self class] runSyncMainQueue:^{
                [self notificationReady:notification];
            }];
        }];
    }];
}

- (void)notificationReady:(CTInAppNotification*)notification {
    if (![NSThread isMainThread]) {
        [[self class] runSyncMainQueue:^{
            [self notificationReady: notification];
        }];
        return;
    }
    if (notification.error) {
        CleverTapLogInternal(self.config.logLevel, @"%@: unable to process inapp notification: %@, error: %@ ", self, notification.jsonDescription, notification.error);
        return;
    }
    
    CleverTapLogInternal(self.config.logLevel, @"%@: InApp prepared for display: %@", self, notification.campaignId);
    [self displayNotification:notification];
}

- (void)displayNotification:(CTInAppNotification*)notification {
#if !CLEVERTAP_NO_INAPP_SUPPORT
    if (![NSThread isMainThread]) {
        [[self class] runSyncMainQueue:^{
            [self displayNotification:notification];
        }];
        return;
    }
    
    if (!self.isAppForeground) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Application is not in the foreground, not displaying in-app: %@", self, notification.jsonDescription);
        return;
    }
    
    if (![self.inAppFCManager canShow:notification]) {
        CleverTapLogInternal(self.config.logLevel, @"%@: InApp %@ has been rejected by FC, not showing", self, notification.campaignId);
        [self showInAppNotificationIfAny];  // auto try the next one
        return;
    }
    
    BOOL goFromDelegate = YES;
    if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(shouldShowInAppNotificationWithExtras:)]) {
        goFromDelegate = [self.inAppNotificationDelegate shouldShowInAppNotificationWithExtras:notification.customExtras];
    }
    
    if (!goFromDelegate) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Application has decided to not show this InApp: %@", self, notification.campaignId ? notification.campaignId : @"<unknown ID>");
        [self showInAppNotificationIfAny];  // auto try the next one
        return;
    }
    
    CTInAppDisplayViewController *controller;
    NSString *errorString = nil;
    CleverTapJSInterface *jsInterface = nil;
    
    switch (notification.inAppType) {
        case CTInAppTypeHTML:
            jsInterface = [[CleverTapJSInterface alloc] initWithConfig:self.config];
            controller = [[CTInAppHTMLViewController alloc] initWithNotification:notification jsInterface:jsInterface];
            break;
        case CTInAppTypeInterstitial:
            controller = [[CTInterstitialViewController alloc] initWithNotification:notification];
            break;
        case CTInAppTypeHalfInterstitial:
            controller = [[CTHalfInterstitialViewController alloc] initWithNotification:notification];
            break;
        case CTInAppTypeCover:
            controller = [[CTCoverViewController alloc] initWithNotification:notification];
            break;
        case CTInAppTypeHeader:
            controller = [[CTHeaderViewController alloc] initWithNotification:notification];
            break;
        case CTInAppTypeFooter:
            controller = [[CTFooterViewController alloc] initWithNotification:notification];
            break;
        case CTInAppTypeAlert:
            controller = [[CTAlertViewController alloc] initWithNotification:notification];
            break;
        case CTInAppTypeInterstitialImage:
            controller = [[CTInterstitialImageViewController alloc] initWithNotification:notification];
            break;
        case CTInAppTypeHalfInterstitialImage:
            controller = [[CTHalfInterstitialImageViewController alloc] initWithNotification:notification];
            break;
        case CTInAppTypeCoverImage:
            controller = [[CTCoverImageViewController alloc] initWithNotification:notification];
            break;
        default:
            errorString = [NSString stringWithFormat:@"Unhandled notification type: %lu", (unsigned long)notification.inAppType];
            break;
    }
    if (controller) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Will show new InApp: %@", self, notification.campaignId);
        controller.delegate = self;
        [[self class] displayInAppDisplayController:controller];
    }
    if (errorString) {
        CleverTapLogDebug(self.config.logLevel, @"%@: %@", self, errorString);
    }
#endif
}

- (void)clearInApps {
    CleverTapLogInternal(self.config.logLevel, @"%@: Clearing all pending InApp notifications", self);
    [CTPreferences putObject:[[NSArray alloc] init] forKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY]];
}

- (void)notifyNotificationDismissed:(CTInAppNotification *)notification {
    if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationDismissedWithExtras:andActionExtras:)]) {
        NSDictionary *extras;
        if (notification.actionExtras && [notification.actionExtras isKindOfClass:[NSDictionary class]]) {
            extras = [NSDictionary dictionaryWithDictionary:notification.actionExtras];
        } else {
            extras = [NSDictionary new];
        }
        [self.inAppNotificationDelegate inAppNotificationDismissedWithExtras:notification.customExtras andActionExtras:extras];
    }
}

- (void)recordInAppNotificationStateEvent:(BOOL)clicked
                               forNotification:(CTInAppNotification *)notification andQueryParameters:(NSDictionary *)params {
    
    [self runSerialAsync:^{
        [CTEventBuilder buildInAppNotificationStateEvent:clicked forNotification:notification andQueryParameters:params completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
            if (event) {
                if (clicked) {
                    self.wzrkParams = [event[@"evtData"] copy];
                }
                [self queueEvent:event withType:CleverTapEventTypeRaised];
            };
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
}

#pragma mark CTInAppNotificationDisplayDelegate

-(void)notificationDidDismiss:(CTInAppNotification*)notification fromViewController:(CTInAppDisplayViewController*)controller  {
    CleverTapLogInternal(self.config.logLevel, @"%@: InApp did dismiss: %@", self, notification.campaignId);
    [self notifyNotificationDismissed:notification];
    [[self class] inAppDisplayControllerDidDismiss:controller];
    [self showInAppNotificationIfAny];
}

-(void)notificationDidShow:(CTInAppNotification*)notification fromViewController:(CTInAppDisplayViewController*)controller {
    CleverTapLogInternal(self.config.logLevel, @"%@: InApp did show: %@", self, notification.campaignId);
    [self recordInAppNotificationStateEvent:NO forNotification:notification andQueryParameters:nil];
    [self.inAppFCManager didShow:notification];
}

- (void)notifyNotificationButtonTappedWithCustomExtras:(NSDictionary *)customExtras {
    if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationButtonTappedWithCustomExtras:)]) {
        [self.inAppNotificationDelegate inAppNotificationButtonTappedWithCustomExtras:customExtras];
    }
}

- (void)handleNotificationCTA:(NSURL *)ctaURL buttonCustomExtras:(NSDictionary *)buttonCustomExtras forNotification:(CTInAppNotification*)notification fromViewController:(CTInAppDisplayViewController*)controller withExtras:(NSDictionary*)extras {
    CleverTapLogInternal(self.config.logLevel, @"%@: handle InApp cta: %@ button custom extras: %@ with options:%@", self, ctaURL.absoluteString, buttonCustomExtras, extras);
    [self recordInAppNotificationStateEvent:YES forNotification:notification andQueryParameters:extras];
    if (extras) {
        notification.actionExtras = extras;
    }
    if (buttonCustomExtras && buttonCustomExtras.count > 0) {
        CleverTapLogDebug(self.config.logLevel, @"%@: InApp: button tapped with custom extras: %@", self, buttonCustomExtras);
        [self notifyNotificationButtonTappedWithCustomExtras:buttonCustomExtras];
    } else if (ctaURL) {
#if !CLEVERTAP_NO_INAPP_SUPPORT
        [[self class] runSyncMainQueue:^{
            UIApplication *sharedApplication = [[self class] getSharedApplication];
            if (sharedApplication == nil) {
                return;
            }
            CleverTapLogDebug(self.config.logLevel, @"%@: InApp: firing deep link: %@", self, ctaURL);
#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_9_0
            if ([sharedApplication respondsToSelector:@selector(openURL:options:completionHandler:)]) {
                NSMethodSignature *signature = [UIApplication
                                                instanceMethodSignatureForSelector:@selector(openURL:options:completionHandler:)];
                NSInvocation *invocation = [NSInvocation
                                            invocationWithMethodSignature:signature];
                [invocation setTarget:sharedApplication];
                [invocation setSelector:@selector(openURL:options:completionHandler:)];
                NSDictionary *options = @{};
                id completionHandler = nil;
                [invocation setArgument:&ctaURL atIndex:2];
                [invocation setArgument:&options atIndex:3];
                [invocation setArgument:&completionHandler atIndex:4];
                [invocation invoke];
            } else {
                if ([sharedApplication respondsToSelector:@selector(openURL:)]) {
                    [sharedApplication performSelector:@selector(openURL:) withObject:ctaURL];
                }
            }
#else
            if ([sharedApplication respondsToSelector:@selector(openURL:)]) {
                [sharedApplication performSelector:@selector(openURL:) withObject:ctaURL];
            }
           
#endif
        }];
#endif
    }
    [controller hide:true];
}

#pragma mark Serial Queue Operations

- (void)runSerialAsync:(void (^)(void))taskBlock {
    if ([self inSerialQueue]) {
        taskBlock();
    } else {
        dispatch_async(_serialQueue, taskBlock);
    }
}

- (BOOL)inSerialQueue {
    CleverTap *currentQueue = (__bridge id) dispatch_get_specific(kQueueKey);
    return currentQueue == self;
}

# pragma mark event helpers

- (NSMutableDictionary *)getErrorObject:(CTValidationResult *)vr {
    NSMutableDictionary *error = [[NSMutableDictionary alloc] init];
    @try {
        error[@"c"] = @([vr errorCode]);
        error[@"d"] = [vr errorDesc];
    } @catch (NSException *e) {
        // Won't reach here
    }
    return error;
}

- (void)recordDeviceErrors {
    for (CTValidationResult *error in self.deviceInfo.validationErrors) {
        [self pushValidationResult:error];
    }
}

# pragma mark Additional Request Parameters(ARP) and I/J handling

/**
 * Process additional request parameters (if available) in the response.
 * These parameters are then sent back with the next request as HTTP GET parameters.
 *
 * only used in [self endpoint]
 */
- (void)processAdditionalRequestParameters:(NSDictionary *)response {
    if (!response) return;
    
    NSNumber *i = response[@"_i"];
    if (i != nil) {
        [self saveI:i];
    }
    
    NSNumber *j = response[@"_j"];
    if (j != nil) {
        [self saveJ:j];
    }
    
    NSDictionary *arp = response[@"arp"];
    if (!arp || [arp count] < 1) return;
    
    [self updateARP:arp];
}

- (NSString *)arpKey {
    NSString *accountId = self.config.accountId;
    if (accountId == nil) {
        return nil;
    }
    return [NSString stringWithFormat:@"arp:%@", accountId];
}

- (NSDictionary *)getARP {
    NSString *key = [self arpKey];
    if (!key) return nil;
    NSDictionary *arp = [CTPreferences getObjectForKey:key];
    CleverTapLogInternal(self.config.logLevel, @"%@: Getting ARP: %@ for key: %@", self, arp, key);
    return arp;
}

- (void)saveARP:(NSDictionary *)arp {
    NSString *key = [self arpKey];
    if (!key) return;
    CleverTapLogInternal(self.config.logLevel, @"%@: Saving ARP: %@ for key: %@", self, arp, key);
    [CTPreferences putObject:arp forKey:key];
}

- (void)clearARP {
    NSString *key = [self arpKey];
    if (!key) return;
    CleverTapLogInternal(self.config.logLevel, @"%@: Clearing ARP for key: %@", self, key);
    [CTPreferences removeObjectForKey:key];
}

- (void)updateARP:(NSDictionary *)arp {
    NSMutableDictionary *update;
    NSDictionary *staleARP = [self getARP];
    if (staleARP) {
        update = [staleARP mutableCopy];
    } else {
        update = [[NSMutableDictionary alloc] init];
    }
    [update addEntriesFromDictionary:arp];
    
    // Remove any keys that have the value -1
    NSArray *keys = [update allKeys];
    for (NSUInteger i = 0; i < [keys count]; i++) {
        id value = update[keys[i]];
        if ([value isKindOfClass:[NSNumber class]] && ((NSNumber *) value).intValue == -1) {
            [update removeObjectForKey:keys[i]];
            CleverTapLogInternal(self.config.logLevel, @"%@: Purged key %@ from future additional request parameters", self, keys[i]);
        }
    }
    [self saveARP:update];
}

- (long)getI {
    return [CTPreferences getIntForKey:[self storageKeyWithSuffix:kI_KEY] withResetValue:0];
}

- (void)saveI:(NSNumber *)i {
    [CTPreferences putInt:[i longValue] forKey:[self storageKeyWithSuffix:kI_KEY]];
}

- (void)clearI {
    [CTPreferences removeObjectForKey:[self storageKeyWithSuffix:kI_KEY]];
}

- (long)getJ {
    return [CTPreferences getIntForKey:[self storageKeyWithSuffix:kJ_KEY] withResetValue:0];
}

- (void)saveJ:(NSNumber *)j {
    [CTPreferences putInt:[j longValue] forKey:[self storageKeyWithSuffix:kJ_KEY]];
}

- (void)clearJ {
    [CTPreferences removeObjectForKey:[self storageKeyWithSuffix:kJ_KEY]];
}

- (void)clearUserContext {
    [self clearARP];
    [self clearI];
    [self clearJ];
    [self clearLastRequestTimestamp];
    [self clearFirstRequestTimestamp];
}

#pragma mark Session and Related Handling

- (void)createSessionIfNeeded {
    if ([[self class] runningInsideAppExtension] || [self inCurrentSession]) {
        return;
    }
    [self resetSession];
    [self createSession];
}

- (void)updateSessionStateOnLaunch {
    if (![self inCurrentSession]) {
        [self resetSession];
        [self createSession];
        return;
    }
    CleverTapLogInternal(self.config.logLevel, @"%@: have current session: %lu", self, self.sessionId);
    long now = (long) [[NSDate date] timeIntervalSince1970];
    if (![self isSessionTimedOut:now]) {
        [self updateSessionTime:now];
        return;
    }
    CleverTapLogInternal(self.config.logLevel, @"%@: Session timeout reached", self);
    [self resetSession];
    [self createSession];
}

- (BOOL)inCurrentSession {
    return self.sessionId > 0;
}

- (BOOL)isSessionTimedOut:(long)currentTS {
    long lastSessionTime = [self lastSessionTime];
    return (lastSessionTime > 0 && (currentTS - lastSessionTime > self.minSessionSeconds));
}

- (long)lastSessionTime {
    return (long)[CTPreferences getIntForKey:[self storageKeyWithSuffix:kLastSessionTime] withResetValue:0];
}

- (void)updateSessionTime:(long)ts {
    if (![self inCurrentSession]) return;
    CleverTapLogInternal(self.config.logLevel, @"%@: updating session time: %lu", self, ts);
    [CTPreferences putInt:ts forKey:[self storageKeyWithSuffix:kLastSessionTime]];
}

- (void)resetSession {
    if ([[self class] runningInsideAppExtension]) return;
    self.appLaunchProcessed = NO;
    long lastSessionID = 0;
    long lastSessionEnd = 0;
    if (self.config.isDefaultInstance) {
        lastSessionID = [CTPreferences getIntForKey:[self storageKeyWithSuffix:kSessionId] withResetValue:[CTPreferences getIntForKey:kSessionId withResetValue:0]];
        lastSessionEnd = [CTPreferences getIntForKey:[self storageKeyWithSuffix:kLastSessionTime] withResetValue:[CTPreferences getIntForKey:kLastSessionPing withResetValue:0]];
    } else {
        lastSessionID = [CTPreferences getIntForKey:[self storageKeyWithSuffix:kSessionId] withResetValue:0];
        lastSessionEnd = [CTPreferences getIntForKey:[self storageKeyWithSuffix:kLastSessionTime] withResetValue:0];
    }
    self.lastSessionLengthSeconds = (lastSessionID > 0 && lastSessionEnd > 0) ? (int)(lastSessionEnd - lastSessionID) : 0;
    self.sessionId = 0;
    [self updateSessionTime:0];
    [CTPreferences removeObjectForKey:kSessionId];
    [CTPreferences removeObjectForKey:[self storageKeyWithSuffix:kSessionId]];
    self.screenCount = 1;
    [self clearSource];
    [self clearMedium];
    [self clearCampaign];
    [self clearWzrkParams];
#if !CLEVERTAP_NO_INAPP_SUPPORT
    if (![[self class] runningInsideAppExtension]) {
        [self.inAppFCManager resetSession];
    }
#endif
}

- (void)setSessionId:(long)sessionId {
    _sessionId = sessionId;
    [CTPreferences putInt:self.sessionId forKey:[self storageKeyWithSuffix:kSessionId]];
}

- (long)sessionId {
    return _sessionId;
}

- (void)createSession {
    self.sessionId = (long) [[NSDate date] timeIntervalSince1970];
    [self updateSessionTime:self.sessionId];
    if (self.config.isDefaultInstance) {
        self.firstSession = [CTPreferences getIntForKey:[self storageKeyWithSuffix:@"firstTime"] withResetValue:[CTPreferences getIntForKey:@"firstTime" withResetValue:0]] == 0;
    } else {
        self.firstSession = [CTPreferences getIntForKey:[self storageKeyWithSuffix:@"firstTime"] withResetValue:0] == 0;
    }
    [CTPreferences putInt:1 forKey:[self storageKeyWithSuffix:@"firstTime"]];
    CleverTapLogInternal(self.config.logLevel, @"%@: session created with ID: %lu", self, self.sessionId);
    CleverTapLogInternal(self.config.logLevel, @"%@: previous session length: %d seconds", self, self.lastSessionLengthSeconds);
#if !CLEVERTAP_NO_INAPP_SUPPORT
    if (![[self class] runningInsideAppExtension]) {
        [self clearInApps];
    }
#endif
}

- (NSString*)source {
    return _source;
}
// only set if not already set for this session
- (void)setSource:(NSString *)source {
    if (_source == nil) {
        _source = source;
    }
}
- (void)clearSource {
    _source = nil;
}

- (NSString*)medium{
    return _medium;
}
// only set them if not already set during the session
- (void)setMedium:(NSString *)medium {
    if (_medium == nil) {
        _medium = medium;
    }
}
- (void)clearMedium {
    _medium = nil;
}

- (NSString*)campaign {
    return _campaign;
}
// only set them if not already set during the session
- (void)setCampaign:(NSString *)campaign {
    if (_campaign == nil) {
        _campaign = campaign;
    }
}
- (void)clearCampaign {
    _campaign = nil;
}

- (NSDictionary*)wzrkParams{
    return _wzrkParams;
}
// only set them if not already set during the session
- (void)setWzrkParams:(NSDictionary *)params {
    if (_wzrkParams == nil) {
        _wzrkParams = params;
    }
}
- (void)clearWzrkParams {
    _wzrkParams = nil;
}

#pragma mark - Queues/Persistence/Dispatch Handling

- (BOOL)shouldDeferProcessingEvent: (NSDictionary *)event withType:(CleverTapEventType)type {
    if (self.config.isCreatedPostAppLaunched){
        return NO;
    }
    return (type == CleverTapEventTypeRaised && !self.appLaunchProcessed);
}

- (void)queueEvent:(NSDictionary *)event withType:(CleverTapEventType)type {
    if (self.currentUserOptedOut) {
        CleverTapLogDebug(self.config.logLevel, @"%@: User: %@ has opted out of sending events, dropping event: %@", self, self.deviceInfo.deviceId, event);
        return;
    }
    if ([self isMuted]) {
        CleverTapLogDebug(self.config.logLevel, @"%@: is muted, dropping event: %@", self, event);
        return;
    }
    
    // make sure App Launched is processed first
    // if not defer this one; push back on the queue
    if ([self shouldDeferProcessingEvent:event withType:type]) {
        CleverTapLogDebug(self.config.logLevel, @"%@: App Launched not yet processed re-queueing: %@, %lu", self, event, (long)type);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self runSerialAsync:^{
                [self queueEvent:event withType:type];
            }];
        });
        return;
    }
    
    [self createSessionIfNeeded];
    [self pushInitialEventsIfNeeded];
    [self runSerialAsync:^{
        [self updateSessionTime:(long) [[NSDate date] timeIntervalSince1970]];
        [self processEvent:event withType:type];
    }];
}

- (void)processEvent:(NSDictionary *)event withType:(CleverTapEventType)eventType {
    @try {
        // just belt and suspenders
        if ([self isMuted]) {
            [self flushQueue];  //this will clear the queues when in a muted state
            return;
        }
        NSMutableDictionary *mutableEvent = [NSMutableDictionary dictionaryWithDictionary:event];
        
        if (!self.config.accountId || !self.config.accountToken) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Account ID/token not found, will not add to queue", self);
            return;
        }
        
        // ignore pings if queue is not draining
        if ([self.eventsQueue count] >= 50 && eventType == CleverTapEventTypePing) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Events queue not draining, ignoring ping event", self);
            return;
        }
        
        if (eventType != CleverTapEventTypeRaised || eventType != CleverTapEventTypeNotificationViewed) {
            event = [self convertDataToPrimitive:event];
        }
        
        NSString *type;
        if (eventType == CleverTapEventTypePage) {
            type = @"page";
        } else if (eventType == CleverTapEventTypePing) {
            type = @"ping";
        } else if (eventType == CleverTapEventTypeProfile){
            type = @"profile";
        } else if (eventType == CleverTapEventTypeData) {
            type = @"data";
        } else if (eventType == CleverTapEventTypeNotificationViewed) {
            type = @"event";
            NSString *bundleIdentifier = _deviceInfo.bundleId;
            if (bundleIdentifier) {
                mutableEvent[@"pai"] = bundleIdentifier;
            }
        } else {
            type = @"event";
            NSString *bundleIdentifier = _deviceInfo.bundleId;
            if (bundleIdentifier) {
                mutableEvent[@"pai"] = bundleIdentifier;
            }
        }
        mutableEvent[@"type"] = type;
        mutableEvent[@"ep"] = @((int) [[NSDate date] timeIntervalSince1970]);
        mutableEvent[@"s"] = @(self.sessionId);
        int screenCount = self.screenCount == 0 ? 1 : self.screenCount;
        mutableEvent[@"pg"] = @(screenCount);
        mutableEvent[@"lsl"] = @(self.lastSessionLengthSeconds);
        mutableEvent[@"f"] = @(self.firstSession);
        mutableEvent[@"n"] = self.currentViewControllerName ? self.currentViewControllerName : @"_bg";
        
        // Report any pending validation error
        CTValidationResult *vr = [self popValidationResult];
        if (vr != nil) {
            mutableEvent[CLTAP_ERROR_KEY] = [self getErrorObject:vr];
        }
        
        if (self.config.enablePersonalization) {
            [self.localDataStore addDataSyncFlag:mutableEvent];
        }
        
        if (eventType == CleverTapEventTypeRaised || eventType == CleverTapEventTypeNotificationViewed) {
            [self.localDataStore persistEvent:mutableEvent];
        }
        
        if (eventType == CleverTapEventTypeProfile) {
            [self.profileQueue addObject:mutableEvent];
            if ([self.profileQueue count] > 500) {
                [self.profileQueue removeObjectAtIndex:0];
            }
        } else if (eventType == CleverTapEventTypeNotificationViewed) {
            [self.notificationsQueue addObject:mutableEvent];
            if ([self.notificationsQueue count] > 100) {
                [self.notificationsQueue removeObjectAtIndex:0];
            }
        } else {
            [self.eventsQueue addObject:mutableEvent];
            if ([self.eventsQueue count] > 500) {
                [self.eventsQueue removeObjectAtIndex:0];
            }
        }
        
        CleverTapLogDebug(self.config.logLevel, @"%@: New event processed: %@", self, [self jsonObjectToString:mutableEvent]);
        
        [self scheduleQueueFlush];
        
    } @catch (NSException *e) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Processing event failed with a exception: %@", self, e.debugDescription);
    }
}
- (void)scheduleQueueFlush {
    CleverTapLogInternal(self.config.logLevel, @"%@: scheduling delayed queue flush", self);
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(flushQueue) object:nil];
        [self performSelector:@selector(flushQueue) withObject:nil afterDelay:CLTAP_PUSH_DELAY_SECONDS];
    });
}

- (void)flushQueue {
    if ([self needHandshake]) {
        [self runSerialAsync:^{
            [self doHandshakeAsync];
        }];
    }
    [self runSerialAsync:^{
        if ([self isMuted]) {
            [self clearQueues];
        } else {
            [self sendQueues];
        }
    }];
}

- (void)clearQueue {
    [self runSerialAsync:^{
        [self sendQueues];
        [self clearQueues];
    }];
}

- (void)sendQueues {
    if ([self isMuted] || _offline) return;
    [self sendQueue:_profileQueue];
    [self sendQueue:_eventsQueue];
    [self sendQueue:_notificationsQueue];
}

- (void)inflateQueuesAsync {
    [self runSerialAsync:^{
        [self inflateProfileQueue];
        [self inflateEventsQueue];
        [self inflateNotificationsQueue];
    }];
}

- (void)inflateEventsQueue {
    self.eventsQueue = (NSMutableArray *)[CTPreferences unarchiveFromFile:[self eventsFileName] removeFile:YES];
    if (!self.eventsQueue || [self isMuted]) {
        self.eventsQueue = [NSMutableArray array];
    }
}

- (void)inflateProfileQueue {
    self.profileQueue = (NSMutableArray *)[CTPreferences unarchiveFromFile:[self profileEventsFileName] removeFile:YES];
    if (!self.profileQueue || [self isMuted]) {
        self.profileQueue = [NSMutableArray array];
    }
}

- (void)inflateNotificationsQueue {
    self.notificationsQueue = (NSMutableArray *)[CTPreferences unarchiveFromFile:[self notificationsFileName] removeFile:YES];
    if (!self.notificationsQueue || [self isMuted]) {
        self.notificationsQueue = [NSMutableArray array];
    }
}

- (void)clearQueues {
    [self clearProfileQueue];
    [self clearEventsQueue];
    [self clearNotificationsQueue];
}

- (void)clearEventsQueue {
    self.eventsQueue = (NSMutableArray *)[CTPreferences unarchiveFromFile:[self eventsFileName] removeFile:YES];
    self.eventsQueue = [NSMutableArray array];
}

- (void)clearProfileQueue {
    self.profileQueue = (NSMutableArray *)[CTPreferences unarchiveFromFile:[self profileEventsFileName] removeFile:YES];
    self.profileQueue = [NSMutableArray array];
}

- (void)clearNotificationsQueue {
    self.notificationsQueue = (NSMutableArray *)[CTPreferences unarchiveFromFile:[self notificationsFileName] removeFile:YES];
    self.notificationsQueue = [NSMutableArray array];
}

- (void)persistQueues {
    [self runSerialAsync:^{
        if ([self isMuted]) {
            [self clearQueues];
        } else {
            [self persistProfileQueue];
            [self persistEventsQueue];
            [self persistNotificationsQueue];
        }
    }];
}
- (void)persistEventsQueue {
    NSString *fileName = [self eventsFileName];
    NSMutableArray *eventsCopy;
    @synchronized (self) {
        eventsCopy = [NSMutableArray arrayWithArray:[self.eventsQueue copy]];
    }
    [CTPreferences archiveObject:eventsCopy forFileName:fileName];
}

- (void)persistProfileQueue {
    NSString *fileName = [self profileEventsFileName];
    NSMutableArray *profileEventsCopy;
    @synchronized (self) {
        profileEventsCopy = [NSMutableArray arrayWithArray:[self.profileQueue copy]];
    }
    [CTPreferences archiveObject:profileEventsCopy forFileName:fileName];
}

- (void)persistNotificationsQueue {
    NSString *fileName = [self notificationsFileName];
    NSMutableArray *notificationsCopy;
    @synchronized (self) {
        notificationsCopy = [NSMutableArray arrayWithArray:[self.notificationsQueue copy]];
    }
    [CTPreferences archiveObject:notificationsCopy forFileName:fileName];
}

- (NSString *)fileNameForQueue:(NSString *)queueName {
    return [NSString stringWithFormat:@"clevertap-%@-%@.plist", self.config.accountId, queueName];
}

- (NSString *)eventsFileName {
    return [self fileNameForQueue:kQUEUE_NAME_EVENTS];
}

- (NSString *)profileEventsFileName {
    return [self fileNameForQueue:kQUEUE_NAME_PROFILE];
}

- (NSString *)notificationsFileName {
    return [self fileNameForQueue:kQUEUE_NAME_NOTIFICATIONS];
}

#pragma mark Validation Error Handling

- (void)pushValidationResults:(NSArray<CTValidationResult *> * _Nonnull )results {
    for (CTValidationResult *vr in results) {
        [self pushValidationResult:vr];
    }
}

- (void)pushValidationResult:(CTValidationResult *)vr {
    [self.pendingValidationResults addObject:vr];
    if (self.pendingValidationResults && [self.pendingValidationResults count] > 50) {
        [self.pendingValidationResults removeObjectAtIndex:0];
    }
}

- (CTValidationResult *)popValidationResult {
    CTValidationResult *vr = nil;
    if (self.pendingValidationResults && [self.pendingValidationResults count] > 0) {
        vr = self.pendingValidationResults[0];
        [self.pendingValidationResults removeObjectAtIndex:0];
    }
    return vr;
}

# pragma mark Request/Response handling

- (void)sendQueue:(NSMutableArray *)queue {
    if (queue == nil || ((int) [queue count]) <= 0) {
        CleverTapLogInternal(self.config.logLevel, @"%@: No events in the queue", self);
        return;
    }
    // just belt and suspenders here, should never get here in muted state
    if ([self isMuted]) {
        CleverTapLogInternal(self.config.logLevel, @"%@: is muted won't send queue", self);
        return;
    }
    
    NSString *endpoint = [self endpointForQueue:queue];
    
    if (endpoint == nil) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Endpoint is not set, will not start sending queue", self);
        return;
    }
    
    NSDictionary *header = [self batchHeader];
    
    int originalCount = (int) [queue count];
    float numBatches = (float) ceil((float) originalCount / kMaxBatchSize);
    CleverTapLogDebug(self.config.logLevel, @"%@: Pending events to be sent: %d in %d batches", self, originalCount, (int) numBatches);
    
    while ([queue count] > 0) {
        NSUInteger batchSize = ([queue count] > kMaxBatchSize) ? kMaxBatchSize : [queue count];
        NSArray *batch = [queue subarrayWithRange:NSMakeRange(0, batchSize)];
        NSArray *batchWithHeader = [self insertHeader:header inBatch:batch];
        
        CleverTapLogInternal(self.config.logLevel, @"%@: Pending events batch contains: %d items", self, (int) [batch count]);
        
        @try {
            NSString *jsonBody = [self jsonObjectToString:batchWithHeader];
            
            CleverTapLogDebug(self.config.logLevel, @"%@: Sending %@ to CleverTap servers at %@", self, jsonBody, endpoint);
            
            // update endpoint for current timestamp
            endpoint = [self endpointForQueue:queue];
            if (endpoint == nil) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Endpoint is not set, won't send queue", self);
                return;
            }
            
            NSMutableURLRequest *request = [self createURLRequestFromURL:[[NSURL alloc] initWithString:endpoint]];
            request.HTTPBody = [jsonBody dataUsingEncoding:NSUTF8StringEncoding];
            request.HTTPMethod = @"POST";
            
            __block BOOL success = NO;
            __block NSData *responseData;
            
            __block BOOL redirect = NO;
            
            // Need to simulate a synchronous request
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            NSURLSessionDataTask *postDataTask = [self.urlSession
                                                  dataTaskWithRequest:request
                                                  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                      responseData = data;
                                                      
                                                      if (error) {
                                                          CleverTapLogDebug(self.config.logLevel, @"%@: Network error while sending queue, will retry: %@", self, error.localizedDescription);
                                                      }
                                                      
                                                      if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                                          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                                          
                                                          success = (httpResponse.statusCode == 200);
                                                          
                                                          if (success) {
                                                              if (queue == self->_notificationsQueue) {
                                                                  redirect = [self updateStateFromResponseHeadersShouldRedirectForNotif: httpResponse.allHeaderFields];
                                                              } else {
                                                                  redirect = [self updateStateFromResponseHeadersShouldRedirect: httpResponse.allHeaderFields];
                                                              }
                                                              
                                                          } else {
                                                              CleverTapLogDebug(self.config.logLevel, @"%@: Got %lu response when sending queue, will retry", self, (long)httpResponse.statusCode);
                                                          }
                                                      }
                                                      
                                                      dispatch_semaphore_signal(semaphore);
                                                  }];
            [postDataTask resume];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            
            if (!success) {
                [self scheduleQueueFlush];
                [self handleSendQueueFail];
            }
            
            if (!success || redirect) {
                // error so return without removing events from the queue or parsing the response
                // Note: in an APP Extension we don't persist any unsent queues
                return;
            }
            
            [queue removeObjectsInArray:batch];
            
            [self parseResponse:responseData];
            
            CleverTapLogDebug(self.config.logLevel,@"%@: Successfully sent %lu events", self, (unsigned long)[batch count]);
            
        } @catch (NSException *e) {
            CleverTapLogDebug(self.config.logLevel, @"%@: An error occurred while sending the queue: %@", self, e.debugDescription);
            break;
        }
    }
}

#pragma mark - Response handling

- (void)parseResponse:(NSData *)responseData {
    if (responseData) {
        @try {
            id jsonResp = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
            CleverTapLogInternal(self.config.logLevel, @"%@: Response: %@", self, jsonResp);
            
            if (jsonResp && [jsonResp isKindOfClass:[NSDictionary class]]) {
                NSString *upstreamGUID = [jsonResp objectForKey:@"g"];
                
                if (upstreamGUID && ![upstreamGUID isEqualToString:@""]) {
                    [self.deviceInfo forceUpdateDeviceID:upstreamGUID];
                    CleverTapLogInternal(self.config.logLevel, @"%@: Upstream updated the GUID to %@", self, upstreamGUID);
                }
                
#if !CLEVERTAP_NO_INAPP_SUPPORT
                if (!self.config.analyticsOnly && ![[self class] runningInsideAppExtension]) {
                    NSNumber *perSession = jsonResp[@"imc"];
                    if (!perSession) {
                        perSession = @10;
                    }
                    NSNumber *perDay = jsonResp[@"imp"];
                    if (!perDay) {
                        perDay = @10;
                    }
                    [self.inAppFCManager updateLimitsPerDay:perDay.intValue andPerSession:perSession.intValue];
                    
                    NSArray *inappsJSON = jsonResp[CLTAP_INAPP_JSON_RESPONSE_KEY];
                    if (inappsJSON) {
                        NSMutableArray *inappNotifs;
                        @try {
                            inappNotifs = [[NSMutableArray alloc] initWithArray:inappsJSON];
                        } @catch (NSException *e) {
                            CleverTapLogInternal(self.config.logLevel, @"%@: Error parsing InApps JSON: %@", self, e.debugDescription);
                        }
                        
                        // Add all the new notifications to the queue
                        if (inappNotifs && [inappNotifs count] > 0) {
                            CleverTapLogInternal(self.config.logLevel, @"%@: Processing new InApps: %@", self, inappNotifs);
                            @try {
                                NSMutableArray *inapps = [[NSMutableArray alloc] initWithArray:[CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY]]];
                                for (int i = 0; i < [inappNotifs count]; i++) {
                                    @try {
                                        NSMutableDictionary *inappNotif = [[NSMutableDictionary alloc] initWithDictionary:inappNotifs[(NSUInteger) i]];
                                        [inapps addObject:inappNotif];
                                    } @catch (NSException *e) {
                                        CleverTapLogInternal(self.config.logLevel, @"%@: Malformed InApp notification", self);
                                    }
                                }
                                // Commit all the changes
                                [CTPreferences putObject:inapps forKey:[self storageKeyWithSuffix:CLTAP_PREFS_INAPP_KEY]];
                                
                                // Fire the first notification, if any
                                [self runOnNotificationQueue:^{
                                    [self _showNotificationIfAvailable];
                                }];
                            } @catch (NSException *e) {
                                CleverTapLogInternal(self.config.logLevel, @"%@: InApp notification handling error: %@", self, e.debugDescription);
                            }
                            // Handle inapp_stale
                            @try {
                                [self.inAppFCManager processResponse:jsonResp];
                            } @catch (NSException *ex) {
                                CleverTapLogInternal(self.config.logLevel, @"%@: Failed to handle inapp_stale update: %@", self, ex.debugDescription)
                            }
                        }
                    }
                }
#endif
                
#if !CLEVERTAP_NO_INBOX_SUPPORT
                NSArray *inboxJSON = jsonResp[CLTAP_INBOX_MSG_JSON_RESPONSE_KEY];
                if (inboxJSON) {
                    NSMutableArray *inboxNotifs;
                    @try {
                        inboxNotifs = [[NSMutableArray alloc] initWithArray:inboxJSON];
                    } @catch (NSException *e) {
                        CleverTapLogInternal(self.config.logLevel, @"%@: Error parsing Inbox Message JSON: %@", self, e.debugDescription);
                    }
                    if (inboxNotifs && [inboxNotifs count] > 0) {
                        [self initializeInboxWithCallback:^(BOOL success) {
                            if (success) {
                                [self runSerialAsync:^{
                                    NSArray <NSDictionary*> *messages =  [inboxNotifs mutableCopy];;
                                    [self.inboxController updateMessages:messages];
                                }];
                            }
                        }];
                    }
                }
#endif
                
#if !CLEVERTAP_NO_AB_SUPPORT
                if (!self.config.analyticsOnly && ![[self class] runningInsideAppExtension]) {
                    NSArray *experimentsJSON = jsonResp[CLTAP_AB_EXP_JSON_RESPONSE_KEY];
                    if (experimentsJSON) {
                        NSMutableArray *experiments;
                        @try {
                            experiments = [[NSMutableArray alloc] initWithArray:experimentsJSON];
                        } @catch (NSException *e) {
                            CleverTapLogInternal(self.config.logLevel, @"%@: Error parsing AB Experiments JSON: %@", self, e.debugDescription);
                        }
                        if (experiments && self.abTestController) {
                            [self.abTestController updateExperiments:experiments];
                        }
                    }
                }
#endif
                
#if !CLEVERTAP_NO_DISPLAY_UNIT_SUPPORT
                NSArray *displayUnitJSON = jsonResp[CLTAP_DISPLAY_UNIT_JSON_RESPONSE_KEY];
                if (displayUnitJSON) {
                    NSMutableArray *displayUnitNotifs;
                    @try {
                        displayUnitNotifs = [[NSMutableArray alloc] initWithArray:displayUnitJSON];
                    } @catch (NSException *e) {
                        CleverTapLogInternal(self.config.logLevel, @"%@: Error parsing Display Unit JSON: %@", self, e.debugDescription);
                    }
                    if (displayUnitNotifs && [displayUnitNotifs count] > 0) {
                        [self initializeDisplayUnitWithCallback:^(BOOL success) {
                            if (success) {
                                  NSArray <NSDictionary*> *displayUnits =  [displayUnitNotifs mutableCopy];
                                  [self.displayUnitController updateDisplayUnits:displayUnits];
                             }
                        }];
                    }
                }
#endif
                // Handle events/profiles sync data
                @try {
                    NSDictionary *evpr = jsonResp[@"evpr"];
                    if (evpr) {
                        NSDictionary *updates = [self.localDataStore syncWithRemoteData:evpr];
                        if (updates) {
                            if (self.syncDelegate && [self.syncDelegate respondsToSelector:@selector(profileDataUpdated:)]) {
                                [self.syncDelegate profileDataUpdated:updates];
                            }
                            [[NSNotificationCenter defaultCenter] postNotificationName:CleverTapProfileDidChangeNotification object:nil userInfo:updates];
                        }
                    }
                } @catch (NSException *e) {
                    CleverTapLogInternal(self.config.logLevel, @"%@: Failed to process profile data updates: %@", self, e.debugDescription);
                }
                
                // Handle console
                @try {
                    NSArray *consoleMessages = jsonResp[@"console"];
                    if (consoleMessages && [consoleMessages count] > 0) {
                        for (NSUInteger i = 0; i < [consoleMessages count]; ++i) {
                            CleverTapLogDebug(self.config.logLevel, @"%@", consoleMessages[i]);
                        }
                    }
                } @catch (NSException *ex) {
                    // no-op
                }
                
                // Handle arp
                @try {
                    [self processAdditionalRequestParameters:jsonResp];
                } @catch (NSException *ex) {
                    CleverTapLogInternal(self.config.logLevel, @"%@: Failed to handle ARP update: %@", self, ex.debugDescription)
                }
                
                // Handle dbg_lvl
                @try {
                    if (jsonResp[@"dbg_lvl"] && [jsonResp[@"dbg_lvl"] isKindOfClass:[NSNumber class]]) {
                        [[self class] setDebugLevel:((NSNumber *) jsonResp[@"dbg_lvl"]).intValue];
                        CleverTapLogDebug(self.config.logLevel, @"%@: Debug level set to %@ (set by upstream)", self, jsonResp[@"dbg_lvl"]);
                    }
                } @catch (NSException *ex) {
                    CleverTapLogInternal(self.config.logLevel, @"%@: Failed to set debug level: %@", self, ex.debugDescription);
                }
                
                // good time to make sure we have persisted the local profile if needed
                [self.localDataStore persistLocalProfileIfRequired];
                
                CleverTapLogInternal(self.config.logLevel, @"%@: parseResponse completed successfully", self);
                
                [self handleSendQueueSuccess];
                
            } else {
                CleverTapLogInternal(self.config.logLevel, @"%@: either the JSON response was nil or it wasn't of type NSDictionary", self);
                [self handleSendQueueFail];
            }
        }
        @catch (NSException *e) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Failed to parse the response as a JSON object. Reason: %@", self, e.debugDescription);
            [self handleSendQueueFail];
        }
    } else {
        CleverTapLogInternal(self.config.logLevel, @"%@: Expected a JSON object as the response, but received none", self);
        [self handleSendQueueFail];
    }
}

#pragma mark Profile Handling Private

- (NSString*)_optOutKey {
    NSString *currentGUID = self.deviceInfo.deviceId;
    return  currentGUID ? [NSString stringWithFormat:@"%@:OptOut:%@", self.config.accountId, currentGUID] : nil;
}

- (NSString*)_legacyOptOutKey {
    NSString *currentGUID = self.deviceInfo.deviceId;
    return  currentGUID ? [NSString stringWithFormat:@"OptOut:%@", currentGUID] : nil;
}

- (void)_setCurrentUserOptOutStateFromStorage {
    NSString *legacyKey = [self _legacyOptOutKey];
    NSString *key = [self _optOutKey];
    if (!key) {
        CleverTapLogInternal(self.config.logLevel, @"Unable to set user optOut state from storage: storage key is nil");
        return;
    }
    BOOL optedOut = NO;
    if (self.config.isDefaultInstance) {
        optedOut = (BOOL) [CTPreferences getIntForKey:key withResetValue:[CTPreferences getIntForKey:legacyKey withResetValue:NO]];
    } else {
        optedOut = (BOOL) [CTPreferences getIntForKey:key withResetValue:NO];
    }
    CleverTapLogInternal(self.config.logLevel, @"Setting user optOut state from storage to: %@ for storageKey: %@", optedOut ? @"YES" : @"NO", key);
    self.currentUserOptedOut = optedOut;
}

- (void)cacheGUIDSforProfile:(NSDictionary*)profileEvent {
    // cache identifier:guid pairs
    for (NSString *key in profileEvent) {
        @try {
            if ([CLTAP_PROFILE_IDENTIFIER_KEYS containsObject:key]) {
                NSString *identifier = [NSString stringWithFormat:@"%@", profileEvent[key]];
                [self cacheGUID:nil forKey:key andIdentifier:identifier];
            }
        } @catch (NSException *e) {
            // no-op
        }
    }
}

- (BOOL)isAnonymousDevice {
    NSDictionary *cache = [self getCachedGUIDs];
    if (!cache) cache = @{};
    return [cache count] <= 0;
}

- (NSDictionary *)getCachedGUIDs {
    NSDictionary *cachedGUIDS = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:kCachedGUIDS]];
    if (!cachedGUIDS && self.config.isDefaultInstance) {
        cachedGUIDS = [CTPreferences getObjectForKey:kCachedGUIDS];
    }
    return cachedGUIDS;
}

- (void)setCachedGUIDs:(NSDictionary *)cache {
    [CTPreferences putObject:cache forKey:[self storageKeyWithSuffix:kCachedGUIDS]];
}

- (NSString *)getGUIDforKey:(NSString *)key andIdentifier:(NSString *)identifier {
    if (!key || !identifier) return nil;
    
    NSDictionary *cache = [self getCachedGUIDs];
    NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", key, identifier];
    if (!cache) return nil;
    else return cache[cacheKey];
}

- (void)cacheGUID:(NSString *)guid forKey:(NSString *)key andIdentifier:(NSString *)identifier {
    if (!guid) guid = [self profileGetCleverTapID];
    if (!guid || [self.deviceInfo isErrorDeviceID] || !key || !identifier) return;
    
    NSDictionary *cache = [self getCachedGUIDs];
    if (!cache) cache = @{};
    NSMutableDictionary *newCache = [NSMutableDictionary dictionaryWithDictionary:cache];
    NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", key, identifier];
    newCache[cacheKey] = guid;
    [self setCachedGUIDs:newCache];
}

- (BOOL)deviceIsMultiUser {
    NSDictionary *cache = [self getCachedGUIDs];
    if (!cache) cache = @{};
    return [cache count] > 1;
}

- (BOOL)isProcessingLoginUserWithIdentifier:(NSString *)identifier {
     return identifier == nil ? NO : [self.processingLoginUserIdentifier isEqualToString:identifier];
}

- (void)_onUserLogin:(NSDictionary *)properties withCleverTapID:(NSString *)cleverTapID {
    if (!properties) return;
    
    NSString *currentGUID = [self profileGetCleverTapID];
    
    if (!currentGUID) return;
    
    NSString *cachedGUID;
    BOOL haveIdentifier = NO;
    
    // check for valid identifier keys
    // use the first one we find
    for (NSString *key in properties) {
        @try {
            if ([CLTAP_PROFILE_IDENTIFIER_KEYS containsObject:key]) {
                NSString *identifier = [NSString stringWithFormat:@"%@", properties[key]];
                if (identifier && [identifier length] > 0) {
                    haveIdentifier = YES;
                    cachedGUID = [self getGUIDforKey:key andIdentifier:identifier];
                    if (cachedGUID) break;
                }
            }
        } @catch (NSException *e) {
            // no-op
        }
    }
    
    // if no identifier provided or there are no identified users on the device; just push on the current profile
    if (![self.deviceInfo isErrorDeviceID]) {
        if (!haveIdentifier || [self isAnonymousDevice]) {
            CleverTapLogDebug(self.config.logLevel, @"%@: onUserLogin: either don't have identifier or device is anonymous, associating profile %@ with current user profile", self, properties);
            [self profilePush:properties];
            return;
        }
    }
    // if profile maps to current guid, push on current profile
    if (cachedGUID && [cachedGUID isEqualToString:currentGUID]) {
        CleverTapLogDebug(self.config.logLevel, @"%@: onUserLogin: profile %@ maps to current device id %@, using current user profile", self, properties, currentGUID);
        [self profilePush:properties];
        return;
    }
    // stringify the profile dict to use as a concurrent dupe key
    NSString *profileToString = [CTUtils dictionaryToJsonString:properties];
    
    // as processing happens async block concurrent onUserLogin requests with the same profile, as our cache is set async
    if ([self isProcessingLoginUserWithIdentifier:profileToString]) {
        CleverTapLogInternal(self.config.logLevel, @"Already processing onUserLogin, will not process for profile: %@", properties);
        return;
    }
    
    // prevent dupes
    self.processingLoginUserIdentifier = profileToString;
    
    [self _asyncSwitchUser:properties withCachedGuid:cachedGUID andCleverTapID:cleverTapID forAction:kOnUserLoginAction];
}

- (void) _asyncSwitchUser:(NSDictionary *)properties withCachedGuid:(NSString *)cachedGUID andCleverTapID:(NSString *)cleverTapID forAction:(NSString*)action  {
    
    [self runSerialAsync:^{
        CleverTapLogDebug(self.config.logLevel, @"%@: async switching user with properties:  %@", action, properties);
        
        // set OptOut to false for the old user
        self.currentUserOptedOut = NO;
        
        // unregister the push token on the current user
        [self pushDeviceTokenWithAction:CleverTapPushTokenUnregister];
        
        // clear any events in the queue
        [self clearQueue];
        
        // clear ARP and other context for the old user
        [self clearUserContext];
        
        // clear old profile data
        [self.localDataStore changeUser];
        
#if !CLEVERTAP_NO_INAPP_SUPPORT
        if (![[self class] runningInsideAppExtension]) {
            [self.inAppFCManager changeUser];
        }
#endif
        [self resetSession];
        
        if (cachedGUID) {
            [self.deviceInfo forceUpdateDeviceID:cachedGUID];
        } else if (self.config.useCustomCleverTapId){
            [self.deviceInfo forceUpdateCustomDeviceID:cleverTapID];
        } else {
            [self.deviceInfo forceNewDeviceID];
        }
        
        [self recordDeviceErrors];
        
        [self _setCurrentUserOptOutStateFromStorage];  // be sure to do this AFTER updating the GUID
        
#if !CLEVERTAP_NO_INBOX_SUPPORT
        [self _resetInbox];
#endif
        
#if !CLEVERTAP_NO_AB_SUPPORT
        [self _resetABTesting];
#endif
        
#if !CLEVERTAP_NO_DISPLAY_UNIT_SUPPORT
        [self _resetDisplayUnit];
#endif
        // push data on reset profile
        [self recordAppLaunched:action];
        if (properties) {
            [self profilePush:properties];
        }
        [self pushDeviceTokenWithAction:CleverTapPushTokenRegister];
        [self notifyUserProfileInitialized];
    }];
}

- (void)_pushBaseProfile {
    [self runSerialAsync:^{
        NSMutableDictionary *profile = [[self.localDataStore generateBaseProfile] mutableCopy];
        NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
        event[@"profile"] = profile;
        [self queueEvent:event withType:CleverTapEventTypeProfile];
    }];
}

#pragma mark Public

#pragma mark public API's for multi instance implementations

+ (void)handlePushNotification:(NSDictionary*)notification openDeepLinksInForeground:(BOOL)openInForeground {
    CleverTapLogStaticDebug(@"Handling notification: %@", notification);
    NSString *accountId = (NSString *) notification[@"wzrk_acct_id"];
    // route to the right instance
    if (!_instances || [_instances count] <= 0 || !accountId) {
        [[self sharedInstance] _handlePushNotification:notification openDeepLinksInForeground:openInForeground];
        return;
    }
    for (CleverTap *instance in [_instances allValues]) {
        if ([accountId isEqualToString:instance.config.accountId]) {
            [instance _handlePushNotification:notification openDeepLinksInForeground:openInForeground];
            break;
        }
    }
}
+ (void)handleOpenURL:(NSURL*)url {
    if ([[self class] runningInsideAppExtension]){
        CleverTapLogStaticDebug(@"handleOpenUrl is a no-op in an app extension.");
        return;
    }
    CleverTapLogStaticDebug(@"Handling open url: %@", url.absoluteString);
    NSDictionary *args = [CTUriHelper getQueryParameters:url andDecode:YES];
    NSString *accountId = args[@"wzrk_acct_id"];
    // if no accountId, default to the sharedInstance
    if (!accountId) {
        [[self sharedInstance] handleOpenURL:url sourceApplication:nil];
        return;
    }
    for (CleverTap *instance in [_instances allValues]) {
        if ([accountId isEqualToString:instance.config.accountId]) {
            [instance handleOpenURL:url sourceApplication:nil];
            break;
        }
    }
}

#pragma mark Profile/Event/Session APIs

- (void)notifyApplicationLaunchedWithOptions:launchOptions {
    if ([[self class] runningInsideAppExtension]) {
        CleverTapLogDebug(self.config.logLevel, @"%@: notifyApplicationLaunchedWithOptions is a no-op in an app extension.", self);
        return;
    }
    CleverTapLogInternal(self.config.logLevel, @"%@: Application launched with options: %@", self, launchOptions);
    [self _appEnteredForegroundWithLaunchingOptions:launchOptions];
}

#pragma mark Device Network Info reporting handling
// public
- (void)enableDeviceNetworkInfoReporting:(BOOL)enabled {
    self.enableNetworkInfoReporting = enabled;
    [CTPreferences putInt:enabled forKey:[self storageKeyWithSuffix:kNetworkInfoReportingKey]];
}

// private
- (void)_setDeviceNetworkInfoReportingFromStorage {
    BOOL enabled = NO;
    if (self.config.isDefaultInstance) {
        enabled = (BOOL) [CTPreferences getIntForKey:[self storageKeyWithSuffix:kNetworkInfoReportingKey] withResetValue:[CTPreferences getIntForKey:kNetworkInfoReportingKey withResetValue:NO]];
    } else {
        enabled = (BOOL) [CTPreferences getIntForKey:[self storageKeyWithSuffix:kNetworkInfoReportingKey] withResetValue:NO];
    }
    CleverTapLogInternal(self.config.logLevel, @"%@: Setting device network info reporting state from storage to: %@", self, enabled ? @"YES" : @"NO");
    [self enableDeviceNetworkInfoReporting:enabled];
}

#pragma mark Profile API

- (void)setOptOut:(BOOL)enabled {
    [self runSerialAsync:^ {
        CleverTapLogDebug(self.config.logLevel, @"%@: User: %@ OptOut set to: %@", self, self.deviceInfo.deviceId, enabled ? @"YES" : @"NO");
        NSDictionary *profile = @{CLTAP_OPTOUT: @(enabled)};
        if (enabled) {
            [self profilePush:profile];
            self.currentUserOptedOut = enabled;  // if opting out set this after processing the profile event that updates the server optOut state
        } else {
            self.currentUserOptedOut = enabled;  // if opting back in set this before processing the profile event that updates the server optOut state
            [self profilePush:profile];
        }
        NSString *key = [self _optOutKey];
        if (!key) {
            CleverTapLogInternal(self.config.logLevel, @"unable to store user optOut, optOutKey is nil");
            return;
        }
        [CTPreferences putInt:enabled forKey:key];
    }];
}
- (void)setOffline:(BOOL)offline {
    _offline = offline;
    if (_offline) {
        CleverTapLogDebug(self.config.logLevel, @"%@: offline is enabled, won't send queue", self);
    } else {
        CleverTapLogDebug(self.config.logLevel, @"%@: offline is disabled, send queue", self);
        [self flushQueue];
    }
}
- (BOOL)offline {
    return _offline;
}
- (void)onUserLogin:(NSDictionary *_Nonnull)properties {
    [self _onUserLogin:properties withCleverTapID:nil];
}

- (void)onUserLogin:(NSDictionary *_Nonnull)properties withCleverTapID:(NSString *_Nonnull)cleverTapID {
    [self _onUserLogin:properties withCleverTapID:cleverTapID];
}

- (void)profilePush:(NSDictionary *)properties {
    [self runSerialAsync:^{
        [CTProfileBuilder build:properties completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray<CTValidationResult*>*errors) {
            if (systemFields) {
                [self.localDataStore setProfileFields:systemFields];
            }
            NSMutableDictionary *profile = [[self.localDataStore generateBaseProfile] mutableCopy];
            if (customFields) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Constructed custom profile: %@", self, customFields);
                [self.localDataStore setProfileFields:customFields];
                [profile addEntriesFromDictionary:customFields];
            }
            [self cacheGUIDSforProfile:profile];
            
#if !defined(CLEVERTAP_TVOS)
            // make sure Phone is a string and debug check for country code and phone format, but always send
            NSArray *profileAllKeys = [profile allKeys];
            for (int i = 0; i < [profileAllKeys count]; i++) {
                NSString *key = profileAllKeys[(NSUInteger) i];
                id value = profile[key];
                if ([key isEqualToString:@"Phone"]) {
                    value = [NSString stringWithFormat:@"%@", value];
                    if (!self.deviceInfo.countryCode || [self.deviceInfo.countryCode isEqualToString:@""]) {
                        NSString *_value = (NSString *)value;
                        if (![_value hasPrefix:@"+"]) {
                            // if no country code and phone doesn't start with + log error but still send
                            NSString *errString = [NSString stringWithFormat:@"Device country code not available and profile phone: %@ does not appear to start with country code", _value];
                            CTValidationResult *error = [[CTValidationResult alloc] init];
                            [error setErrorCode:512];
                            [error setErrorDesc:errString];
                            [self pushValidationResult:error];
                            CleverTapLogDebug(self.config.logLevel, @"%@: %@", self, errString);
                        }
                    }
                    CleverTapLogInternal(self.config.logLevel, @"Profile phone number is: %@, device country code is: %@", value, self.deviceInfo.countryCode);
                }
            }
#endif
            NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
            event[@"profile"] = profile;
            [self queueEvent:event withType:CleverTapEventTypeProfile];
            
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
}

- (void)profilePushGraphUser:(id)fbGraphUser {
    [self runSerialAsync:^{
        [CTProfileBuilder buildGraphUser:fbGraphUser completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray<CTValidationResult*>*errors) {
            if (systemFields) {
                [self.localDataStore setProfileFields:systemFields];
            }
            NSMutableDictionary *profile = [[self.localDataStore generateBaseProfile] mutableCopy];
            if (customFields) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Constructed custom profile: %@", self, customFields);
                [self.localDataStore setProfileFields:customFields];
                [profile addEntriesFromDictionary:customFields];
            }
            [self cacheGUIDSforProfile:profile];
            
            NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
            event[@"profile"] = profile;
            [self queueEvent:event withType:CleverTapEventTypeProfile];
            
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
}

- (void)profilePushGooglePlusUser:(id)googleUser {
    [self runSerialAsync:^{
        [CTProfileBuilder buildGooglePlusUser:googleUser completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray<CTValidationResult*>*errors) {
            if (systemFields) {
                [self.localDataStore setProfileFields:systemFields];
            }
            NSMutableDictionary *profile = [[self.localDataStore generateBaseProfile] mutableCopy];
            if (customFields) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Constructed custom profile: %@", self, customFields);
                [self.localDataStore setProfileFields:customFields];
                [profile addEntriesFromDictionary:customFields];
            }
            [self cacheGUIDSforProfile:profile];
            
            NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
            event[@"profile"] = profile;
            [self queueEvent:event withType:CleverTapEventTypeProfile];
            
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
}

- (id)profileGet:(NSString *)propertyName {
    if (!self.config.enablePersonalization) {
        return nil;
    }
    return [self.localDataStore getProfileFieldForKey:propertyName];
}

- (void)profileRemoveValueForKey:(NSString *)key {
    [self runSerialAsync:^{
        [CTProfileBuilder buildRemoveValueForKey:key completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray<CTValidationResult*>*errors) {
            if (customFields && [[customFields allKeys] count] > 0) {
                NSMutableDictionary *profile = [[self.localDataStore generateBaseProfile] mutableCopy];
                NSString* _key = [customFields allKeys][0];
                CleverTapLogInternal(self.config.logLevel, @"%@: removing key %@ from profile", self, _key);
                [self.localDataStore removeProfileFieldForKey:_key];
                [profile addEntriesFromDictionary:customFields];
                
                NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
                event[@"profile"] = profile;
                [self queueEvent:event withType:CleverTapEventTypeProfile];
            }
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
}

- (void)profileSetMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key {
    [CTProfileBuilder buildSetMultiValues:values forKey:key localDataStore:self.localDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult*>*errors) {
       [self _handleMultiValueProfilePush:customFields updatedMultiValue:updatedMultiValue errors:errors];
    }];
}

- (void)profileAddMultiValue:(NSString *)value forKey:(NSString *)key {
    [CTProfileBuilder buildAddMultiValue:value forKey:key localDataStore:self.localDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult*>*errors) {
        [self _handleMultiValueProfilePush:customFields updatedMultiValue:updatedMultiValue errors:errors];
    }];
}

- (void)profileAddMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key {
    [CTProfileBuilder buildAddMultiValues:values forKey:key localDataStore:self.localDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult*>*errors) {
        [self _handleMultiValueProfilePush:customFields updatedMultiValue:updatedMultiValue errors:errors];
    }];
}

- (void)profileRemoveMultiValue:(NSString *)value forKey:(NSString *)key {
    [CTProfileBuilder buildRemoveMultiValue:value forKey:key localDataStore:self.localDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult*>*errors) {
        [self _handleMultiValueProfilePush:customFields updatedMultiValue:updatedMultiValue errors:errors];
    }];
}

- (void)profileRemoveMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key {
    [CTProfileBuilder buildRemoveMultiValues:values forKey:key localDataStore:self.localDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult*>*errors) {
        [self _handleMultiValueProfilePush:customFields updatedMultiValue:updatedMultiValue errors:errors];
    }];
}

// private
- (void)_handleMultiValueProfilePush:(NSDictionary*)customFields updatedMultiValue:(NSArray*)updatedMultiValue errors:(NSArray<CTValidationResult*>*)errors {
    if (customFields && [[customFields allKeys] count] > 0) {
        NSMutableDictionary *profile = [[self.localDataStore generateBaseProfile] mutableCopy];
        NSString* _key = [customFields allKeys][0];
        CleverTapLogInternal(self.config.logLevel, @"Created multi-value profile push: %@", customFields);
        [profile addEntriesFromDictionary:customFields];
        
        if (updatedMultiValue && [updatedMultiValue count] > 0) {
            [self.localDataStore setProfileFieldWithKey:_key andValue:updatedMultiValue];
        } else {
            [self.localDataStore removeProfileFieldForKey:_key];
        }
        NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
        event[@"profile"] = profile;
        [self queueEvent:event withType:CleverTapEventTypeProfile];
    }
    if (errors) {
        [self pushValidationResults:errors];
    }
}

- (NSString *)profileGetCleverTapID {
    return self.deviceInfo.deviceId;
}

- (NSString *)profileGetCleverTapAttributionIdentifier {
    return self.deviceInfo.deviceId;
}

#pragma mark User Action Events API

- (void)recordEvent:(NSString *)event {
    [self runSerialAsync:^{
        [CTEventBuilder build:event completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
            if (event) {
                [self queueEvent:event withType:CleverTapEventTypeRaised];
            }
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
}

- (void)recordEvent:(NSString *)event withProps:(NSDictionary *)properties {
    [self runSerialAsync:^{
        [CTEventBuilder build:event withEventActions:properties completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
            if (event) {
                [self queueEvent:event withType:CleverTapEventTypeRaised];
            }
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
}

- (void)recordChargedEventWithDetails:(NSDictionary *)chargeDetails andItems:(NSArray *)items {
    [self runSerialAsync:^{
        [CTEventBuilder buildChargedEventWithDetails:chargeDetails andItems:items completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
            if (event) {
                [self queueEvent:event withType:CleverTapEventTypeRaised];
            }
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
}

- (void)recordErrorWithMessage:(NSString *)message andErrorCode:(int)code {
    [self runSerialAsync:^{
        NSString *currentVCName = self.currentViewControllerName ? self.currentViewControllerName : @"Unknown";
        
        [self recordEvent:@"Error Occurred" withProps:@{
                                                        @"Error Message" : message,
                                                        @"Error Code" : @(code),
                                                        @"Location" : currentVCName
                                                        }];
    }];
}

- (void)recordScreenView:(NSString *)screenName {
    if ([[self class] runningInsideAppExtension]) {
        CleverTapLogDebug(self.config.logLevel, @"%@: recordScreenView is a no-op in an app extension.", self);
        return;
    }
    self.isAppForeground = YES;
    if (!screenName) {
        self.currentViewControllerName = nil;
        return;
    }
    // skip dupes
    if (self.currentViewControllerName && [self.currentViewControllerName isEqualToString:screenName]) {
        return;
    }
    CleverTapLogInternal(self.config.logLevel, @"%@: screen changed: %@", self, screenName);
    if (self.currentViewControllerName == nil && self.screenCount == 1) {
        self.screenCount--;
    }
    self.currentViewControllerName = screenName;
    self.screenCount++;
    
    [self recordPageEventWithExtras:nil];
}

- (void)recordNotificationViewedEventWithData:(id _Nonnull)notificationData {
    // normalize the notification data
#if !defined(CLEVERTAP_TVOS)
    NSDictionary *notification;
    if ([notificationData isKindOfClass:[UILocalNotification class]]) {
        notification = [((UILocalNotification *) notificationData) userInfo];
    } else if ([notificationData isKindOfClass:[NSDictionary class]]) {
        notification = notificationData;
    }
    [self runSerialAsync:^{
        [CTEventBuilder buildPushNotificationEvent:NO forNotification:notification completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
            if (event) {
                self.wzrkParams = [event[@"evtData"] copy];
                [self queueEvent:event withType:CleverTapEventTypeNotificationViewed];
            };
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
#endif
}
- (NSTimeInterval)eventGetFirstTime:(NSString *)event {
    
    if (!self.config.enablePersonalization) {
        return -1;
    }
    return [self.localDataStore getFirstTimeForEvent:event];
}

- (NSTimeInterval)eventGetLastTime:(NSString *)event {
    
    if (!self.config.enablePersonalization) {
        return -1;
    }
    return [self.localDataStore getLastTimeForEvent:event];
}

- (int)eventGetOccurrences:(NSString *)event {
    
    if (!self.config.enablePersonalization) {
        return -1;
    }
    return [self.localDataStore getOccurrencesForEvent:event];
}

- (NSDictionary *)userGetEventHistory {
    
    if (!self.config.enablePersonalization) {
        return nil;
    }
    return [self.localDataStore getEventHistory];
}

- (CleverTapEventDetail *)eventGetDetail:(NSString *)event {
    
    if (!self.config.enablePersonalization) {
        return nil;
    }
    return [self.localDataStore getEventDetail:event];
}


#pragma mark Session API

- (NSTimeInterval)sessionGetTimeElapsed {
    long current = self.sessionId;
    return (int) [[[NSDate alloc] init] timeIntervalSince1970] - current;
}

- (CleverTapUTMDetail *)sessionGetUTMDetails {
    CleverTapUTMDetail *d = [[CleverTapUTMDetail alloc] init];
    d.source = self.source;
    d.medium = self.medium;
    d.campaign = self.campaign;
    return d;
}

- (int)userGetTotalVisits {
    return [self eventGetOccurrences:@"App Launched"];
}

- (int)userGetScreenCount {
    return self.screenCount;
}

- (NSTimeInterval)userGetPreviousVisitTime {
    return self.lastAppLaunchedTime;
}

# pragma mark Notifications

- (void)setPushToken:(NSData *)pushToken {
    if ([[self class] runningInsideAppExtension]){
        CleverTapLogDebug(self.config.logLevel, @"%@: setPushToken is a no-op in an app extension.", self);
        return;
    }
    NSString *deviceTokenString = [CTUtils deviceTokenStringFromData:pushToken];
    [self setPushTokenAsString:deviceTokenString];
}

- (void)setPushTokenAsString:(NSString *)pushTokenString {
    if ([[self class] runningInsideAppExtension]){
        CleverTapLogDebug(self.config.logLevel, @"%@: setPushTokenAsString is a no-op in an app extension.", self);
        return;
    }
    if (self.config.analyticsOnly) {
        CleverTapLogDebug(self.config.logLevel,@"%@ is analyticsOnly, not registering APNs device token %@", self, pushTokenString);
        return;
    }
    CleverTapLogDebug(self.config.logLevel, @"%@: registering APNs device token %@", self, pushTokenString);
    [self storeDeviceToken:pushTokenString];
    [self pushDeviceToken:pushTokenString forRegisterAction:CleverTapPushTokenRegister];
}

- (void)handleNotificationWithData:(id)data {
    if ([[self class] runningInsideAppExtension]){
        CleverTapLogDebug(self.config.logLevel, @"%@: handleNotificationWithData is a no-op in an app extension.", self);
        return;
    }
    [self handleNotificationWithData:data openDeepLinksInForeground:NO];
}

- (void)handleNotificationWithData:(id)data openDeepLinksInForeground:(BOOL)openInForeground {
    if ([[self class] runningInsideAppExtension]){
        CleverTapLogDebug(self.config.logLevel, @"%@: handleNotificationWithData is a no-op in an app extension.", self);
        return;
    }
    [self _handlePushNotification:data openDeepLinksInForeground:openInForeground];
}

- (BOOL)isCleverTapNotification:(NSDictionary *)payload {
    return [self _isCTPushNotification:payload];
}

- (void)showInAppNotificationIfAny {
    if ([[self class] runningInsideAppExtension]){
        CleverTapLogDebug(self.config.logLevel, @"%@: showInappNotificationIfAny is a no-op in an app extension.", self);
        return;
    }
    if (!self.config.analyticsOnly) {
        [self runOnNotificationQueue:^{
            [self _showNotificationIfAvailable];
        }];
    }
}

# pragma mark Referrer Tracking

- (void)handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication {
    if ([[self class] runningInsideAppExtension]){
        CleverTapLogDebug(self.config.logLevel, @"%@: handleOpenUrl is a no-op in an app extension.", self);
        return;
    }
    CleverTapLogDebug(self.config.logLevel, @"%@: handling open URL %@", self, url.absoluteString);
    NSString *URLString = [url absoluteString];
    if (URLString != nil) {
        [self _pushDeepLink:URLString withSourceApp:sourceApplication];
    }
}

- (void)pushInstallReferrerSource:(NSString *)source
                           medium:(NSString *)medium
                         campaign:(NSString *)campaign {
    if ([[self class] runningInsideAppExtension]){
        CleverTapLogDebug(self.config.logLevel, @"%@: pushInstallReferrerSource:medium:campaign is a no-op in an app extension.", self);
        return;
    }
    if (!source && !medium && !campaign) return;
    
    @synchronized (self) {
        long installStatus = 0;
        if (self.config.isDefaultInstance) {
            installStatus = [CTPreferences getIntForKey:[self storageKeyWithSuffix:@"install_referrer_status"] withResetValue:[CTPreferences getIntForKey:@"install_referrer_status" withResetValue:0]];
        } else {
            installStatus = [CTPreferences getIntForKey:[self storageKeyWithSuffix:@"install_referrer_status"] withResetValue:0];
        }
        if (installStatus == 1) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Install referrer has already been set. Will not overwrite", self);
            return;
        }
        [CTPreferences putInt:1 forKey:[self storageKeyWithSuffix:@"install_referrer_status"]];
    }
    @try {
        if (source) source = [CTUtils urlEncodeString:source];
        if (medium) medium = [CTUtils urlEncodeString:medium];
        if (campaign) campaign = [CTUtils urlEncodeString:campaign];
        
        NSString *uriStr = @"wzrk://track?install=true";
        
        if (source) uriStr = [uriStr stringByAppendingFormat:@"&utm_source=%@", source];
        if (medium) uriStr = [uriStr stringByAppendingFormat:@"&utm_medium=%@", medium];
        if (campaign) uriStr = [uriStr stringByAppendingFormat:@"&utm_campaign=%@", campaign];
        
        [self _pushDeepLink:uriStr withSourceApp:nil andInstall:true];
    } @catch (NSException *e) {
        // no-op
    }
}

#pragma mark Admin

- (void)setLibrary:(NSString *)name {
    self.deviceInfo.library = name;
}

+ (void)setDebugLevel:(int)level {
    [CTLogger setDebugLevel:level];
    if (_defaultInstanceConfig) {
        CleverTap *sharedInstance = [CleverTap sharedInstance];
        if (sharedInstance) {
            sharedInstance.config.logLevel = level;
        }
    }
}

+ (CleverTapLogLevel)getDebugLevel {
    return (CleverTapLogLevel)[CTLogger getDebugLevel];
}

+ (void)changeCredentialsWithAccountID:(NSString *)accountID andToken:(NSString *)token {
    [self _changeCredentialsWithAccountID:accountID token:token region:nil];
}

+ (void)changeCredentialsWithAccountID:(NSString *)accountID token:(NSString *)token region:(NSString *)region {
    [self _changeCredentialsWithAccountID:accountID token:token region:region];
}

+ (void)setCredentialsWithAccountID:(NSString *)accountID andToken:(NSString *)token {
    [self _changeCredentialsWithAccountID:accountID token:token region:nil];
}

+ (void)setCredentialsWithAccountID:(NSString *)accountID token:(NSString *)token region:(NSString *)region {
    [self _changeCredentialsWithAccountID:accountID token:token region:region];
}

- (void)setSyncDelegate:(id <CleverTapSyncDelegate>)delegate {
    if (delegate && [delegate conformsToProtocol:@protocol(CleverTapSyncDelegate)]) {
        _syncDelegate = delegate;
    } else {
        CleverTapLogDebug(self.config.logLevel, @"%@: CleverTap Sync Delegate does not conform to the CleverTapSyncDelegate protocol", self);
    }
}

- (id<CleverTapSyncDelegate>)syncDelegate {
    return _syncDelegate;
}

- (void)setInAppNotificationDelegate:(id <CleverTapInAppNotificationDelegate>)delegate {
    if ([[self class] runningInsideAppExtension]){
        CleverTapLogDebug(self.config.logLevel, @"%@: setInAppNotificationDelegate is a no-op in an app extension.", self);
        return;
    }
    if (delegate && [delegate conformsToProtocol:@protocol(CleverTapInAppNotificationDelegate)]) {
         _inAppNotificationDelegate = delegate;
    } else {
        CleverTapLogDebug(self.config.logLevel, @"%@: CleverTap InAppNotification Delegate does not conform to the CleverTapInAppNotificationDelegate protocol", self);
    }
}

- (id<CleverTapInAppNotificationDelegate>)inAppNotificationDelegate {
    return _inAppNotificationDelegate;
}

+ (void)enablePersonalization {
    [self setPersonalizationEnabled:true];
}

+ (void)disablePersonalization {
    [self setPersonalizationEnabled:false];
}

+ (void)setPersonalizationEnabled:(BOOL)enabled {
    [CTPreferences putInt:enabled forKey:kWR_KEY_PERSONALISATION_ENABLED];
}

+ (BOOL)isPersonalizationEnabled {
    return (BOOL) [CTPreferences getIntForKey:kWR_KEY_PERSONALISATION_ENABLED withResetValue:YES];
}

+ (void)setLocation:(CLLocationCoordinate2D)location {
    [[self sharedInstance] setLocation:location];
}

- (void)setLocation:(CLLocationCoordinate2D)location {
    self.userSetLocation = location;
}

+ (void)getLocationWithSuccess:(void (^)(CLLocationCoordinate2D location))success andError:(void (^)(NSString *reason))error; {
#if defined(CLEVERTAP_LOCATION)
    [CTLocationManager getLocationWithSuccess:success andError:error];
#else
    CleverTapLogStaticInfo(@"To Enable CleverTap Location services/apis please build the SDK with the CLEVERTAP_LOCATION macro");
#endif
}

#pragma clang diagnostic pop

#pragma mark Event API

- (NSTimeInterval)getFirstTime:(NSString *)event {
    return [self eventGetFirstTime:event];
}

- (NSTimeInterval)getLastTime:(NSString *)event {
    return [self eventGetLastTime:event];
}

- (int)getOccurrences:(NSString *)event {
    return [self eventGetOccurrences:event];
}

- (NSDictionary *)getHistory {
    return [self userGetEventHistory];
}

- (CleverTapEventDetail *)getEventDetail:(NSString *)event {
    return [self eventGetDetail:event];
}

#pragma mark Profile API

- (id)getProperty:(NSString *)propertyName {
    return [self profileGet:propertyName];
}

#pragma mark Session API

- (NSTimeInterval)getTimeElapsed {
    return [self sessionGetTimeElapsed];
}

- (int)getTotalVisits {
    return [self userGetTotalVisits];
}

- (int)getScreenCount {
    return [self userGetScreenCount];
}

- (NSTimeInterval)getPreviousVisitTime {
    return [self userGetPreviousVisitTime];
}

- (CleverTapUTMDetail *)getUTMDetails {
    return [self sessionGetUTMDetails];
}

#if defined(CLEVERTAP_HOST_WATCHOS)
- (BOOL)handleMessage:(NSDictionary<NSString *, id> *)message forWatchSession:(WCSession *)session  {
    NSString *type = [message objectForKey:@"clevertap_type"];
    
    BOOL handled = (type != nil);
    
    if ([type isEqualToString:@"recordEventWithProps"]) {
        [self recordEvent: message[@"event"] withProps: message[@"props"]];
    }
    return handled;
}
#endif

#pragma mark - Inbox

#if !CLEVERTAP_NO_INBOX_SUPPORT

#pragma mark public

- (void)initializeInboxWithCallback:(CleverTapInboxSuccessBlock)callback {
    if ([[self class] runningInsideAppExtension]) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Inbox unavailable in app extensions", self);
        self.inboxController = nil;
        return;
    }
    if (_config.analyticsOnly) {
        CleverTapLogDebug(self.config.logLevel, @"%@ is configured as analytics only, Inbox unavailable", self);
        self.inboxController = nil;
        return;
    }
    if (sizeof(void*) == 4) {
        CleverTapLogDebug(self.config.logLevel, @"%@: CleverTap Inbox is not available on 32-bit Architecture", self);
        self.inboxController = nil;
        return;
    }
    [self runSerialAsync:^{
        if (self.inboxController) {
            [[self class] runSyncMainQueue: ^{
                callback(self.inboxController.isInitialized);
            }];
            return;
        }
        if (self.deviceInfo.deviceId) {
            self.inboxController = [[CTInboxController alloc] initWithAccountId: [self.config.accountId copy] guid: [self.deviceInfo.deviceId copy]];
            self.inboxController.delegate = self;
            [[self class] runSyncMainQueue: ^{
                callback(self.inboxController.isInitialized);
            }];
        }
    }];
}

- (NSUInteger)getInboxMessageCount {
    if (![self _isInboxInitialized]) {
        return -1;
    }
    return self.inboxController.count;
}

- (NSUInteger)getInboxMessageUnreadCount {
    if (![self _isInboxInitialized]) {
        return -1;
    }
    return self.inboxController.unreadCount;
}

- (NSArray<CleverTapInboxMessage *> * _Nonnull )getAllInboxMessages {
    NSMutableArray *all = [NSMutableArray new];
    if (![self _isInboxInitialized]) {
        return all;
    }
    for (NSDictionary *m in self.inboxController.messages) {
        @try {
            [all addObject: [[CleverTapInboxMessage alloc] initWithJSON:m]];
        } @catch (NSException *e) {
            CleverTapLogDebug(_config.logLevel, @"Error getting inbox message: %@", e.debugDescription);
        }
    };
    
    return all;
}

- (NSArray<CleverTapInboxMessage *> * _Nonnull )getUnreadInboxMessages {
    NSMutableArray *all = [NSMutableArray new];
    if (![self _isInboxInitialized]) {
        return all;
    }
    for (NSDictionary *m in self.inboxController.unreadMessages) {
        @try {
            [all addObject: [[CleverTapInboxMessage alloc] initWithJSON:m]];
        } @catch (NSException *e) {
            CleverTapLogDebug(_config.logLevel, @"Error getting inbox message: %@", e.debugDescription);
        }
    };
    return all;
}

- (CleverTapInboxMessage * _Nullable )getInboxMessageForId:(NSString * _Nonnull)messageId {
    if (![self _isInboxInitialized]) {
        return nil;
    }
    NSDictionary *m = [self.inboxController messageForId:messageId];
    return (m != nil) ? [[CleverTapInboxMessage alloc] initWithJSON:m] : nil;
}

- (void)deleteInboxMessage:(CleverTapInboxMessage * _Nonnull)message {
    if (![self _isInboxInitialized]) {
        return;
    }
    [self.inboxController deleteMessageWithId:message.messageId];
}

- (void)markReadInboxMessage:(CleverTapInboxMessage * _Nonnull) message {
    if (![self _isInboxInitialized]) {
        return;
    }
    [self.inboxController markReadMessageWithId:message.messageId];
}

- (void)registerInboxUpdatedBlock:(CleverTapInboxUpdatedBlock)block {
    if (!_inboxUpdateBlocks) {
        _inboxUpdateBlocks = [NSMutableArray new];
    }
    [_inboxUpdateBlocks addObject:block];
}

- (CleverTapInboxViewController * _Nonnull)newInboxViewControllerWithConfig:(CleverTapInboxStyleConfig * _Nullable )config andDelegate:(id<CleverTapInboxViewControllerDelegate> _Nullable )delegate {
    if (![self _isInboxInitialized]) {
        return nil;
    }
    NSArray *messages = [self getAllInboxMessages];
    if (! messages) {
        return nil;
    }
    return [[CleverTapInboxViewController alloc] initWithMessages:messages config:config delegate:delegate analyticsDelegate:self];
}

#pragma mark private

- (void)_resetInbox {
    if (self.inboxController && self.inboxController.isInitialized && self.deviceInfo.deviceId) {
        self.inboxController = [[CTInboxController alloc] initWithAccountId: [self.config.accountId copy] guid: [self.deviceInfo.deviceId copy]];
        self.inboxController.delegate = self;
    }
}

- (BOOL)_isInboxInitialized {
    if ([[self class] runningInsideAppExtension]) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Inbox unavailable in app extensions", self);
        return NO;
    }
    if (_config.analyticsOnly) {
        CleverTapLogDebug(self.config.logLevel, @"%@ is configured as analytics only, Inbox unavailable", self);
        return NO;
    }
    
    if (!self.inboxController || !self.inboxController.isInitialized) {
        CleverTapLogDebug(_config.logLevel, @"%@: Inbox not initialized.  Did you call initializeInboxWithCallback: ?", self);
        return NO;
    }
    return YES;
}

#pragma mark CTInboxDelegate

- (void)inboxMessagesDidUpdate {
    CleverTapLogInternal(self.config.logLevel, @"%@: Inbox messages did update: %@", self, [self getAllInboxMessages]);
    for (CleverTapInboxUpdatedBlock block in self.inboxUpdateBlocks) {
        if (block) {
            block();
        }
    }
}

#pragma mark CleverTapInboxViewControllerAnalyticsDelegate

- (void)messageDidShow:(CleverTapInboxMessage *)message {
    CleverTapLogDebug(_config.logLevel, @"%@: inbox message viewed: %@", self, message);
    [self markReadInboxMessage:message];
    [self recordInboxMessageStateEvent:NO forMessage:message andQueryParameters:nil];
}

- (void)messageDidSelect:(CleverTapInboxMessage *_Nonnull)message atIndex:(int)index withButtonIndex:(int)buttonIndex {
    CleverTapLogDebug(_config.logLevel, @"%@: inbox message clicked: %@", self, message);
    [self recordInboxMessageStateEvent:YES forMessage:message andQueryParameters:nil];
    
    CleverTapInboxMessageContent *content = (CleverTapInboxMessageContent*)message.content[index];
    NSURL *ctaURL;
    // no button index, means use the on message click url if any
    if (buttonIndex < 0) {
        if (content.actionHasUrl) {
            if (content.actionUrl && content.actionUrl.length > 0) {
                ctaURL = [NSURL URLWithString:content.actionUrl];
            }
        }
    }
    // button index so find the corresponding action link if any
    else {
        if (content.actionHasLinks) {
            NSDictionary *customExtras = [content customDataForLinkAtIndex:buttonIndex];
            if (customExtras && customExtras.count > 0) return;
            NSString *linkUrl = [content urlForLinkAtIndex:buttonIndex];
            if (linkUrl && linkUrl.length > 0) {
                ctaURL = [NSURL URLWithString:linkUrl];
            }
        }
    }
    
    if (ctaURL && ![ctaURL.absoluteString isEqual: @""]) {
#if !CLEVERTAP_NO_INBOX_SUPPORT
            [[self class] runSyncMainQueue:^{
                UIApplication *sharedApplication = [[self class] getSharedApplication];
                if (sharedApplication == nil) {
                    return;
                }
                CleverTapLogDebug(self.config.logLevel, @"%@: Inbox message: firing deep link: %@", self, ctaURL);
#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_9_0
                if ([sharedApplication respondsToSelector:@selector(openURL:options:completionHandler:)]) {
                    NSMethodSignature *signature = [UIApplication
                                                    instanceMethodSignatureForSelector:@selector(openURL:options:completionHandler:)];
                    NSInvocation *invocation = [NSInvocation
                                                invocationWithMethodSignature:signature];
                    [invocation setTarget:sharedApplication];
                    [invocation setSelector:@selector(openURL:options:completionHandler:)];
                    NSDictionary *options = @{};
                    id completionHandler = nil;
                    [invocation setArgument:&ctaURL atIndex:2];
                    [invocation setArgument:&options atIndex:3];
                    [invocation setArgument:&completionHandler atIndex:4];
                    [invocation invoke];
                } else {
                    if ([sharedApplication respondsToSelector:@selector(openURL:)]) {
                        [sharedApplication performSelector:@selector(openURL:) withObject:ctaURL];
                    }
                }
#else
                if ([sharedApplication respondsToSelector:@selector(openURL:)]) {
                    [sharedApplication performSelector:@selector(openURL:) withObject:ctaURL];
                }
#endif
            }];
#endif
        }
}

- (void)recordInboxMessageStateEvent:(BOOL)clicked
                          forMessage:(CleverTapInboxMessage *)message andQueryParameters:(NSDictionary *)params {
    
    [self runSerialAsync:^{
        [CTEventBuilder buildInboxMessageStateEvent:clicked forMessage:message andQueryParameters:params completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
            if (event) {
                if (clicked) {
                    self.wzrkParams = [event[@"evtData"] copy];
                }
                [self queueEvent:event withType:CleverTapEventTypeRaised];
            };
            if (errors) {
                [self pushValidationResults:errors];
            }
        }];
    }];
}

#pragma mark Inbox Message private

- (BOOL)didHandleInboxMessageTestFromPushNotificaton:(NSDictionary*)notification {
#if !CLEVERTAP_NO_INBOX_SUPPORT
    if ([[self class] runningInsideAppExtension]) {
        return NO;
    }
    
    if (!notification || [notification count] <= 0 || !notification[@"wzrk_inbox"]) return NO;
    
    @try {
        CleverTapLogDebug(self.config.logLevel, @"%@: Received inbox message from push payload: %@", self, notification);
        
        NSDictionary *msg;
        id data = notification[@"wzrk_inbox"];
        if ([data isKindOfClass:[NSString class]]) {
            NSString *jsonString = (NSString*)data;
            msg = [NSJSONSerialization
                   JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                   options:0
                   error:nil];
            
        } else if ([data isKindOfClass:[NSDictionary class]]) {
            msg = (NSDictionary*)data;
        }
        
        if (!msg) {
             CleverTapLogDebug(self.config.logLevel, @"%@: Unable to decode inbox message from push payload: %@", self, notification);
        }
        
        NSDate *now = [NSDate date];
        NSTimeInterval nowEpochSeconds = [now timeIntervalSince1970];
        NSInteger epochTime = nowEpochSeconds;
        NSString *nowEpoch = [NSString stringWithFormat:@"%li", (long)epochTime];
        
        NSDate *expireDate = [now dateByAddingTimeInterval:(24 * 60 * 60)];
        NSTimeInterval expireEpochSeconds = [expireDate timeIntervalSince1970];
        NSUInteger expireTime = (long)expireEpochSeconds;

        NSMutableDictionary *message = [NSMutableDictionary dictionary];
        [message setObject:nowEpoch forKey:@"_id"];
        [message setObject:[NSNumber numberWithLong:expireTime] forKey:@"wzrk_ttl"];
        [message addEntriesFromDictionary:msg];
        
        NSMutableArray<NSDictionary*> *inboxMsg = [NSMutableArray new];
        [inboxMsg addObject:message];
        
        if (inboxMsg) {
            float delay = self.isAppForeground ? 0.5 : 2.0;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @try {
                    [self initializeInboxWithCallback:^(BOOL success) {
                        if (success) {
                            [self runSerialAsync:^{
                                [self.inboxController updateMessages:inboxMsg];
                            }];
                        }
                    }];
                } @catch (NSException *e) {
                    CleverTapLogDebug(self.config.logLevel, @"%@: Failed to display the inbox message from payload: %@", self, e.debugDescription);
                }
            });
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Failed to parse the inbox message as JSON", self);
            return YES;
        }
        
    } @catch (NSException *e) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Failed to display the inbox message from payload: %@", self, e.debugDescription);
        return YES;
    }
    
#endif
    return YES;
}

#endif  //!CLEVERTAP_NO_INBOX_SUPPORT

#pragma mark - AB Testing

#if !CLEVERTAP_NO_AB_SUPPORT

#pragma mark AB Testing public


+ (void)setUIEditorConnectionEnabled:(BOOL)enabled {
    [CTPreferences putInt:enabled forKey:kWR_KEY_AB_TEST_EDITOR_ENABLED];
}

+ (BOOL)isUIEditorConnectionEnabled {
    return (BOOL) [CTPreferences getIntForKey:kWR_KEY_AB_TEST_EDITOR_ENABLED withResetValue:NO];
}

- (void)registerBoolVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerBoolVariableWithName:name];
}


- (void)registerDoubleVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerDoubleVariableWithName:name];
}

- (void)registerIntegerVariableWithName:(NSString*)name {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerIntegerVariableWithName:name];
}

- (void)registerStringVariableWithName:(NSString*)name {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerStringVariableWithName:name];
}

- (void)registerArrayOfBoolVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerArrayOfBoolVariableWithName:name];
}

- (void)registerArrayOfDoubleVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerArrayOfDoubleVariableWithName:name];
}

- (void)registerArrayOfIntegerVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerArrayOfIntegerVariableWithName:name];
}

- (void)registerArrayOfStringVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerArrayOfStringVariableWithName:name];
}

- (void)registerDictionaryOfBoolVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerDictionaryOfBoolVariableWithName:name];
}

- (void)registerDictionaryOfDoubleVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerDictionaryOfDoubleVariableWithName:name];
}

- (void)registerDictionaryOfIntegerVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerDictionaryOfIntegerVariableWithName:name];
}

- (void)registerDictionaryOfStringVariableWithName:(NSString* _Nonnull)name {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
        return;
    }
    [self.abTestController registerDictionaryOfStringVariableWithName:name];
}

- (BOOL)getBoolVariableWithName:(NSString* _Nonnull)name defaultValue:(BOOL)defaultValue {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getBoolVariableWithName:name defaultValue:defaultValue];
}

- (double)getDoubleVariableWithName:(NSString* _Nonnull)name defaultValue:(double)defaultValue {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getDoubleVariableWithName:name defaultValue:defaultValue];
}

- (int)getIntegerVariableWithName:(NSString*)name defaultValue:(int)defaultValue {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getIntegerVariableWithName:name defaultValue:defaultValue];
}

- (NSString*)getStringVariableWithName:(NSString*)name defaultValue:(NSString*)defaultValue {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getStringVariableWithName:name defaultValue:defaultValue];
}

- (NSArray<NSNumber*>* _Nonnull)getArrayOfBoolVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSNumber*>* _Nonnull)defaultValue {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getArrayOfBoolVariableWithName:name defaultValue:defaultValue];
}

- (NSArray<NSNumber*>* _Nonnull)getArrayOfDoubleVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSNumber*>* _Nonnull)defaultValue {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getArrayOfDoubleVariableWithName:name defaultValue:defaultValue];
}

- (NSArray<NSNumber*>* _Nonnull)getArrayOfIntegerVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSNumber*>* _Nonnull)defaultValue {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getArrayOfIntegerVariableWithName:name defaultValue:defaultValue];
}

- (NSArray<NSString*>* _Nonnull)getArrayOfStringVariableWithName:(NSString* _Nonnull)name defaultValue:(NSArray<NSString*>* _Nonnull)defaultValue {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getArrayOfStringVariableWithName:name defaultValue:defaultValue];
}

- (NSDictionary<NSString*, NSNumber*>* _Nonnull)getDictionaryOfBoolVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSNumber*>* _Nonnull)defaultValue {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getDictionaryOfBoolVariableWithName:name defaultValue:defaultValue];
}

- (NSDictionary<NSString*, NSNumber*>* _Nonnull)getDictionaryOfDoubleVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSNumber*>* _Nonnull)defaultValue {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getDictionaryOfDoubleVariableWithName:name defaultValue:defaultValue];
}

- (NSDictionary<NSString*, NSNumber*>* _Nonnull)getDictionaryOfIntegerVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSNumber*>* _Nonnull)defaultValue {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getDictionaryOfIntegerVariableWithName:name defaultValue:defaultValue];
}

- (NSDictionary<NSString*, NSString*>* _Nonnull)getDictionaryOfStringVariableWithName:(NSString* _Nonnull)name defaultValue:(NSDictionary<NSString*, NSString*>* _Nonnull)defaultValue {
    if (!self.abTestController) {
        CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance, returning default value", self);
        return defaultValue;
    }
    return [self.abTestController getDictionaryOfStringVariableWithName:name defaultValue:defaultValue];
}

#pragma mark ABTesting private
- (void) _initABTesting {
    if (!self.config.analyticsOnly && ![[self class] runningInsideAppExtension]) {
        if (!self.config.enableABTesting) {
            CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
            return;
        }
        _config.enableUIEditor = [[self class] isUIEditorConnectionEnabled];
        if (!self.abTestController) {
            self.abTestController = [[CTABTestController alloc] initWithConfig:self->_config guid:[self profileGetCleverTapID] delegate:self];
        }
    }
}

- (void) _resetABTesting {
    if (!self.config.analyticsOnly && ![[self class] runningInsideAppExtension]) {
        if (!self.config.enableABTesting) {
            CleverTapLogDebug(self.config.logLevel, @"%@: ABTesting is not enabled for this instance", self);
            return;
        }
        if (self.abTestController) {
            [self.abTestController resetWithGuid:[self profileGetCleverTapID]];
        } else {
            [self _initABTesting];
        }
    }
}

#pragma mark CTABTestingDelegate

- (CTDeviceInfo* _Nonnull)getDeviceInfo {
    return self.deviceInfo;
}

- (void)abExperimentsDidUpdate {
    CleverTapLogInternal(self.config.logLevel, @"%@: AB Experiments did update", self);
    for (CleverTapExperimentsUpdatedBlock block in self.experimentsUpdateBlocks) {
        if (block) {
            block();
        }
    }
}

- (void)registerExperimentsUpdatedBlock:(CleverTapExperimentsUpdatedBlock)block {
    if (!_experimentsUpdateBlocks) {
        _experimentsUpdateBlocks = [NSMutableArray new];
    }
    [_experimentsUpdateBlocks addObject:block];
}

#endif  //!CLEVERTAP_NO_AB_SUPPORT


#pragma mark - Display View

#if !CLEVERTAP_NO_DISPLAY_UNIT_SUPPORT

- (void)initializeDisplayUnitWithCallback:(CleverTapDisplayUnitSuccessBlock)callback {
    [self runSerialAsync:^{
        if (self.displayUnitController) {
           [[self class] runSyncMainQueue: ^{
               callback(self.displayUnitController.isInitialized);
           }];
           return;
        }
        if (self.deviceInfo.deviceId) {
            self.displayUnitController = [[CTDisplayUnitController alloc] initWithAccountId: [self.config.accountId copy] guid: [self.deviceInfo.deviceId copy]];
            self.displayUnitController.delegate = self;
            [[self class] runSyncMainQueue: ^{
              callback(self.displayUnitController.isInitialized);
           }];
        }
    }];
}

- (void)_resetDisplayUnit {
    if (self.displayUnitController && self.displayUnitController.isInitialized && self.deviceInfo.deviceId) {
        self.displayUnitController = [[CTDisplayUnitController alloc] initWithAccountId: [self.config.accountId copy] guid: [self.deviceInfo.deviceId copy]];
        self.displayUnitController.delegate = self;
    }
}

- (void)setDisplayUnitDelegate:(id<CleverTapDisplayUnitDelegate>)delegate {
    if ([[self class] runningInsideAppExtension]){
        CleverTapLogDebug(self.config.logLevel, @"%@: setDisplayUnitDelegate is a no-op in an app extension.", self);
        return;
    }
    if (delegate && [delegate conformsToProtocol:@protocol(CleverTapDisplayUnitDelegate)]) {
         _displayUnitDelegate = delegate;
    } else {
        CleverTapLogDebug(self.config.logLevel, @"%@: CleverTap Display Unit Delegate does not conform to the CleverTapDisplayUnitDelegate protocol", self);
    }
}

- (id<CleverTapDisplayUnitDelegate>)displayUnitDelegate {
    return _displayUnitDelegate;
}

- (void)displayUnitsDidUpdate {
    if (self.displayUnitDelegate && [self.displayUnitDelegate respondsToSelector:@selector(displayUnitsUpdated:)]) {
        [self.displayUnitDelegate displayUnitsUpdated:self.displayUnitController.displayUnits];
    }
}

- (BOOL)didHandleDisplayUnitTestFromPushNotificaton:(NSDictionary*)notification {
#if !CLEVERTAP_NO_DISPLAY_UNIT_SUPPORT
    if ([[self class] runningInsideAppExtension]) {
        return NO;
    }
    
    if (!notification || [notification count] <= 0 || !notification[@"wzrk_adunit"]) return NO;
    
    @try {
        CleverTapLogDebug(self.config.logLevel, @"%@: Received display unit from push payload: %@", self, notification);
        
        NSString *jsonString = notification[@"wzrk_adunit"];
        
        NSDictionary *displayUnitDict = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                              options:0
                                                                error:nil];
        
        NSMutableArray<NSDictionary*> *displayUnits = [NSMutableArray new];
        [displayUnits addObject:displayUnitDict];
        
        if (displayUnits && displayUnits.count > 0) {
            float delay = self.isAppForeground ? 0.5 : 2.0;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
             @try {
                 [self initializeDisplayUnitWithCallback:^(BOOL success) {
                         if (success) {
                              [self.displayUnitController updateDisplayUnits:displayUnits];
                         }
                    }];
                } @catch (NSException *e) {
                    CleverTapLogDebug(self.config.logLevel, @"%@: Failed to initialize the display unit from payload: %@", self, e.debugDescription);
                }
            });
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Failed to parse the display unit as JSON", self);
            return YES;
        }
        
    } @catch (NSException *e) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Failed to initialize the display unit from payload: %@", self, e.debugDescription);
        return YES;
    }
    
#endif
    return YES;
}


#pragma mark Display Unit Public

- (NSArray<CleverTapDisplayUnit *>*)getAllDisplayUnits {
    return self.displayUnitController.displayUnits;
}

- (CleverTapDisplayUnit *_Nullable)getDisplayUnitForID:(NSString *)unitID {
    for (CleverTapDisplayUnit *displayUnit in self.displayUnitController.displayUnits) {
       if ([displayUnit.unitID isEqualToString:unitID]) {
           @try {
                return displayUnit;
             } @catch (NSException *e) {
                CleverTapLogDebug(_config.logLevel, @"Error getting display unit: %@", e.debugDescription);
             }
        }
    };
    return nil;
}

- (void)recordDisplayUnitViewedEventForID:(NSString *)unitID {
      // get the display unit data
    CleverTapDisplayUnit *displayUnit = [self getDisplayUnitForID:unitID];
    #if !defined(CLEVERTAP_TVOS)
        [self runSerialAsync:^{
            [CTEventBuilder buildDisplayViewStateEvent:NO forDisplayUnit:displayUnit andQueryParameters:nil completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
                if (event) {
                    self.wzrkParams = [event[@"evtData"] copy];
                    [self queueEvent:event withType:CleverTapEventTypeRaised];
                };
                if (errors) {
                    [self pushValidationResults:errors];
                }
            }];
        }];
    #endif
}

- (void)recordDisplayUnitClickedEventForID:(NSString *)unitID {
      // get the display unit data
    CleverTapDisplayUnit *displayUnit = [self getDisplayUnitForID:unitID];
    #if !defined(CLEVERTAP_TVOS)
        [self runSerialAsync:^{
            [CTEventBuilder buildDisplayViewStateEvent:YES forDisplayUnit:displayUnit andQueryParameters:nil completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
                if (event) {
                    self.wzrkParams = [event[@"evtData"] copy];
                    [self queueEvent:event withType:CleverTapEventTypeRaised];
                };
                if (errors) {
                    [self pushValidationResults:errors];
                }
            }];
        }];
    #endif
}

#endif

@end

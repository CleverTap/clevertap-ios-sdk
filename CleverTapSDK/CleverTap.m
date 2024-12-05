
#import "CleverTap.h"
#import "CleverTapInternal.h"
#import "CTUtils.h"
#import "CTUIUtils.h"
#import "CTSwizzle.h"
#import "CTLogger.h"
#import "CTSwizzleManager.h"
#import "CTConstants.h"
#import "CTPlistInfo.h"
#import "CTValidator.h"
#import "CTUriHelper.h"
#import "CTInAppUtils.h"
#import "CTDeviceInfo.h"
#import "CTPreferences.h"
#import "CTEventBuilder.h"
#import "CTProfileBuilder.h"
#import "CTLocalDataStore.h"
#import "CleverTapUTMDetail.h"
#import "CleverTapEventDetail.h"
#import "CleverTapSyncDelegate.h"
#import "CleverTapURLDelegate.h"
#import "CleverTapInstanceConfig.h"
#import "CleverTapInstanceConfigPrivate.h"
#import "CleverTapPushNotificationDelegate.h"
#import "CleverTapInAppNotificationDelegate.h"
#import "CTValidationResult.h"
#import "CTValidationResultStack.h"
#import "CTIdentityRepoFactory.h"
#import "CTLoginInfoProvider.h"
#import "CTDispatchQueueManager.h"
#import "CTMultiDelegateManager.h"
#import "CTSessionManager.h"
#import "CTFileDownloader.h"

#if !CLEVERTAP_NO_INAPP_SUPPORT
#import "CTInAppFCManager.h"
#import "CTInAppNotification.h"
#import "CTInAppDisplayViewController.h"
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
#import "CleverTap+InAppNotifications.h"
#import "CTLocalInApp.h"
#import "CleverTap+PushPermission.h"
#import "CleverTapJSInterfacePrivate.h"
#import "CTPushPrimerManager.h"
#import "CTInAppDisplayManager.h"
#import "CleverTap+InAppsResponseHandler.h"
#import "CTInAppEvaluationManager.h"
#import "CTInAppTriggerManager.h"
#import "CTCustomTemplatesManager-Internal.h"
#endif

#if !CLEVERTAP_NO_INBOX_SUPPORT
#import "CTInboxController.h"
#import "CleverTap+Inbox.h"
#import "CleverTapInboxViewControllerPrivate.h"
#endif

#if CLEVERTAP_SSL_PINNING
#import "CTPinnedNSURLSessionDelegate.h"
static NSArray *sslCertNames;
#endif

#if !CLEVERTAP_NO_DISPLAY_UNIT_SUPPORT
#import "CTDisplayUnitController.h"
#import "CleverTap+DisplayUnit.h"
#endif

#import "CTBatchSentDelegate.h"
#import "CTAttachToBatchHeaderDelegate.h"
#import "CTSwitchUserDelegate.h"

#import "CleverTap+FeatureFlags.h"
#import "CleverTapFeatureFlagsPrivate.h"
#import "CTFeatureFlagsController.h"

#import "CleverTap+ProductConfig.h"
#import "CleverTapProductConfigPrivate.h"
#import "CTProductConfigController.h"

#import "CTVarCache.h"
#import "CTVariables.h"
#import "CleverTap+CTVar.h"

#import "CTRequestFactory.h"
#import "CTRequestSender.h"
#import "CTDomainFactory.h"
#import "CleverTap+SCDomain.h"

#import "NSDictionary+Extensions.h"

#import "CTAES.h"

#import <objc/runtime.h>

static const void *const kQueueKey = &kQueueKey;
static const void *const kNotificationQueueKey = &kNotificationQueueKey;
static NSMutableDictionary *auxiliarySdkVersions;

static NSRecursiveLock *instanceLock;
static const int kMaxBatchSize = 49;
NSString *const kQUEUE_NAME_PROFILE = @"net_queue_profile";
NSString *const kQUEUE_NAME_EVENTS = @"events";
NSString *const kQUEUE_NAME_NOTIFICATIONS = @"notifications";

NSString *const kREDIRECT_DOMAIN_KEY = @"CLTAP_REDIRECT_DOMAIN_KEY";
NSString *const kREDIRECT_NOTIF_VIEWED_DOMAIN_KEY = @"CLTAP_REDIRECT_NOTIF_VIEWED_DOMAIN_KEY";
NSString *const kMUTED_TS_KEY = @"CLTAP_MUTED_TS_KEY";

NSString *const kREDIRECT_HEADER = @"X-WZRK-RD";
NSString *const kREDIRECT_NOTIF_VIEWED_HEADER = @"X-WZRK-SPIKY-RD";
NSString *const kMUTE_HEADER = @"X-WZRK-MUTE";


NSString *const kI_KEY = @"CLTAP_I_KEY";
NSString *const kJ_KEY = @"CLTAP_J_KEY";

NSString *const kFIRST_TS_KEY = @"CLTAP_FIRST_TS_KEY";
NSString *const kLAST_TS_KEY = @"CLTAP_LAST_TS_KEY";

NSString *const kMultiUserPrefix = @"mt_";

NSString *const kNetworkInfoReportingKey = @"NetworkInfo";

NSString *const kWR_KEY_PERSONALISATION_ENABLED = @"boolPersonalisationEnabled";
NSString *const CleverTapProfileDidInitializeNotification = CLTAP_PROFILE_DID_INITIALIZE_NOTIFICATION;
NSString *const CleverTapProfileDidChangeNotification = CLTAP_PROFILE_DID_CHANGE_NOTIFICATION;
NSString *const CleverTapGeofencesDidUpdateNotification = CLTAP_GEOFENCES_DID_UPDATE_NOTIFICATION;

NSString *const kOnUserLoginAction = @"onUserLogin";
NSString *const kInstanceWithCleverTapIDAction = @"instanceWithCleverTapID";

static int currentRequestTimestamp = 0;
static int initialAppEnteredForegroundTime = 0;
static BOOL isAutoIntegrated;

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

@interface CleverTap () {}
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

@interface CleverTap () <CTFeatureFlagsDelegate, CleverTapPrivateFeatureFlagsDelegate> {}
@property (atomic, strong) CTFeatureFlagsController *featureFlagsController;
@property (atomic, strong, readwrite, nonnull) CleverTapFeatureFlags *featureFlags;

@end

@interface CleverTap () <CTProductConfigDelegate, CleverTapPrivateProductConfigDelegate> {}
@property (atomic, strong) CTProductConfigController *productConfigController;
@property (atomic, strong, readwrite, nonnull) CleverTapProductConfig *productConfig;

@end

#import <UserNotifications/UserNotifications.h>

@interface CleverTap () <UIApplicationDelegate> {
}

@property (nonatomic, strong, readwrite) CleverTapInstanceConfig *config;
@property (nonatomic, assign) NSTimeInterval lastAppLaunchedTime;
@property (nonatomic, strong) CTDeviceInfo *deviceInfo;
@property (nonatomic, strong) CTLocalDataStore *localDataStore;
@property (nonatomic, strong) CTDispatchQueueManager *dispatchQueueManager;

@property (nonatomic, strong) NSMutableArray *eventsQueue;
@property (nonatomic, strong) NSMutableArray *profileQueue;
@property (nonatomic, strong) NSMutableArray *notificationsQueue;
@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) CTDomainFactory *domainFactory;
@property (nonatomic, strong) CTRequestSender *requestSender;
@property (nonatomic, assign) NSTimeInterval lastMutedTs;
@property (nonatomic, assign) int sendQueueFails;

@property (nonatomic, assign, readwrite) BOOL isAppForeground;

@property (nonatomic, assign) BOOL pushedAPNSId;
@property (atomic, assign) BOOL currentUserOptedOut;
@property (atomic, assign) BOOL offline;
@property (atomic, assign) BOOL enableNetworkInfoReporting;
@property (atomic, assign) BOOL initialEventsPushed;
@property (atomic, assign) CLLocationCoordinate2D userSetLocation;
@property (nonatomic, assign) double lastLocationPingTime;

@property (atomic, retain) NSDictionary *wzrkParams;
@property (atomic, retain) NSDictionary *lastUTMFields;
@property (atomic, strong) NSString *currentViewControllerName;

@property (atomic, strong) CTValidationResultStack *validationResultStack;
@property (nonatomic, strong) CTSessionManager *sessionManager;

@property (atomic, weak) id <CleverTapSyncDelegate> syncDelegate;
@property (atomic, weak) id <CleverTapURLDelegate> urlDelegate;
@property (atomic, weak) id <CleverTapPushNotificationDelegate> pushNotificationDelegate;
@property (atomic, weak) id <CleverTapInAppNotificationDelegate> inAppNotificationDelegate;
@property (nonatomic, weak) id <CleverTapDomainDelegate> domainDelegate;

@property (atomic, weak) id <CTBatchSentDelegate> batchSentDelegate;
@property (nonatomic, strong, readwrite) CTMultiDelegateManager *delegateManager;

@property (nonatomic, strong, readwrite) CTFileDownloader *fileDownloader;

#if !CLEVERTAP_NO_INAPP_SUPPORT
@property (atomic, weak) id <CleverTapPushPermissionDelegate> pushPermissionDelegate;
@property (atomic, strong) CTPushPrimerManager *pushPrimerManager;

@property (strong, nonatomic, nullable) CleverTapFetchInAppsBlock fetchInAppsBlock;
@property (nonatomic, strong, readwrite) CTInAppFCManager *inAppFCManager;
@property (nonatomic, strong, readwrite) CTInAppEvaluationManager *inAppEvaluationManager;
@property (nonatomic, strong, readwrite) CTInAppDisplayManager *inAppDisplayManager;
@property (nonatomic, strong, readwrite) CTImpressionManager *impressionManager;
@property (nonatomic, strong, readwrite) CTInAppStore * _Nullable inAppStore;
@property (nonatomic, strong, readwrite) CTCustomTemplatesManager *customTemplatesManager;
#endif

@property (atomic, strong) NSString *processingLoginUserIdentifier;

@property (nonatomic, assign, readonly) BOOL sslPinningEnabled;

@property (atomic, assign) BOOL geofenceLocation;
@property (nonatomic, strong) NSString *gfSDKVersion;

@property (nonatomic, strong) CTVariables *variables;

@property (nonatomic, strong) NSLocale *locale;

- (instancetype)init __unavailable;

@end

@implementation CleverTap

@synthesize wzrkParams=_wzrkParams;
@synthesize syncDelegate=_syncDelegate;
@synthesize urlDelegate=_urlDelegate;
@synthesize pushNotificationDelegate=_pushNotificationDelegate;
@synthesize inAppNotificationDelegate=_inAppNotificationDelegate;
@synthesize userSetLocation=_userSetLocation;
@synthesize offline=_offline;
@synthesize geofenceLocation=_geofenceLocation;
@synthesize domainDelegate=_domainDelegate;

#if !CLEVERTAP_NO_DISPLAY_UNIT_SUPPORT
@synthesize displayUnitDelegate=_displayUnitDelegate;
#endif

@synthesize featureFlagsDelegate=_featureFlagsDelegate;
@synthesize productConfigDelegate=_productConfigDelegate;
#if !CLEVERTAP_NO_INAPP_SUPPORT
@synthesize pushPermissionDelegate=_pushPermissionDelegate;
#endif

static CTPlistInfo *_plistInfo;
static NSMutableDictionary<NSString*, CleverTap*> *_instances;
static CleverTapInstanceConfig *_defaultInstanceConfig;
static BOOL sharedInstanceErrorLogged;

#pragma mark - Lifecycle

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDidFinishLaunchingNotification:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instanceLock = [NSRecursiveLock new];
        _instances = [NSMutableDictionary new];
        _plistInfo = [CTPlistInfo sharedInstance];
#if CLEVERTAP_SSL_PINNING
        // Only pin anchor/CA certificates
        sslCertNames = @[@"AmazonRootCA1"];
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
    
    if ([_instances respondsToSelector: @selector(enumerateKeysAndObjectsUsingBlock:)]) {
        [_instances enumerateKeysAndObjectsUsingBlock:^(NSString* _Nonnull key, CleverTap* _Nonnull instance, BOOL * _Nonnull stop) {
            if ([instance respondsToSelector: @selector(notifyApplicationLaunchedWithOptions:)]) {
                [instance notifyApplicationLaunchedWithOptions:launchOptions];
            }
        }];
    }
}

+ (nullable instancetype)autoIntegrate {
    return [self _autoIntegrateWithCleverTapID:nil];
}

+ (nullable instancetype)autoIntegrateWithCleverTapID:(NSString *)cleverTapID {
    return [self _autoIntegrateWithCleverTapID:cleverTapID];
}

+ (nullable instancetype)_autoIntegrateWithCleverTapID:(NSString *)cleverTapID {
    CleverTapLogStaticInfo("%@: Auto Integration enabled", self);
    isAutoIntegrated = YES;
    [CTSwizzleManager swizzleAppDelegate];
    CleverTap *instance = cleverTapID ? [CleverTap sharedInstanceWithCleverTapID:cleverTapID] : [CleverTap sharedInstance];
    return instance;
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

#pragma mark - Instance Lifecycle

+ (nullable instancetype)sharedInstance {
    return [self _sharedInstanceWithCleverTapID:nil];
}

+ (nullable instancetype)sharedInstanceWithCleverTapID:(NSString *)cleverTapID {
    return [self _sharedInstanceWithCleverTapID:cleverTapID];
}

+ (nullable instancetype)_sharedInstanceWithCleverTapID:(NSString *)cleverTapID {
    @try {
        [instanceLock lock];
    if (_defaultInstanceConfig == nil) {
        if (!_plistInfo.accountId || !_plistInfo.accountToken) {
            if (!sharedInstanceErrorLogged) {
                sharedInstanceErrorLogged = YES;
                CleverTapLogStaticInfo(@"Unable to initialize default CleverTap SDK instance. %@: %@ %@: %@", CLTAP_ACCOUNT_ID_LABEL, _plistInfo.accountId, CLTAP_TOKEN_LABEL, _plistInfo.accountToken);
            }
            return nil;
        }
        if (_plistInfo.proxyDomain.length > 0 && _plistInfo.spikyProxyDomain.length > 0) {
            _defaultInstanceConfig = [[CleverTapInstanceConfig alloc] initWithAccountId:_plistInfo.accountId accountToken:_plistInfo.accountToken proxyDomain:_plistInfo.proxyDomain spikyProxyDomain:_plistInfo.spikyProxyDomain isDefaultInstance:YES];
        } else if (_plistInfo.proxyDomain.length > 0) {
            _defaultInstanceConfig = [[CleverTapInstanceConfig alloc] initWithAccountId:_plistInfo.accountId accountToken:_plistInfo.accountToken proxyDomain:_plistInfo.proxyDomain isDefaultInstance:YES];
        } else if (_plistInfo.handshakeDomain.length > 0) {
            _defaultInstanceConfig = [[CleverTapInstanceConfig alloc] initWithAccountId:_plistInfo.accountId accountToken:_plistInfo.accountToken handshakeDomain:_plistInfo.handshakeDomain isDefaultInstance:YES];
        } else {
            _defaultInstanceConfig = [[CleverTapInstanceConfig alloc] initWithAccountId:_plistInfo.accountId accountToken:_plistInfo.accountToken accountRegion:_plistInfo.accountRegion isDefaultInstance:YES];
        }
        
        if (_defaultInstanceConfig == nil) {
            return nil;
        }
        _defaultInstanceConfig.enablePersonalization = [CleverTap isPersonalizationEnabled];
        _defaultInstanceConfig.logLevel = [self getDebugLevel];
        _defaultInstanceConfig.enableFileProtection = _plistInfo.enableFileProtection;
        _defaultInstanceConfig.handshakeDomain = _plistInfo.handshakeDomain;
        NSString *regionLog = (!_plistInfo.accountRegion || _plistInfo.accountRegion.length < 1) ? @"default" : _plistInfo.accountRegion;
        NSString *proxyDomainLog = (!_plistInfo.proxyDomain || _plistInfo.proxyDomain.length < 1) ? @"" : _plistInfo.proxyDomain;
        NSString *spikyProxyDomainLog = (!_plistInfo.spikyProxyDomain || _plistInfo.spikyProxyDomain.length < 1) ? @"" : _plistInfo.spikyProxyDomain;
        CleverTapLogStaticInfo(@"Initializing default CleverTap SDK instance. %@: %@ %@: %@ %@: %@ %@: %@ %@: %@ %@: %d", CLTAP_ACCOUNT_ID_LABEL, _plistInfo.accountId, CLTAP_TOKEN_LABEL, _plistInfo.accountToken, CLTAP_REGION_LABEL, regionLog, CLTAP_PROXY_DOMAIN_LABEL, proxyDomainLog, CLTAP_SPIKY_PROXY_DOMAIN_LABEL, spikyProxyDomainLog, CLTAP_ENABLE_FILE_PROTECTION, _plistInfo.enableFileProtection);
    }
    return [self _instanceWithConfig:_defaultInstanceConfig andCleverTapID:cleverTapID];
    } @finally {
        [instanceLock unlock];
    }
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
    if (instance == nil || instance.deviceInfo.deviceId == nil) {
        if (config.accountId) {
            instance = [[self alloc] initWithConfig:config andCleverTapID:cleverTapID];
            _instances[config.accountId] = instance;
            [instance recordDeviceErrors];
#if !CLEVERTAP_NO_INAPP_SUPPORT
            // Set resume status for inApp notifications to handle it on device level
            [instance.inAppDisplayManager _resumeInAppNotifications];
#endif
        }
    } else {
        if ([instance.deviceInfo isErrorDeviceID] && instance.config.useCustomCleverTapId && cleverTapID != nil && [CTValidator isValidCleverTapId:cleverTapID]) {
            [instance _asyncSwitchUser:nil withCachedGuid:nil andCleverTapID:cleverTapID forAction:kInstanceWithCleverTapIDAction];
        }
    }
    return instance;
}

- (instancetype)initWithConfig:(CleverTapInstanceConfig*)config andCleverTapID:(NSString *)cleverTapID {
    self = [super init];
    if (self) {
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
        
        self.dispatchQueueManager = [[CTDispatchQueueManager alloc]initWithConfig:_config];
        self.delegateManager = [[CTMultiDelegateManager alloc] init];
        
        _localDataStore = [[CTLocalDataStore alloc] initWithConfig:_config profileValues:initialProfileValues andDeviceInfo: _deviceInfo dispatchQueueManager:_dispatchQueueManager];
        
        _lastAppLaunchedTime = [self eventGetLastTime:@"App Launched"];
        self.validationResultStack = [[CTValidationResultStack alloc]initWithConfig: _config];
        self.userSetLocation = kCLLocationCoordinate2DInvalid;
        
        // save config to defaults
        [CTPreferences archiveObject:config forFileName: [CleverTapInstanceConfig dataArchiveFileNameWithAccountId:config.accountId] config:config];
        
        [self _setDeviceNetworkInfoReportingFromStorage];
        [self _setCurrentUserOptOutStateFromStorage];
        [self initNetworking];
        [self inflateQueuesAsync];
        [self addObservers];
        
        self.fileDownloader = [[CTFileDownloader alloc] initWithConfig:self.config];
#if !CLEVERTAP_NO_INAPP_SUPPORT
        if (!_config.analyticsOnly && ![CTUIUtils runningInsideAppExtension]) {
            [self initializeInAppSupport];
        }
#endif
#if defined(CLEVERTAP_TVOS)
        self.sessionManager = [[CTSessionManager alloc] initWithConfig:self.config];
#endif
        
        int now = [[[NSDate alloc] init] timeIntervalSince1970];
        if (now - initialAppEnteredForegroundTime > 5) {
            _config.isCreatedPostAppLaunched = YES;
        }
        
        [self _initFeatureFlags];
        
        [self _initProductConfig];
        
        // Initialise Variables
        self.variables = [[CTVariables alloc] initWithConfig:self.config deviceInfo:self.deviceInfo fileDownloader:self.fileDownloader];
        
        [self notifyUserProfileInitialized];
    }
    
    return self;
}

#if !CLEVERTAP_NO_INAPP_SUPPORT
- (void)initializeInAppSupport {
    CTInAppStore *inAppStore = [[CTInAppStore alloc] initWithConfig:self.config
                                                    delegateManager:self.delegateManager
                                                           deviceId:self.deviceInfo.deviceId];
    self.inAppStore = inAppStore;
    
    CTImpressionManager *impressionManager = [[CTImpressionManager alloc] initWithAccountId:self.config.accountId deviceId:self.deviceInfo.deviceId delegateManager:self.delegateManager];
    CTInAppTriggerManager *triggerManager = [[CTInAppTriggerManager alloc] initWithAccountId:self.config.accountId deviceId:self.deviceInfo.deviceId delegateManager:self.delegateManager];
    
    CTInAppFCManager *inAppFCManager = [[CTInAppFCManager alloc] initWithConfig:self.config delegateManager:self.delegateManager deviceId:[_deviceInfo.deviceId copy] impressionManager:impressionManager inAppTriggerManager:triggerManager];
    
    CTCustomTemplatesManager *templatesManager = [[CTCustomTemplatesManager alloc] initWithConfig:self.config];
    
    CTInAppDisplayManager *displayManager = [[CTInAppDisplayManager alloc] initWithCleverTap:self
                                                                        dispatchQueueManager:self.dispatchQueueManager
                                                                              inAppFCManager:inAppFCManager
                                                                           impressionManager:impressionManager
                                                                                  inAppStore:inAppStore
                                                                            templatesManager:templatesManager
                                                                              fileDownloader:self.fileDownloader];
    
    CTInAppEvaluationManager *evaluationManager = [[CTInAppEvaluationManager alloc] initWithAccountId:self.config.accountId deviceId:self.deviceInfo.deviceId delegateManager:self.delegateManager impressionManager:impressionManager inAppDisplayManager:displayManager inAppStore:inAppStore inAppTriggerManager:triggerManager];
    
    self.customTemplatesManager = templatesManager;
    self.inAppFCManager = inAppFCManager;
    self.impressionManager = impressionManager;
    self.inAppEvaluationManager = evaluationManager;
    self.inAppEvaluationManager.location = self.userSetLocation;
    self.inAppDisplayManager = displayManager;

    self.sessionManager = [[CTSessionManager alloc] initWithConfig:self.config impressionManager:self.impressionManager inAppStore:inAppStore];
    
    self.pushPrimerManager = [[CTPushPrimerManager alloc] initWithConfig:_config inAppDisplayManager:self.inAppDisplayManager dispatchQueueManager:_dispatchQueueManager];
    [self.inAppDisplayManager setPushPrimerManager:self.pushPrimerManager];
}
#endif

+ (CleverTap *)getGlobalInstance:(NSString *)accountId {
    
    if (!_instances || [_instances count] <= 0) {
        NSSet *allowedClasses = [NSSet setWithObjects:[CleverTapInstanceConfig class], [CTAES class], [NSArray class], [NSString class], nil];
        CleverTapInstanceConfig *config = [CTPreferences unarchiveFromFile:[CleverTapInstanceConfig dataArchiveFileNameWithAccountId:accountId] ofTypes:allowedClasses removeFile:NO];
        return [CleverTap instanceWithConfig:config];
    }
    
    return _instances[accountId];
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private

+ (void)_setCredentialsWithAccountID:(NSString *)accountID token:(NSString *)token region:(NSString *)region {
    [self _setCredentialsWithAccountID:accountID token:token];
    
    if (region != nil && ![region isEqualToString:@""]) {
        region = [region stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (region.length <= 0) {
            region = nil;
        }
    }
    [_plistInfo setCredentialsWithAccountID:accountID token:token region:region];
}

+ (void)_setCredentialsWithAccountID:(NSString *)accountID token:(NSString *)token proxyDomain:(NSString *)proxyDomain {
    [self _setCredentialsWithAccountID:accountID token:token];
    
    if (proxyDomain != nil && ![proxyDomain isEqualToString:@""]) {
        proxyDomain = [proxyDomain stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (proxyDomain.length <= 0) {
            proxyDomain = nil;
        }
    }
}

+ (void)_setCredentialsWithAccountID:(NSString *)accountID token:(NSString *)token {
    @try {
        [instanceLock lock];
    if (_defaultInstanceConfig) {
        CleverTapLogStaticDebug(@"CleverTap SDK already initialized with accountID: %@ and token: %@. Cannot change credentials to %@ : %@", _defaultInstanceConfig.accountId, _defaultInstanceConfig.accountToken, accountID, token);
        return;
    }
    accountID = [accountID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    token = [token stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } @finally {
        [instanceLock unlock];
    }
}

+ (NSMutableDictionary<NSString*, CleverTap*>*)getInstances {
    return _instances;
}

- (void)addObservers {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"CleverTap.%@", self.config.accountId];
}

- (void)initNetworking {
    if (self.config.isDefaultInstance) {
        self.lastMutedTs = [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kLAST_TS_KEY config: self.config] withResetValue:[CTPreferences getIntForKey:kMUTED_TS_KEY withResetValue:0]];
    } else {
        self.lastMutedTs = [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kLAST_TS_KEY config: self.config] withResetValue:0];
    }

#if CLEVERTAP_SSL_PINNING
     self.urlSessionDelegate = [[CTPinnedNSURLSessionDelegate alloc] initWithConfig:self.config];
    self.domainFactory = [[CTDomainFactory alloc]initWithConfig:self.config pinnedNSURLSessionDelegate: self.urlSessionDelegate sslCertNames: sslCertNames];
    self.requestSender = [[CTRequestSender alloc]initWithConfig:self.config redirectDomain:self.domainFactory.redirectDomain pinnedNSURLSessionDelegate: self.urlSessionDelegate sslCertNames: sslCertNames];
#else
    self.domainFactory = [[CTDomainFactory alloc]initWithConfig:self.config];
    
    self.requestSender = [[CTRequestSender alloc]initWithConfig:self.config redirectDomain:self.domainFactory.redirectDomain];
#endif
    [self doHandshakeAsyncWithCompletion:nil];
}

- (void)setUserSetLocation:(CLLocationCoordinate2D)location {
    _userSetLocation = location;
#if !CLEVERTAP_NO_INAPP_SUPPORT
    [self.inAppEvaluationManager setLocation:location];
#endif
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


# pragma mark - Handshake Handling

- (void)persistMutedTs {
    self.lastMutedTs = [NSDate new].timeIntervalSince1970;
    [CTPreferences putInt:self.lastMutedTs forKey:[CTPreferences storageKeyWithSuffix:kMUTED_TS_KEY config: self.config]];
}

- (BOOL)needHandshake {
    if ([self isMuted] || self.domainFactory.explictEndpointDomain) {
        return NO;
    }
    return self.domainFactory.redirectDomain == nil;
}

- (void)doHandshakeAsyncWithCompletion:(void (^ _Nullable )(void))taskBlock {
    [self.dispatchQueueManager runSerialAsync:^{
        if (![self needHandshake]) {
            //self.domainFactory.redirectDomain contains value
            [self onDomainAvailable];
            if (taskBlock) {
                taskBlock();
            }
            return;
        }
        CleverTapLogInternal(self.config.logLevel, @"%@: starting handshake with %@", self, kHANDSHAKE_URL);
        
        // Need to simulate a synchronous request
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        CTRequest *ctRequest = [CTRequestFactory helloRequestWithConfig:self.config];
        [ctRequest onResponse:^(NSData * _Nullable data, NSURLResponse * _Nullable response) {
            
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if (httpResponse.statusCode == 200) {
                    [self updateStateFromResponseHeadersShouldRedirect:httpResponse.allHeaderFields];
                    [self updateStateFromResponseHeadersShouldRedirectForNotif:httpResponse.allHeaderFields];
                    [self handleHandshakeSuccess];
                } else {
                    [self onDomainUnavailable];
                }
            } else {
                [self onDomainUnavailable];
            }
            if (taskBlock) {
                taskBlock();
            }
                
            dispatch_semaphore_signal(semaphore);
        }];
        [ctRequest onError:^(NSError * _Nullable error) {
            [self onDomainUnavailable];
            dispatch_semaphore_signal(semaphore);
        }];
        [self.requestSender send:ctRequest];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }];
}

- (void)runSerialAsyncEnsureHandshake:(void(^)(void))block {
    if ([self needHandshake]) {
        [self.dispatchQueueManager runSerialAsync:^{
            [self doHandshakeAsyncWithCompletion:^{
                block();
            }];
        }];
    }
    else {
        [self.dispatchQueueManager runSerialAsync:^{
            block();
        }];
    }
}

- (BOOL)updateStateFromResponseHeadersShouldRedirectForNotif:(NSDictionary *)headers {
    CleverTapLogInternal(self.config.logLevel, @"%@: processing response with headers:%@", self, headers);
    BOOL shouldRedirect = NO;
    @try {
        NSString *redirectNotifViewedDomain = headers[kREDIRECT_NOTIF_VIEWED_HEADER];
        if (redirectNotifViewedDomain != nil) {
            NSString *currentDomain = self.domainFactory.redirectNotifViewedDomain;
            self.domainFactory.redirectNotifViewedDomain = redirectNotifViewedDomain;
            if (![self.domainFactory.redirectNotifViewedDomain isEqualToString:currentDomain]) {
                shouldRedirect = YES;
                self.domainFactory.redirectNotifViewedDomain = redirectNotifViewedDomain;
                [self.domainFactory persistRedirectNotifViewedDomain];
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
            NSString *currentDomain = self.domainFactory.redirectDomain;
            self.domainFactory.redirectDomain = redirectDomain;
            if (![self.domainFactory.redirectDomain isEqualToString:currentDomain]) {
                shouldRedirect = YES;
                self.domainFactory.redirectDomain = redirectDomain;
                [self.domainFactory persistRedirectDomain];
                //domain changed
                [self onDomainAvailable];
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
        [self.domainFactory clearRedirectDomain];
        self.sendQueueFails = 0;
    }
}


#pragma mark - Queue/Dispatch helpers

- (NSString *)endpointForQueue: (NSMutableArray *)queue {
    if (!self.domainFactory.redirectDomain) return nil;
    NSString *accountId = self.config.accountId;
    NSString *sdkRevision = self.deviceInfo.sdkVersion;
    NSString *endpointDomain;
    if (queue == _notificationsQueue) {
        endpointDomain = self.domainFactory.redirectNotifViewedDomain;
    } else {
        endpointDomain = self.domainFactory.redirectDomain;
    }
    NSString *endpointUrl = [[NSString alloc] initWithFormat:@"https://%@/a1?os=iOS&t=%@&z=%@", endpointDomain, sdkRevision, accountId];
    currentRequestTimestamp = (int) [[[NSDate alloc] init] timeIntervalSince1970];
    endpointUrl = [endpointUrl stringByAppendingFormat:@"&ts=%d", currentRequestTimestamp];
    return endpointUrl;
}

- (NSDictionary *)batchHeaderForQueue:(CTQueueType)queueType {
    NSDictionary *appFields = [self generateAppFields];
    NSMutableDictionary *header = [@{@"type" : @"meta", @"af" : appFields} mutableCopy];
    
    header[@"g"] = self.deviceInfo.deviceId;
    header[@"tk"] = self.config.accountToken;
    header[@"id"] = self.config.accountId;
    
    header[@"ddnd"] = @([self getStoredDeviceToken].length <= 0);
    
    header[@"frs"] = @(self.sessionManager.firstRequestInSession);
    self.sessionManager.firstRequestInSession = NO;
    
    int lastTS = [self getLastRequestTimeStamp];
    header[@"l_ts"] = @(lastTS);
    
    int firstTS = [self getFirstRequestTimestamp];
    header[@"f_ts"] = @(firstTS);
    
    NSArray *registeredURLSchemes = _plistInfo.registeredUrlSchemes;
    if (registeredURLSchemes && [registeredURLSchemes count] > 0) {
        header[@"regURLs"] = registeredURLSchemes;
    }
    
    // Adds debug flag to show errors and events on the dashboard - integration-debugger when dubug level is set to 3
    if ([CleverTap getDebugLevel] >= CleverTapLogDebug){
        header[@"debug"] = @YES;
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
        if (self.sessionManager.source != nil) {
            ref[@"us"] = self.sessionManager.source;
        }
        if (self.sessionManager.medium != nil) {
            ref[@"um"] = self.sessionManager.medium;
        }
        if (self.sessionManager.campaign != nil) {
            ref[@"uc"] = self.sessionManager.campaign;
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
    
    @try {
        NSDictionary *additionalHeaders = [[self delegateManager] notifyAttachToHeaderDelegatesAndCollectKeyPathValues:queueType];
        for (NSString *keyPath in additionalHeaders) {
            if (![header valueForKeyPath:keyPath]) {
                [header setValue:additionalHeaders[keyPath] forKeyPath:keyPath];
            }
        }
    } @catch (NSException *exception) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Failed to attach headers from delegates", self);
    }
    
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
    evtData[CLTAP_APP_VERSION] = self.deviceInfo.appVersion;
    
    evtData[@"Build"] = self.deviceInfo.appBuild;
    
    evtData[CLTAP_SDK_VERSION] = @([self.deviceInfo.sdkVersion integerValue]);
    
    if (self.deviceInfo.model) {
        evtData[@"Model"] = self.deviceInfo.model;
    }
    
    if (CLLocationCoordinate2DIsValid(self.userSetLocation)) {
        evtData[CLTAP_LATITUDE] = @(self.userSetLocation.latitude);
        evtData[CLTAP_LONGITUDE] = @(self.userSetLocation.longitude);
    }
    
    evtData[@"Make"] = self.deviceInfo.manufacturer;
    evtData[CLTAP_OS_VERSION] = self.deviceInfo.osVersion;
    
    if (self.deviceInfo.carrier && ![self.deviceInfo.carrier isEqualToString:@""]) {
        evtData[CLTAP_CARRIER] = self.deviceInfo.carrier;
    }
    
    evtData[@"useIP"] = @(self.enableNetworkInfoReporting);
    if (self.enableNetworkInfoReporting) {
        if (self.deviceInfo.radio != nil) {
            evtData[CLTAP_NETWORK_TYPE] = self.deviceInfo.radio;
        }
        evtData[CLTAP_CONNECTED_TO_WIFI] = @(self.deviceInfo.wifi);
    }
    
    evtData[@"ifaA"] = @NO;
    if (self.deviceInfo.vendorIdentifier) {
        CTLoginInfoProvider *loginInfoProvider = [[CTLoginInfoProvider alloc]initWithDeviceInfo:self.deviceInfo config:self.config];
        NSString *ifvString = [loginInfoProvider deviceIsMultiUser] ?  [NSString stringWithFormat:@"%@%@", kMultiUserPrefix, @"ifv"] : @"ifv";
        if (ifvString) {
            evtData[ifvString] = self.deviceInfo.vendorIdentifier;
        }
    }
    
    if ([CTUIUtils runningInsideAppExtension]) {
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
    
    if (auxiliarySdkVersions && auxiliarySdkVersions.count > 0) {
        [auxiliarySdkVersions enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
            [evtData setObject:value forKey:key];
        }];
    }
    
    if (_locale){
        evtData[@"locale"] = [_locale localeIdentifier];
    }else{
        evtData[@"locale"] = [self.deviceInfo.systemLocale localeIdentifier];
    }
    
    #if CLEVERTAP_SSL_PINNING
        evtData[@"sslpin"] = @YES;
    #endif
    
    NSString *proxyDomain = [self.config.proxyDomain stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (proxyDomain != nil && proxyDomain.length > 0) {
        evtData[@"proxyDomain"] = self.config.proxyDomain;
    }
    
    NSString *spikyProxyDomain = [self.config.spikyProxyDomain stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (spikyProxyDomain != nil && spikyProxyDomain.length > 0) {
        evtData[@"spikyProxyDomain"] = self.config.spikyProxyDomain;
    }
    
    if (self.config.wv_init) {
        evtData[@"wv_init"] = @(YES);
    }
    
    return evtData;
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


#pragma mark - Timestamp bookkeeping helpers

- (void)setLastRequestTimestamp:(double)ts {
    [CTPreferences putInt:ts forKey:kLAST_TS_KEY];
}

- (NSTimeInterval)getLastRequestTimeStamp {
    if (self.config.isDefaultInstance) {
        return [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kLAST_TS_KEY config: self.config] withResetValue:[CTPreferences getIntForKey:kLAST_TS_KEY withResetValue:0]];
    } else {
        return [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kLAST_TS_KEY config: self.config] withResetValue:0];
    }
}

- (void)clearLastRequestTimestamp {
    [CTPreferences putInt:0 forKey:[CTPreferences storageKeyWithSuffix:kLAST_TS_KEY config: self.config]];
}

- (void)setFirstRequestTimestampIfNeeded:(double)ts {
    NSTimeInterval firstRequestTS = [self getFirstRequestTimestamp];
    if (firstRequestTS > 0) return;
    [CTPreferences putInt:ts forKey:[CTPreferences storageKeyWithSuffix:kFIRST_TS_KEY config: self.config]];
}

- (NSTimeInterval)getFirstRequestTimestamp {
    if (self.config.isDefaultInstance) {
        return [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kFIRST_TS_KEY config: self.config] withResetValue:[CTPreferences getIntForKey:kFIRST_TS_KEY withResetValue:0]];
    } else {
        return [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kFIRST_TS_KEY config: self.config] withResetValue:0];
    }
}

- (void)clearFirstRequestTimestamp {
    [CTPreferences putInt:0 forKey:[CTPreferences storageKeyWithSuffix:kFIRST_TS_KEY config: self.config]];
}

- (BOOL)isMuted {
    return [NSDate new].timeIntervalSince1970 - _lastMutedTs < 24 * 60 * 60;
}


#pragma mark - Lifecycle Handling

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
        [self doHandshakeAsyncWithCompletion:nil];
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    if ([self isMuted]) return;
    [self persistOrClearQueues];
}

- (void)_appEnteredForegroundWithLaunchingOptions:(NSDictionary *)launchOptions {
    CleverTapLogInternal(self.config.logLevel, @"%@: appEnteredForeground with options: %@", self, launchOptions);
    if ([CTUIUtils runningInsideAppExtension]) return;
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
        if ([self.deviceInfo.library isEqualToString:@"Leanplum"]) {
            CleverTapLogDebug(self.config.logLevel, @"%@: Leanplum will handle the notification: %@", self, notification);
        } else {
            [self _handlePushNotification:notification];
        }
    }
#endif
}

- (void)_appEnteredForeground {
    if ([CTUIUtils runningInsideAppExtension]) return;
    [self.sessionManager updateSessionStateOnLaunch];
    if (!self.isAppForeground) {
        [self recordAppLaunched:@"appEnteredForeground"];
        [self scheduleQueueFlush];
        CleverTapLogInternal(self.config.logLevel, @"%@: app is in foreground", self);
    }
    self.isAppForeground = YES;
    
#if !CLEVERTAP_NO_INAPP_SUPPORT
    if (!_config.analyticsOnly && ![CTUIUtils runningInsideAppExtension]) {
        [self.inAppFCManager checkUpdateDailyLimits];
    }
#endif
}

- (void)_appEnteredBackground {
    self.isAppForeground = NO;
    
    UIApplication *application = [CTUIUtils getSharedApplication];
    UIBackgroundTaskIdentifier __block backgroundTask;
    
    void (^finishTaskHandler)(void) = ^(){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [application endBackgroundTask:backgroundTask];
            backgroundTask = UIBackgroundTaskInvalid;
        });
    };
    // Start background task to make sure it runs when the app is in background.
    backgroundTask = [application beginBackgroundTaskWithExpirationHandler:finishTaskHandler];
    
    @try {
        [self.dispatchQueueManager runSerialAsync:^{
            if (![self isMuted]) {
                [self persistOrClearQueues];
            }
            [self.sessionManager updateSessionTime:(long) [[NSDate date] timeIntervalSince1970]];
            finishTaskHandler();
        }];
    }
    @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Exception caught: %@", self, [exception reason]);
        finishTaskHandler();
    }
}

- (void)recordAppLaunched:(NSString *)caller {
    
    if ([CTUIUtils runningInsideAppExtension]) return;
    
    if (self.sessionManager.appLaunchProcessed) {
        CleverTapLogInternal(self.config.logLevel, @"%@: App Launched already processed", self);
        return;
    }
    
    // Load Vars from cache before App Launched
    [self.variables.varCache loadDiffs];
    
    self.sessionManager.appLaunchProcessed = YES;
    
    if (self.config.disableAppLaunchedEvent) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Dropping App Launched event - reporting disabled in instance configuration", self);
        return;
    }
    
    CleverTapLogInternal(self.config.logLevel, @"%@: recording App Launched event from: %@", self, caller);
    
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    event[CLTAP_EVENT_NAME] = CLTAP_APP_LAUNCHED_EVENT;
    event[CLTAP_EVENT_DATA] = [self generateAppFields];
    
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
    if ([CTUIUtils runningInsideAppExtension]) return;
    NSDate *d = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"d"];
    
    if ([CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:CLTAP_PREFS_LAST_DAILY_PUSHED_EVENTS_DATE config: self.config] withResetValue:0] != [[dateFormatter stringFromDate:d] intValue]) {
        CleverTapLogInternal(self.config.logLevel, @"%@: queuing daily events", self);
        [self _pushBaseProfile];
        if (!self.pushedAPNSId) {
            [self pushDeviceTokenWithAction:CleverTapPushTokenRegister];
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@: Skipped push of the APNS ID, already sent.", self);
        }
    }
    [CTPreferences putInt:[[dateFormatter stringFromDate:d] intValue] forKey:[CTPreferences storageKeyWithSuffix:CLTAP_PREFS_LAST_DAILY_PUSHED_EVENTS_DATE config: self.config]];
}


#pragma mark - Notifications Private

- (void)pushDeviceTokenWithAction:(CleverTapPushTokenRegistrationAction)action {
    if ([CTUIUtils runningInsideAppExtension]) return;
    NSString *token = [self getStoredDeviceToken];
    if (token != nil && ![token isEqualToString:@""])
        [self pushDeviceToken:token forRegisterAction:action];
}

- (void)pushDeviceToken:(NSString *)deviceToken forRegisterAction:(CleverTapPushTokenRegistrationAction)action {
    if ([CTUIUtils runningInsideAppExtension]) return;
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
    if ([CTUIUtils runningInsideAppExtension]) return;
    
    if (!object) return;
    
#if !defined(CLEVERTAP_TVOS)
    NSDictionary *notification = [self getNotificationDictionary:object];
    
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
    
    // check to see whether the push includes a test in-app notification, test inbox message or test display unit, if so don't process further
    if ([self _checkAndHandleTestPushPayload:notification]) return;
    
    // notify application with push notification custom extras
    [self _notifyPushNotificationTapped:notification];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // determine application state
        UIApplication *application = [CTUIUtils getSharedApplication];
        if (application != nil) {
            BOOL inForeground = !(application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground);
            
            // should we open a deep link ?
            // if the app is in foreground and force flag is off, then don't fire any deep link
            if (self.urlDelegate && [self.urlDelegate respondsToSelector: @selector(shouldHandleCleverTapURL: forChannel:)]) {
                NSURL *url = [self urlForNotification: notification];
                if (url && [self.urlDelegate shouldHandleCleverTapURL: url forChannel: CleverTapPushNotification]) {
                    [self _checkAndFireDeepLinkForNotification: notification];
                }
            } else if (inForeground && !openInForeground) {
                CleverTapLogDebug(self.config.logLevel, @"%@: app in foreground and openInForeground flag is FALSE, will not process any deep link for notification: %@", self, notification);
            } else {
                [self _checkAndFireDeepLinkForNotification:notification];
            }
            
            [self.dispatchQueueManager runSerialAsync:^{
                [CTEventBuilder buildPushNotificationEvent:YES forNotification:notification completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
                    if (event) {
                        self.wzrkParams = [event[CLTAP_EVENT_DATA] copy];
                        [self queueEvent:event withType:CleverTapEventTypeRaised];
                    };
                    if (errors) {
                        [self.validationResultStack pushValidationResults:errors];
                    }
                }];
            }];
        }
    });
#endif
}

#if !defined(CLEVERTAP_TVOS)
- (BOOL)_checkAndHandleTestPushPayload:(NSDictionary *)notification {
    if (notification[@"wzrk_inapp"] || notification[@"wzrk_inbox"] || notification[@"wzrk_adunit"]) {
        // remove unknown json attributes
        NSMutableDictionary *testPayload = [NSMutableDictionary new];
        for (NSString *key in [notification allKeys]) {
            if ([CTUtils doesString:key startWith:CLTAP_NOTIFICATION_TAG] || [CTUtils doesString:key startWith:CLTAP_NOTIFICATION_TAG_SECONDARY]) {
                testPayload[key] = notification[key];
            }
        }
#if !CLEVERTAP_NO_INAPP_SUPPORT
        if ([self.inAppDisplayManager didHandleInAppTestFromPushNotificaton:testPayload]) {
            return YES;
        }
#endif
#if !CLEVERTAP_NO_INBOX_SUPPORT
        if ([self didHandleInboxMessageTestFromPushNotificaton:testPayload]) {
            return YES;
        }
#endif
        if ([self didHandleDisplayUnitTestFromPushNotificaton:testPayload]) {
            return YES;
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: unable to handle test payload in the push notification: %@", self, notification);
            return NO;
        }
    }
    return NO;
}
#endif

- (void)_notifyPushNotificationTapped:(NSDictionary *)notification {
    if (self.pushNotificationDelegate && [self.pushNotificationDelegate respondsToSelector:@selector(pushNotificationTappedWithCustomExtras:)]) {
        NSMutableDictionary *mutableNotification = [NSMutableDictionary dictionaryWithDictionary:notification];
        [mutableNotification removeObjectForKey:@"aps"];
        [self.pushNotificationDelegate pushNotificationTappedWithCustomExtras:mutableNotification];
    }
}

- (NSURL*)urlForNotification:(NSDictionary *)notification {
    NSString *dl = (NSString *) notification[@"wzrk_dl"];
    if (dl) {
        return [NSURL URLWithString:dl];
    }
    return nil;
}

- (void)_checkAndFireDeepLinkForNotification:(NSDictionary *)notification {
    UIApplication *application = [CTUIUtils getSharedApplication];
    if (application != nil) {
        @try {
            __block NSURL *dlURL = [self urlForNotification: notification];
            if (dlURL) {
                [CTUtils runSyncMainQueue:^{
                    CleverTapLogDebug(self.config.logLevel, @"%@: Firing deep link: %@", self, dlURL.absoluteString);
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
    [self.sessionManager setSource:referrer[@"us"]];
    [self.sessionManager setMedium:referrer[@"um"]];
    [self.sessionManager setCampaign:referrer[@"uc"]];
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

#if !(TARGET_OS_TV)
/// Get notification dictionary object from id object to normalize the notification data
/// @param object notification, data or notification userInfo dictionary
- (NSDictionary *)getNotificationDictionary:(id)object {
    NSDictionary *notification;
    
    if (@available(iOS 10.0, tvOS 10.0, *)) {
        if ([object isKindOfClass:[UNNotification class]]) {
            notification = ((UNNotification *) object).request.content.userInfo;
        } else if ([object isKindOfClass:[NSDictionary class]]) {
            notification = object;
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    else if ([object isKindOfClass:[UILocalNotification class]]) {
        notification = [((UILocalNotification *) object) userInfo];
    }
#pragma clang diagnostic pop
    else if ([object isKindOfClass:[NSDictionary class]]) {
        notification = object;
    }
    return notification;
}
#endif

#pragma mark - InApp Notifications

#pragma mark Public Method
#if !CLEVERTAP_NO_INAPP_SUPPORT
- (void)showInAppNotificationIfAny {
    [self.inAppDisplayManager _showInAppNotificationIfAny];
}

- (void)suspendInAppNotifications {
    [self.inAppDisplayManager _suspendInAppNotifications];
}

- (void)discardInAppNotifications {
    [self.inAppDisplayManager _discardInAppNotifications];
}

- (void)resumeInAppNotifications {
    [self.inAppDisplayManager _resumeInAppNotifications];
    [self.inAppDisplayManager _showInAppNotificationIfAny];
}

- (void)clearInAppResources:(BOOL)expiredOnly {
    [self.fileDownloader clearFileAssets:expiredOnly];
}

+ (void)registerCustomInAppTemplates:(id<CTTemplateProducer> _Nonnull)producer {
    [CTCustomTemplatesManager registerTemplateProducer:producer];
}

- (CTTemplateContext * _Nullable)activeContextForTemplate:(NSString * _Nonnull)templateName {
    return [[self customTemplatesManager] activeContextForTemplate:templateName];
}

#endif

#pragma mark Private Method

- (void)recordInAppNotificationStateEvent:(BOOL)clicked
                          forNotification:(CTInAppNotification *)notification andQueryParameters:(NSDictionary *)params {
    [self.dispatchQueueManager runSerialAsync:^{
        [CTEventBuilder buildInAppNotificationStateEvent:clicked forNotification:notification andQueryParameters:params completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
            if (event) {
                if (clicked) {
                    self.wzrkParams = [event[CLTAP_EVENT_DATA] copy];
                }
                [self queueEvent:event withType:CleverTapEventTypeRaised];
            };
            if (errors) {
                [self.validationResultStack pushValidationResults:errors];
            }
        }];
    }];
}

- (void)openURL:(NSURL *)ctaURL forModule:(NSString *)module {
    UIApplication *sharedApplication = [CTUIUtils getSharedApplication];
    if (sharedApplication == nil) {
        return;
    }
    CleverTapLogDebug(self.config.logLevel, @"%@: %@: firing deep link: %@", module, self, ctaURL);
    id dlURL;
    if (@available(iOS 10.0, *)) {
        if ([sharedApplication respondsToSelector:@selector(openURL:options:completionHandler:)]) {
            NSMethodSignature *signature = [UIApplication
                                            instanceMethodSignatureForSelector:@selector(openURL:options:completionHandler:)];
            NSInvocation *invocation = [NSInvocation
                                        invocationWithMethodSignature:signature];
            [invocation setTarget:sharedApplication];
            [invocation setSelector:@selector(openURL:options:completionHandler:)];
            NSDictionary *options = @{};
            id completionHandler = nil;
            dlURL = ctaURL;
            [invocation setArgument:&dlURL atIndex:2];
            [invocation setArgument:&options atIndex:3];
            [invocation setArgument:&completionHandler atIndex:4];
            [invocation invoke];
        } else {
            if ([sharedApplication respondsToSelector:@selector(openURL:)]) {
                [sharedApplication performSelector:@selector(openURL:) withObject:ctaURL];
            }
        }
    } else {
        if ([sharedApplication respondsToSelector:@selector(openURL:)]) {
            [sharedApplication performSelector:@selector(openURL:) withObject:ctaURL];
        }
    }
}

# pragma mark - Event Helpers

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
        [self.validationResultStack pushValidationResult:error];
    }
}


# pragma mark - Additional Request Parameters(ARP) and I/J handling

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

- (void)processDiscardedEventsRequest:(NSDictionary *)arp {
    if (!arp) return;
    
    if (!arp[CLTAP_DISCARDED_EVENT_JSON_KEY]) {
        CleverTapLogInternal(self.config.logLevel, @"%@: ARP doesn't contain the Discarded Events key.", self);
        return;
    }
    
    if (![arp[CLTAP_DISCARDED_EVENT_JSON_KEY] isKindOfClass:[NSArray class]]) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Error parsing discarded events: %@", self, arp);
        return;
    }
    
    NSArray *discardedEvents = arp[CLTAP_DISCARDED_EVENT_JSON_KEY];
    if (discardedEvents && discardedEvents.count > 0) {
        @try {
            [CTValidator setDiscardedEvents:discardedEvents];
        } @catch (NSException *e) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Error parsing discarded events list: %@", self, e.debugDescription);
        }
    }
}

- (NSString *)arpKey {
    NSString *accountId = self.config.accountId;
    NSString *guid = self.deviceInfo.deviceId;
    if (accountId == nil || guid == nil) {
        return nil;
    }
    return [NSString stringWithFormat:@"arp:%@:%@", accountId, guid];
}

- (NSDictionary *)getARP {
    [self migrateARPKeysForLocalStorage];
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
    [self processDiscardedEventsRequest:update];
    [self.productConfig updateProductConfigWithOptions:[self _setProductConfig:arp]];
}

- (void)migrateARPKeysForLocalStorage {
    //Fetch latest key which is updated in the new method we are using the old key structure below
    NSString *accountId = self.config.accountId;
    if (accountId == nil) {
        return;
    }
    NSString *key = [NSString stringWithFormat:@"arp:%@", accountId];
    NSDictionary *arp = [CTPreferences getObjectForKey:key];
    
    //Set ARP value in new key and delete the value for old key
    if (arp != nil) {
        [self saveARP:arp];
        [CTPreferences removeObjectForKey:key];
    }
}

- (long)getI {
    return [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kI_KEY config: self.config] withResetValue:0];
}

- (void)saveI:(NSNumber *)i {
    [CTPreferences putInt:[i longValue] forKey:[CTPreferences storageKeyWithSuffix:kI_KEY config: self.config]];
}

- (void)clearI {
    [CTPreferences removeObjectForKey:[CTPreferences storageKeyWithSuffix:kI_KEY config: self.config]];
}

- (long)getJ {
    return [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kJ_KEY config: self.config] withResetValue:0];
}

- (void)saveJ:(NSNumber *)j {
    [CTPreferences putInt:[j longValue] forKey:[CTPreferences storageKeyWithSuffix:kJ_KEY config: self.config]];
}

- (void)clearJ {
    [CTPreferences removeObjectForKey:[CTPreferences storageKeyWithSuffix:kJ_KEY config: self.config]];
}

- (void)clearUserContext {
    [self clearI];
    [self clearJ];
    [self clearLastRequestTimestamp];
    [self clearFirstRequestTimestamp];
}

#pragma mark - Queues/Persistence/Dispatch Handling

- (BOOL)shouldDeferProcessingEvent: (NSDictionary *)event withType:(CleverTapEventType)type {
    
    if (self.config.isCreatedPostAppLaunched){
        return NO;
    }
    
    return (type == CleverTapEventTypeRaised && !self.sessionManager.appLaunchProcessed);
}

- (BOOL)_shouldDropEvent:(NSDictionary *)event withType:(CleverTapEventType)type {
    
    if (type == CleverTapEventTypeFetch) {
        return NO;
    }
    
    if (self.currentUserOptedOut) {
        CleverTapLogDebug(self.config.logLevel, @"%@: User: %@ has opted out of sending events, dropping event: %@", self, self.deviceInfo.deviceId, event);
        return YES;
    }
    
    if ([self isMuted]) {
        CleverTapLogDebug(self.config.logLevel, @"%@: is muted, dropping event: %@", self, event);
        return YES;
    }
    
    return NO;
}

- (void)queueEvent:(NSDictionary *)event withType:(CleverTapEventType)type {
    if ([self _shouldDropEvent:event withType:type]) {
        return;
    }
    
    // make sure App Launched is processed first
    // if not defer this one; push back on the queue
    if ([self shouldDeferProcessingEvent:event withType:type]) {
        CleverTapLogDebug(self.config.logLevel, @"%@: App Launched not yet processed re-queueing: %@, %lu", self, event, (long)type);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self.dispatchQueueManager runSerialAsync:^{
                [self queueEvent:event withType:type];
            }];
        });
        return;
    }
    
    if (type == CleverTapEventTypeFetch) {
        [self.dispatchQueueManager runSerialAsync:^{
            [self processEvent:event withType:type];
        }];
    } else {
        [self.sessionManager createSessionIfNeeded];
        [self pushInitialEventsIfNeeded];
        [self.dispatchQueueManager runSerialAsync:^{
            [self.sessionManager updateSessionTime:(long) [[NSDate date] timeIntervalSince1970]];
            [self processEvent:event withType:type];
        }];
    }
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
        if ([self.eventsQueue count] >= 50 && (eventType == CleverTapEventTypePing || eventType == CleverTapEventTypeFetch)) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Events queue not draining, ignoring ping and fetch events", self);
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
        } else if (eventType == CleverTapEventTypeProfile) {
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
        mutableEvent[@"s"] = @(self.sessionManager.sessionId);
        int screenCount = self.sessionManager.screenCount == 0 ? 1 : self.sessionManager.screenCount;
        mutableEvent[@"pg"] = @(screenCount);
        mutableEvent[@"lsl"] = @(self.sessionManager.lastSessionLengthSeconds);
        mutableEvent[@"f"] = @(self.sessionManager.firstSession);
        mutableEvent[@"n"] = self.currentViewControllerName ? self.currentViewControllerName : @"_bg";
        
        if (eventType == CleverTapEventTypePing && _geofenceLocation) {
            mutableEvent[@"gf"] = @(_geofenceLocation);
            mutableEvent[@"gfSDKVersion"] = _gfSDKVersion;
            _geofenceLocation = NO;
        }
        
        // Report any pending validation error
        CTValidationResult *vr = [self.validationResultStack popValidationResult];
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
        
        CleverTapLogDebug(self.config.logLevel, @"%@: New event processed: %@", self, [CTUtils jsonObjectToString:mutableEvent]);
        
#if !CLEVERTAP_NO_INAPP_SUPPORT
        // Evaluate the event only if it will be processed
        [self.dispatchQueueManager runSerialAsync:^{
            [self evaluateOnEvent:event withType: eventType];
        }];
#endif
        
        if (eventType == CleverTapEventTypeFetch) {
            [self flushQueue];
        } else {
            [self scheduleQueueFlush];
        }
        
    } @catch (NSException *e) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Processing event failed with a exception: %@", self, e.debugDescription);
    }
}

- (void)evaluateOnEvent:(NSDictionary *)event withType:(CleverTapEventType)eventType {
#if !CLEVERTAP_NO_INAPP_SUPPORT
    NSString *eventName = event[CLTAP_EVENT_NAME];
    // Add the system properties for evaluation
    NSMutableDictionary *eventData = [[NSMutableDictionary alloc] initWithDictionary:[self generateAppFields]];
    // Add the event properties last, so custom properties are not overriden
    [eventData addEntriesFromDictionary:event[CLTAP_EVENT_DATA]];
    if (eventName && [eventName isEqualToString:CLTAP_CHARGED_EVENT]) {
        NSArray *items = eventData[CLTAP_CHARGED_EVENT_ITEMS];
        [self.inAppEvaluationManager evaluateOnChargedEvent:eventData andItems:items];
    } else if (eventType == CleverTapEventTypeProfile) {
        NSDictionary<NSString *, NSDictionary<NSString *, id> *> *result = [self.localDataStore getUserAttributeChangeProperties:event];
        [self.inAppEvaluationManager evaluateOnUserAttributeChange:result];
    } else if (eventName) {
        [self.inAppEvaluationManager evaluateOnEvent:eventName withProps:eventData];
    }
#endif
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
        [self.dispatchQueueManager runSerialAsync:^{
            [self doHandshakeAsyncWithCompletion:nil];
        }];
    }
    [self.dispatchQueueManager runSerialAsync:^{
        if ([self isMuted]) {
            [self clearQueues];
        } else {
            [self sendQueues];
        }
    }];
}

- (void)clearQueue {
    [self.dispatchQueueManager runSerialAsync:^{
        [self sendQueues];
        [self clearQueues];
    }];
}

- (void)sendQueues {
    if ([self isMuted] || _offline) return;
    [self sendQueue:_profileQueue ofType:CTQueueTypeProfile];
    [self sendQueue:_eventsQueue ofType:CTQueueTypeEvents];
    [self sendQueue:_notificationsQueue ofType:CTQueueTypeNotifications];
}

- (void)inflateQueuesAsync {
    [self.dispatchQueueManager runSerialAsync:^{
        [self inflateProfileQueue];
        [self inflateEventsQueue];
        [self inflateNotificationsQueue];
    }];
}

- (void)inflateEventsQueue {
    self.eventsQueue = (NSMutableArray *)[CTPreferences unarchiveFromFile:[self eventsFileName] ofType:[NSMutableArray class] removeFile:YES];
    if (!self.eventsQueue || [self isMuted]) {
        self.eventsQueue = [NSMutableArray array];
    }
}

- (void)inflateProfileQueue {
    self.profileQueue = (NSMutableArray *)[CTPreferences unarchiveFromFile:[self profileEventsFileName] ofType:[NSMutableArray class] removeFile:YES];
    if (!self.profileQueue || [self isMuted]) {
        self.profileQueue = [NSMutableArray array];
    }
}

- (void)inflateNotificationsQueue {
    self.notificationsQueue = (NSMutableArray *)[CTPreferences unarchiveFromFile:[self notificationsFileName] ofType:[NSMutableArray class] removeFile:YES];
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
    self.eventsQueue = (NSMutableArray *)[CTPreferences unarchiveFromFile:[self eventsFileName] ofType:[NSMutableArray class] removeFile:YES];
    self.eventsQueue = [NSMutableArray array];
}

- (void)clearProfileQueue {
    self.profileQueue = (NSMutableArray *)[CTPreferences unarchiveFromFile:[self profileEventsFileName] ofType:[NSMutableArray class] removeFile:YES];
    self.profileQueue = [NSMutableArray array];
}

- (void)clearNotificationsQueue {
    self.notificationsQueue = (NSMutableArray *)[CTPreferences unarchiveFromFile:[self notificationsFileName] ofType:[NSMutableArray class] removeFile:YES];
    self.notificationsQueue = [NSMutableArray array];
}

- (void)persistOrClearQueues {
    if ([self isMuted]) {
        [self clearQueues];
    } else {
        [self persistProfileQueue];
        [self persistEventsQueue];
        [self persistNotificationsQueue];
    }
}

- (void)persistEventsQueue {
    NSString *fileName = [self eventsFileName];
    NSMutableArray *eventsCopy;
    @synchronized (self) {
        eventsCopy = [NSMutableArray arrayWithArray:[self.eventsQueue copy]];
    }
    [CTPreferences archiveObject:eventsCopy forFileName:fileName config:_config];
}

- (void)persistProfileQueue {
    NSString *fileName = [self profileEventsFileName];
    NSMutableArray *profileEventsCopy;
    @synchronized (self) {
        profileEventsCopy = [NSMutableArray arrayWithArray:[self.profileQueue copy]];
    }
    [CTPreferences archiveObject:profileEventsCopy forFileName:fileName config:_config];
}

- (void)persistNotificationsQueue {
    NSString *fileName = [self notificationsFileName];
    NSMutableArray *notificationsCopy;
    @synchronized (self) {
        notificationsCopy = [NSMutableArray arrayWithArray:[self.notificationsQueue copy]];
    }
    [CTPreferences archiveObject:notificationsCopy forFileName:fileName config:_config];
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

# pragma mark - Request/Response handling

- (void)sendQueue:(NSMutableArray *)queue ofType:(CTQueueType)queueType {
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
    
    NSDictionary *header = [self batchHeaderForQueue:queueType];
    
    int originalCount = (int) [queue count];
    float numBatches = (float) ceil((float) originalCount / kMaxBatchSize);
    CleverTapLogDebug(self.config.logLevel, @"%@: Pending events to be sent: %d in %d batches", self, originalCount, (int) numBatches);
    
    while ([queue count] > 0) {
        NSUInteger batchSize = ([queue count] > kMaxBatchSize) ? kMaxBatchSize : [queue count];
        NSArray *batch = [queue subarrayWithRange:NSMakeRange(0, batchSize)];
        NSArray *batchWithHeader = [self insertHeader:header inBatch:batch];
        
        CleverTapLogInternal(self.config.logLevel, @"%@: Pending events batch contains: %d items", self, (int) [batch count]);
        
        @try {
            NSString *jsonBody = [CTUtils jsonObjectToString:batchWithHeader];
            
            CleverTapLogDebug(self.config.logLevel, @"%@: Sending %@ to servers at %@", self, jsonBody, endpoint);
            
            // update endpoint for current timestamp
            endpoint = [self endpointForQueue:queue];
            if (endpoint == nil) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Endpoint is not set, won't send queue", self);
                return;
            }
            
            __block BOOL success = NO;
            __block NSData *responseData;
            
            __block BOOL redirect = NO;
            
            // Need to simulate a synchronous request
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            
            CTRequest *ctRequest = [CTRequestFactory eventRequestWithConfig:self.config params:batchWithHeader url:endpoint];
            [ctRequest onResponse:^(NSData * _Nullable data, NSURLResponse * _Nullable response) {
                responseData = data;
                
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
            [ctRequest onError:^(NSError * _Nullable error) {
                if (error) {
                    CleverTapLogDebug(self.config.logLevel, @"%@: Network error while sending queue, will retry: %@", self, error.localizedDescription);
                }
                [[self variables] handleVariablesError];
#if !CLEVERTAP_NO_INAPP_SUPPORT
                [self triggerFetchInApps:NO];
#endif
                
                dispatch_semaphore_signal(semaphore);
            }];
            [self.requestSender send:ctRequest];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            
            if (!success) {
                [self scheduleQueueFlush];
                [self handleSendQueueFail];
                
                [self.delegateManager notifyDelegatesBatchDidSend:batchWithHeader withSuccess:NO withQueueType:queueType];
            }
            
            if (!success || redirect) {
                // error so return without removing events from the queue or parsing the response
                // Note: in an APP Extension we don't persist any unsent queues
                return;
            }
            
            [queue removeObjectsInArray:batch];
            
            [self parseResponse:responseData];
            
            [self.delegateManager notifyDelegatesBatchDidSend:batchWithHeader withSuccess:YES withQueueType:queueType];

            CleverTapLogDebug(self.config.logLevel,@"%@: Successfully sent %lu events", self, (unsigned long)[batch count]);
            
        } @catch (NSException *e) {
            CleverTapLogDebug(self.config.logLevel, @"%@: An error occurred while sending the queue: %@", self, e.debugDescription);
            break;
        }
    }
}

#pragma mark Response Handling

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
                [self handleInAppResponse:jsonResp];
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
                                [self.dispatchQueueManager runSerialAsync:^{
                                    NSArray <NSDictionary*> *messages =  [inboxNotifs mutableCopy];;
                                    [self.inboxController updateMessages:messages];
                                }];
                            }
                        }];
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
                                NSArray <NSDictionary*> *displayUnits = [displayUnitNotifs mutableCopy];
                                [self.displayUnitController updateDisplayUnits:displayUnits];
                            }
                        }];
                    }
                }
#endif
                NSDictionary *featureFlagsJSON = jsonResp[CLTAP_FEATURE_FLAGS_JSON_RESPONSE_KEY];
                if (featureFlagsJSON) {
                    NSMutableArray *featureFlagsNotifs;
                    @try {
                        featureFlagsNotifs = [[NSMutableArray alloc] initWithArray:featureFlagsJSON[@"kv"]];
                    } @catch (NSException *e) {
                        CleverTapLogInternal(self.config.logLevel, @"%@: Error parsing Feature Flags JSON: %@", self, e.debugDescription);
                    }
                    if (featureFlagsNotifs && self.featureFlagsController) {
                        NSArray <NSDictionary*> *featureFlags =  [featureFlagsNotifs mutableCopy];
                        [self.featureFlagsController updateFeatureFlags:featureFlags];
                    }
                }
                
                NSDictionary *productConfigJSON = jsonResp[CLTAP_PRODUCT_CONFIG_JSON_RESPONSE_KEY];
                if (productConfigJSON) {
                    NSMutableArray *productConfigNotifs;
                    @try {
                        productConfigNotifs = [[NSMutableArray alloc] initWithArray:productConfigJSON[@"kv"]];
                    } @catch (NSException *e) {
                        CleverTapLogInternal(self.config.logLevel, @"%@: Error parsing Product Config JSON: %@", self, e.debugDescription);
                    }
                    if (productConfigNotifs && self.productConfigController) {
                        NSArray <NSDictionary*> *productConfig =  [productConfigNotifs mutableCopy];
                        [self.productConfigController updateProductConfig:productConfig];
                        NSString *lastFetchTs = productConfigJSON[@"ts"];
                        [self.productConfig updateProductConfigWithLastFetchTs:(long) [lastFetchTs longLongValue]];
                    }
                }
                
#if !CLEVERTAP_NO_GEOFENCE_SUPPORT
                NSArray *geofencesJSON = jsonResp[CLTAP_GEOFENCES_JSON_RESPONSE_KEY];
                if (geofencesJSON) {
                    NSMutableArray *geofencesList;
                    @try {
                        geofencesList = [[NSMutableArray alloc] initWithArray:geofencesJSON];
                    } @catch (NSException *e) {
                        CleverTapLogInternal(self.config.logLevel, @"%@: Error parsing Geofences JSON: %@", self, e.debugDescription);
                    }
                    if (geofencesList) {
                        NSMutableDictionary *geofencesDict = [NSMutableDictionary new];
                        geofencesDict[@"geofences"] = geofencesList;
                        [CTUtils runSyncMainQueue: ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:CleverTapGeofencesDidUpdateNotification object:nil userInfo:geofencesDict];
                        }];
                    }
                }
#endif
                
                // Handle and Cache PE Variables
                NSDictionary *varsResponse = jsonResp[CLTAP_PE_VARS_RESPONSE_KEY];
                if (varsResponse) {
                    [[self variables] handleVariablesResponse: jsonResp[CLTAP_PE_VARS_RESPONSE_KEY]];
                }
                
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
    
    id<CTIdentityRepo> identityRepo = [CTIdentityRepoFactory getRepoForConfig:_config deviceInfo:_deviceInfo validationResultStack:_validationResultStack];
    
    // cache identifier:guid pairs
    for (NSString *key in profileEvent) {
        @try {
            if ([identityRepo isIdentity:key]) {
                NSString *identifier = [NSString stringWithFormat:@"%@", profileEvent[key]];
                CTLoginInfoProvider *loginInfoProvider = [[CTLoginInfoProvider alloc]initWithDeviceInfo:self.deviceInfo config:self.config];
                [loginInfoProvider cacheGUID:nil forKey:key andIdentifier:identifier];
            }
        } @catch (NSException *e) {
            // no-op
        }
    }
}

- (NSArray *)getConfigIdentifiers {
    // IF DEFAULT INSTANCE, GET KEYS FROM PLIST, ELSE GET FROM SETTER
    if (self.config.isDefaultInstance) {
        // ONLY ADD SUPPORTED KEYS
        NSArray *clevertapIdentifiers = [[NSBundle mainBundle].infoDictionary objectForKey:@"CleverTapIdentifiers"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self IN %@", CLTAP_ALL_PROFILE_IDENTIFIER_KEYS];
        NSArray *result = [clevertapIdentifiers filteredArrayUsingPredicate:predicate];
        return result;
    }
    else {
        return self.config.identityKeys;
    }
}

- (BOOL)isProcessingLoginUserWithIdentifier:(NSString *)identifier {
    return identifier == nil ? NO : [self.processingLoginUserIdentifier isEqualToString:identifier];
}

- (void)_onUserLogin:(NSDictionary *)properties withCleverTapID:(NSString *)cleverTapID {
    
    // GET IDENTIFIER KEYS FROM CACHE, PLIST OR CONFIG
    if (!properties) return;
    NSString *currentGUID = [self profileGetCleverTapID];
    if (!currentGUID) return;
    
    NSString *cachedGUID;
    BOOL haveIdentifier = NO;
    CTLoginInfoProvider *loginInfoProvider = [[CTLoginInfoProvider alloc]initWithDeviceInfo:self.deviceInfo config:self.config];
    
    // check for valid identifier keys
    // use the first one we find
    id<CTIdentityRepo> identityRepo = [CTIdentityRepoFactory getRepoForConfig:_config deviceInfo:_deviceInfo validationResultStack:_validationResultStack];
    for (NSString *key in properties) {
        @try {
            if ([identityRepo isIdentity:key]) {
                NSString *identifier = [NSString stringWithFormat:@"%@", properties[key]];
                
                if (identifier && [identifier length] > 0) {
                    haveIdentifier = YES;
                    cachedGUID = [loginInfoProvider getGUIDforKey:key andIdentifier:identifier];
                    if (cachedGUID) break;
                }
            }
        } @catch (NSException *e) {
            // no-op
        }
    }
    
    // if no identifier provided or there are no identified users on the device; just push on the current profile
    if (![self.deviceInfo isErrorDeviceID]) {
        if (!haveIdentifier || [loginInfoProvider isAnonymousDevice]) {
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
    NSString *profileToString = [properties toJsonString];
    
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
    
    [self.dispatchQueueManager runSerialAsync:^{
        CleverTapLogDebug(self.config.logLevel, @"%@: async switching user with properties:  %@", action, properties);
        
        // set OptOut to false for the old user
        self.currentUserOptedOut = NO;
        
        // unregister the push token on the current user
        [self pushDeviceTokenWithAction:CleverTapPushTokenUnregister];
        
        // clear any events in the queue
        [self clearQueue];
        
        // clear ARP and other context for the old user
        [self clearUserContext];
        
        [self.sessionManager resetSession];
        
        if (cachedGUID) {
            [self.deviceInfo forceUpdateDeviceID:cachedGUID];
        } else if (self.config.useCustomCleverTapId){
            [self.deviceInfo forceUpdateCustomDeviceID:cleverTapID];
        } else {
            [self.deviceInfo forceNewDeviceID];
        }
        
        // clear old profile data
        [self.localDataStore changeUser];
        
        [self recordDeviceErrors];
        [[self delegateManager] notifyDelegatesDeviceIdDidChange:self.deviceInfo.deviceId];
        
        [self _setCurrentUserOptOutStateFromStorage];  // be sure to do this AFTER updating the GUID
        
#if !CLEVERTAP_NO_INBOX_SUPPORT
        [self _resetInbox];
#endif
        
#if !CLEVERTAP_NO_DISPLAY_UNIT_SUPPORT
        [self _resetDisplayUnit];
#endif
        
        [self _resetFeatureFlags];
        
        [self _resetProductConfig];
        
        [self _resetVars];
        
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
    [self.dispatchQueueManager runSerialAsync:^{
        NSMutableDictionary *profile = [[self.localDataStore generateBaseProfile] mutableCopy];
        NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
        event[@"profile"] = profile;
        [self queueEvent:event withType:CleverTapEventTypeProfile];
    }];
}

#pragma mark - Public

#pragma mark Public API's For Multi Instance Implementations

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
    if ([CTUIUtils runningInsideAppExtension]){
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


#pragma mark - Profile/Event/Session APIs

- (void)notifyApplicationLaunchedWithOptions:launchOptions {
    if ([CTUIUtils runningInsideAppExtension]) {
        CleverTapLogDebug(self.config.logLevel, @"%@: notifyApplicationLaunchedWithOptions is a no-op in an app extension.", self);
        return;
    }
    CleverTapLogInternal(self.config.logLevel, @"%@: Application launched with options: %@", self, launchOptions);
    [self _appEnteredForegroundWithLaunchingOptions:launchOptions];
}


#pragma mark - Device Network Info Reporting Handling
// public
- (void)enableDeviceNetworkInfoReporting:(BOOL)enabled {
    self.enableNetworkInfoReporting = enabled;
    [CTPreferences putInt:enabled forKey:[CTPreferences storageKeyWithSuffix:kNetworkInfoReportingKey config: self.config]];
}

// private
- (void)_setDeviceNetworkInfoReportingFromStorage {
    BOOL enabled = NO;
    if (self.config.isDefaultInstance) {
        enabled = (BOOL) [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kNetworkInfoReportingKey config: self.config] withResetValue:[CTPreferences getIntForKey:kNetworkInfoReportingKey withResetValue:NO]];
    } else {
        enabled = (BOOL) [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kNetworkInfoReportingKey config: self.config] withResetValue:NO];
    }
    CleverTapLogInternal(self.config.logLevel, @"%@: Setting device network info reporting state from storage to: %@", self, enabled ? @"YES" : @"NO");
    [self enableDeviceNetworkInfoReporting:enabled];
}


#pragma mark - Profile API

- (void)setOptOut:(BOOL)enabled {
    [self.dispatchQueueManager runSerialAsync:^ {
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
    [self.dispatchQueueManager runSerialAsync:^{
        [CTProfileBuilder build:properties completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray<CTValidationResult*>*errors) {
            NSMutableDictionary *profile = [[self.localDataStore generateBaseProfile] mutableCopy];
            if (systemFields) {
                [profile addEntriesFromDictionary:systemFields];
            }
            if (customFields) {
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
                            [self.validationResultStack pushValidationResult:error];
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
                [self.validationResultStack pushValidationResults:errors];
            }
        }];
    }];
}

- (NSString *)profileGetCleverTapID {
    return self.deviceInfo.deviceId;
}

- (id)profileGetLocalValues:(NSString *)propertyName {
    return [self.localDataStore getProfileFieldForKey:propertyName];
}

- (NSString *)getAccountID {
    return self.config.accountId;
}

- (NSString *)profileGetCleverTapAttributionIdentifier {
    return self.deviceInfo.deviceId;
}

- (id)getProperty:(NSString *)propertyName {
    return [self profileGet:propertyName];
}

- (id)profileGet:(NSString *)propertyName {
    if (!self.config.enablePersonalization) {
        return nil;
    }
    return [self.localDataStore getProfileFieldForKey:propertyName];
}

- (void)profileRemoveValueForKey:(NSString *)key {
    [self.dispatchQueueManager runSerialAsync:^{
        [CTProfileBuilder buildRemoveValueForKey:key completionHandler:^(NSDictionary *customFields, NSDictionary *systemFields, NSArray<CTValidationResult*>*errors) {
            if (customFields && [[customFields allKeys] count] > 0) {
                NSMutableDictionary *profile = [[self.localDataStore generateBaseProfile] mutableCopy];
                NSString* _key = [customFields allKeys][0];
                CleverTapLogInternal(self.config.logLevel, @"%@: removing key %@ from profile", self, _key);
                [profile addEntriesFromDictionary:customFields];
                
                NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
                event[@"profile"] = profile;
                [self queueEvent:event withType:CleverTapEventTypeProfile];
            }
            if (errors) {
                [self.validationResultStack pushValidationResults:errors];
            }
        }];
    }];
}

- (void)profileSetMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key {
    [CTProfileBuilder buildSetMultiValues:values forKey:key
                           localDataStore:self.localDataStore
                        completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult*>*errors) {
        [self _handleMultiValueProfilePush:customFields updatedMultiValue:updatedMultiValue errors:errors];
    }];
}

- (void)profileAddMultiValue:(NSString *)value forKey:(NSString *)key {
    [CTProfileBuilder buildAddMultiValue:value forKey:key
                          localDataStore:self.localDataStore
                       completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult*>*errors) {
        
        [self _handleMultiValueProfilePush:customFields updatedMultiValue:updatedMultiValue errors:errors];
    }];
}

- (void)profileAddMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key {
    [CTProfileBuilder buildAddMultiValues:values forKey:key
                           localDataStore:self.localDataStore
                        completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult*>*errors) {
        
        [self _handleMultiValueProfilePush:customFields updatedMultiValue:updatedMultiValue errors:errors];
    }];
}

- (void)profileRemoveMultiValue:(NSString *)value forKey:(NSString *)key {
    [CTProfileBuilder buildRemoveMultiValue:value forKey:key
                             localDataStore:self.localDataStore
                          completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult*>*errors) {
        
        [self _handleMultiValueProfilePush:customFields updatedMultiValue:updatedMultiValue errors:errors];
    }];
}

- (void)profileRemoveMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key {
    [CTProfileBuilder buildRemoveMultiValues:values forKey:key
                              localDataStore:self.localDataStore completionHandler:^(NSDictionary *customFields, NSArray *updatedMultiValue, NSArray<CTValidationResult*>*errors) {
        [self _handleMultiValueProfilePush:customFields updatedMultiValue:updatedMultiValue errors:errors];
    }];
}

- (void)profileIncrementValueBy:(NSNumber* _Nonnull)value forKey:(NSString *_Nonnull)key {
    [CTProfileBuilder buildIncrementValueBy: value forKey: key
                             localDataStore: _localDataStore
                          completionHandler: ^(NSDictionary *_Nullable operatorDict, NSNumber * _Nullable updatedValue, NSArray<CTValidationResult *> *_Nullable errors) {
        [self _handleIncrementDecrementProfilePushForKey: key updatedValue: updatedValue operatorDict: operatorDict errors: errors];
    }];
}

- (void)profileDecrementValueBy:(NSNumber* _Nonnull)value forKey:(NSString *_Nonnull)key {
    [CTProfileBuilder buildDecrementValueBy: value forKey: key
                             localDataStore: _localDataStore
                          completionHandler: ^(NSDictionary *_Nullable operatorDict, NSNumber * _Nullable updatedValue, NSArray<CTValidationResult *> *_Nullable errors) {
        [self _handleIncrementDecrementProfilePushForKey: key updatedValue: updatedValue operatorDict: operatorDict errors: errors];
    }];
}


#pragma mark - Private Profile API

- (void)_handleIncrementDecrementProfilePushForKey:(NSString *)key updatedValue:(NSNumber *)updatedValue operatorDict: (NSDictionary *)operatorDict errors: (NSArray<CTValidationResult*>*)errors {
    
    if (errors) {
        [self.validationResultStack pushValidationResults:errors];
        return;
    }
    
    if (!operatorDict || (operatorDict && [[operatorDict allKeys] count] == 0)) {
        CleverTapLogInternal(self.config.logLevel, @"Failed to initialise an operator dictionary");
        return;
    }
    
    NSMutableDictionary *profile = [[self.localDataStore generateBaseProfile] mutableCopy];
    [profile addEntriesFromDictionary:operatorDict];
    CleverTapLogInternal(self.config.logLevel, @"Created Increment/ Decrement profile push: %@", operatorDict);
    
    NSMutableDictionary *event = [[NSMutableDictionary alloc] init];
    event[@"profile"] = profile;
    [self queueEvent:event withType:CleverTapEventTypeProfile];
    
}

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
        [self.validationResultStack pushValidationResults:errors];
    }
}

#pragma mark - User Action Events API

- (void)recordEvent:(NSString *)event {
    [self.dispatchQueueManager runSerialAsync:^{
        [CTEventBuilder build:event completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
            if (event) {
                [self queueEvent:event withType:CleverTapEventTypeRaised];
            }
            if (errors) {
                [self.validationResultStack pushValidationResults:errors];
            }
        }];
    }];
}

- (void)recordEvent:(NSString *)event withProps:(NSDictionary *)properties {
    [self.dispatchQueueManager runSerialAsync:^{
        [CTEventBuilder build:event withEventActions:properties completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
            if (event) {
                [self queueEvent:event withType:CleverTapEventTypeRaised];
            }
            if (errors) {
                [self.validationResultStack pushValidationResults:errors];
            }
        }];
    }];
}

- (void)recordChargedEventWithDetails:(NSDictionary *)chargeDetails andItems:(NSArray *)items {
    [self.dispatchQueueManager runSerialAsync:^{
        [CTEventBuilder buildChargedEventWithDetails:chargeDetails andItems:items completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
            if (event) {
                [self queueEvent:event withType:CleverTapEventTypeRaised];
            }
            if (errors) {
                [self.validationResultStack pushValidationResults:errors];
            }
        }];
    }];
}

- (void)recordErrorWithMessage:(NSString *)message andErrorCode:(int)code {
    [self.dispatchQueueManager runSerialAsync:^{
        NSString *currentVCName = self.currentViewControllerName ? self.currentViewControllerName : @"Unknown";
        
        [self recordEvent:@"Error Occurred" withProps:@{
            @"Error Message" : message,
            @"Error Code" : @(code),
            @"Location" : currentVCName
        }];
    }];
}

- (void)recordScreenView:(NSString *)screenName {
    if ([CTUIUtils runningInsideAppExtension]) {
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
    if (self.currentViewControllerName == nil && self.sessionManager.screenCount == 1) {
        self.sessionManager.screenCount--;
    }
    self.currentViewControllerName = screenName;
    self.sessionManager.screenCount++;
    
    [self recordPageEventWithExtras:nil];
}

- (void)recordNotificationViewedEventWithData:(id _Nonnull)notificationData {
    [self _recordPushNotificationEvent:NO forNotification:notificationData];
}

- (void)recordNotificationClickedEventWithData:(id)notificationData {
    [self _recordPushNotificationEvent:YES forNotification:notificationData];
}

- (void)_recordPushNotificationEvent:(BOOL)clicked forNotification:(id)notificationData {
#if !defined(CLEVERTAP_TVOS)
    NSDictionary *notification = [self getNotificationDictionary:notificationData];
    if (notification) {
        [self.dispatchQueueManager runSerialAsync:^{
            [CTEventBuilder buildPushNotificationEvent:clicked forNotification:notification completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
                if (event) {
                    self.wzrkParams = [event[CLTAP_EVENT_DATA] copy];
                    [self queueEvent:event withType: clicked ? CleverTapEventTypeRaised : CleverTapEventTypeNotificationViewed];
                };
                if (errors) {
                    [self.validationResultStack pushValidationResults:errors];
                }
            }];
        }];
    }
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


#pragma mark - Session API

- (NSTimeInterval)sessionGetTimeElapsed {
    long current = self.sessionManager.sessionId;
    return (int) [[[NSDate alloc] init] timeIntervalSince1970] - current;
}

- (CleverTapUTMDetail *)sessionGetUTMDetails {
    CleverTapUTMDetail *d = [[CleverTapUTMDetail alloc] init];
    d.source = self.sessionManager.source;
    d.medium = self.sessionManager.medium;
    d.campaign = self.sessionManager.campaign;
    return d;
}

- (int)userGetTotalVisits {
    return [self eventGetOccurrences:@"App Launched"];
}

- (int)userGetScreenCount {
    return self.sessionManager.screenCount;
}

- (NSTimeInterval)userGetPreviousVisitTime {
    return self.lastAppLaunchedTime;
}


# pragma mark - Push Notifications

- (void)setPushToken:(NSData *)pushToken {
    if ([CTUIUtils runningInsideAppExtension]){
        CleverTapLogDebug(self.config.logLevel, @"%@: setPushToken is a no-op in an app extension.", self);
        return;
    }
    NSString *deviceTokenString = [CTUtils deviceTokenStringFromData:pushToken];
    [self setPushTokenAsString:deviceTokenString];
}

- (void)setPushTokenAsString:(NSString *)pushTokenString {
    if ([CTUIUtils runningInsideAppExtension]){
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
    if ([CTUIUtils runningInsideAppExtension]){
        CleverTapLogDebug(self.config.logLevel, @"%@: handleNotificationWithData is a no-op in an app extension.", self);
        return;
    }
    [self handleNotificationWithData:data openDeepLinksInForeground:NO];
}

- (void)handleNotificationWithData:(id)data openDeepLinksInForeground:(BOOL)openInForeground {
    if ([CTUIUtils runningInsideAppExtension]){
        CleverTapLogDebug(self.config.logLevel, @"%@: handleNotificationWithData is a no-op in an app extension.", self);
        return;
    }
    [self _handlePushNotification:data openDeepLinksInForeground:openInForeground];
}

- (BOOL)isCleverTapNotification:(NSDictionary *)payload {
    return [self _isCTPushNotification:payload];
}


# pragma mark - Referrer Tracking

- (void)handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication {
    if ([CTUIUtils runningInsideAppExtension]){
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
    if ([CTUIUtils runningInsideAppExtension]){
        CleverTapLogDebug(self.config.logLevel, @"%@: pushInstallReferrerSource:medium:campaign is a no-op in an app extension.", self);
        return;
    }
    if (!source && !medium && !campaign) return;
    
    @synchronized (self) {
        long installStatus = 0;
        if (self.config.isDefaultInstance) {
            installStatus = [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:@"install_referrer_status" config: self.config] withResetValue:[CTPreferences getIntForKey:@"install_referrer_status" withResetValue:0]];
        } else {
            installStatus = [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:@"install_referrer_status" config: self.config] withResetValue:0];
        }
        if (installStatus == 1) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Install referrer has already been set. Will not overwrite", self);
            return;
        }
        [CTPreferences putInt:1 forKey:[CTPreferences storageKeyWithSuffix:@"install_referrer_status" config: self.config]];
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


#pragma mark - Admin

- (void)setLibrary:(NSString *)name {
    self.deviceInfo.library = name;
}

- (void)setCustomSdkVersion:(NSString *)name version:(int)version {
    if (!auxiliarySdkVersions) {
        auxiliarySdkVersions = [NSMutableDictionary new];
    }
    auxiliarySdkVersions[name] = @(version);
}

- (void)setLocale:(NSLocale *)locale
{
    _locale = locale;
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
    [self _setCredentialsWithAccountID:accountID token:token region:nil];
}

+ (void)changeCredentialsWithAccountID:(NSString *)accountID token:(NSString *)token region:(NSString *)region {
    [self _setCredentialsWithAccountID:accountID token:token region:region];
}

+ (void)setCredentialsWithAccountID:(NSString *)accountID andToken:(NSString *)token {
    [self _setCredentialsWithAccountID:accountID token:token region:nil];
}

+ (void)setCredentialsWithAccountID:(NSString *)accountID token:(NSString *)token region:(NSString *)region {
    [self _setCredentialsWithAccountID:accountID token:token region:region];
}

+ (void)setCredentialsWithAccountID:(NSString *)accountID token:(NSString *)token proxyDomain:(NSString *)proxyDomain {
    [self _setCredentialsWithAccountID:accountID token:token proxyDomain:proxyDomain];
    [_plistInfo setCredentialsWithAccountID:accountID token:token proxyDomain:proxyDomain];
}

+ (void)setCredentialsWithAccountID:(NSString *)accountID token:(NSString *)token proxyDomain:(NSString *)proxyDomain spikyProxyDomain:(NSString *)spikyProxyDomain {
    [self _setCredentialsWithAccountID:accountID token:token proxyDomain:proxyDomain];
    
    NSString *finalSpikyProxyDomain;
    if (spikyProxyDomain != nil && ![spikyProxyDomain isEqualToString:@""]) {
        finalSpikyProxyDomain = [spikyProxyDomain stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (finalSpikyProxyDomain.length <= 0) {
            finalSpikyProxyDomain = nil;
        }
    }
    [_plistInfo setCredentialsWithAccountID:accountID token:token proxyDomain:proxyDomain spikyProxyDomain:finalSpikyProxyDomain];
}

+ (void)setCredentialsWithAccountID:(NSString *)accountID token:(NSString *)token proxyDomain:(NSString *)proxyDomain spikyProxyDomain:(NSString *)spikyProxyDomain handshakeDomain:(NSString *)handshakeDomain {
    [self _setCredentialsWithAccountID:accountID token:token proxyDomain:proxyDomain];
    
    NSString *finalSpikyProxyDomain;
    if (spikyProxyDomain != nil && ![spikyProxyDomain isEqualToString:@""]) {
        finalSpikyProxyDomain = [spikyProxyDomain stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (finalSpikyProxyDomain.length <= 0) {
            finalSpikyProxyDomain = nil;
        }
    }
    [_plistInfo setCredentialsWithAccountID:accountID token:token proxyDomain:proxyDomain spikyProxyDomain:finalSpikyProxyDomain handshakeDomain:handshakeDomain];
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

- (void)setLocationForGeofences:(CLLocationCoordinate2D)location withPluginVersion:(NSString *)version {
    if (version) {
        _gfSDKVersion = version;
    }
    _geofenceLocation = YES;
    [self setLocation:location];
}

+ (void)setLocation:(CLLocationCoordinate2D)location {
    [[self sharedInstance] setLocation:location];
}

- (void)setLocation:(CLLocationCoordinate2D)location {
    self.userSetLocation = location;
}

- (void)setGeofenceLocation:(BOOL)geofenceLocation {
    _geofenceLocation = geofenceLocation;
}

- (BOOL)geofenceLocation {
    return _geofenceLocation;
}

#pragma clang diagnostic pop


#pragma mark - Delegates

#pragma mark CleverTap Sync Delegate Implementation

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


#pragma mark  CleverTap URL Delegate Getter and Setter

- (void)setUrlDelegate:(id <CleverTapURLDelegate>)delegate {
    if (delegate && [delegate conformsToProtocol:@protocol(CleverTapURLDelegate)]) {
        _urlDelegate = delegate;
    } else {
        CleverTapLogDebug(self.config.logLevel, @"%@: CleverTap URL Delegate does not conform to the CleverTapURLDelegate protocol", self);
    }
}

- (id<CleverTapURLDelegate>)urlDelegate {
    return _urlDelegate;
}


#pragma mark CleverTap Push Notification Delegate Implementation

- (void)setPushNotificationDelegate:(id<CleverTapPushNotificationDelegate>)delegate {
    if ([CTUIUtils runningInsideAppExtension]){
        CleverTapLogDebug(self.config.logLevel, @"%@: setPushNotificationDelegate is a no-op in an app extension.", self);
        return;
    }
    if (delegate && [delegate conformsToProtocol:@protocol(CleverTapPushNotificationDelegate)]) {
        _pushNotificationDelegate = delegate;
    } else {
        CleverTapLogDebug(self.config.logLevel, @"%@: CleverTap PushNotification Delegate does not conform to the CleverTapPushNotificationDelegate protocol", self);
    }
}

- (id<CleverTapPushNotificationDelegate>)pushNotificationDelegate {
    return _pushNotificationDelegate;
}


#pragma mark CleverTap InApp Notification Delegate Implementation
#if !CLEVERTAP_NO_INAPP_SUPPORT
- (void)setInAppNotificationDelegate:(id <CleverTapInAppNotificationDelegate>)delegate {
    [self.inAppDisplayManager setInAppNotificationDelegate:delegate];
}

- (id<CleverTapInAppNotificationDelegate>)inAppNotificationDelegate {
    return self.inAppDisplayManager.inAppNotificationDelegate;
}

- (void)fetchInApps:(CleverTapFetchInAppsBlock _Nullable)block {
    self.fetchInAppsBlock = block;
    [self queueEvent:@{CLTAP_EVENT_NAME: CLTAP_WZRK_FETCH_EVENT, CLTAP_EVENT_DATA: @{@"t": @5}} withType:CleverTapEventTypeFetch];
}
#endif

#pragma mark - Event API

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

#pragma mark - Session API

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
- (BOOL)handleMessage:(NSDictionary<NSString *, id> *_Nonnull)message forWatchSession:(WCSession *_Nonnull)session  {
    NSString *type = [message objectForKey:@"clevertap_type"];
    
    BOOL handled = (type != nil);
    
    if ([type isEqualToString:@"recordEventWithProps"]) {
        [self recordEvent: message[@"event"] withProps: message[@"props"]];
    }
    return handled;
}
#endif


#pragma mark - App Inbox

#if !CLEVERTAP_NO_INBOX_SUPPORT

#pragma mark Public

- (void)initializeInboxWithCallback:(CleverTapInboxSuccessBlock)callback {
    if ([CTUIUtils runningInsideAppExtension]) {
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
    [self.dispatchQueueManager runSerialAsync:^{
        if (self.inboxController) {
            [CTUtils runSyncMainQueue: ^{
                callback(self.inboxController.isInitialized);
            }];
            return;
        }
        if (self.deviceInfo.deviceId) {
            self.inboxController = [[CTInboxController alloc] initWithAccountId: [self.config.accountId copy] guid: [self.deviceInfo.deviceId copy]];
            self.inboxController.delegate = self;
            [CTUtils runSyncMainQueue: ^{
                callback(self.inboxController.isInitialized);
            }];
        }
    }];
}

- (NSInteger)getInboxMessageCount {
    if (![self _isInboxInitialized]) {
        return -1;
    }
    return self.inboxController.count;
}

- (NSInteger)getInboxMessageUnreadCount {
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

- (void)recordInboxNotificationViewedEventForID:(NSString * _Nonnull)messageId {
    CleverTapInboxMessage *message = [self getInboxMessageForId:messageId];
    [self recordInboxMessageStateEvent:NO forMessage:message andQueryParameters:nil];
}

- (void)recordInboxNotificationClickedEventForID:(NSString * _Nonnull)messageId {
    CleverTapInboxMessage *message = [self getInboxMessageForId:messageId];
    [self recordInboxMessageStateEvent:YES forMessage:message andQueryParameters:nil];
}

- (void)deleteInboxMessageForID:(NSString *)messageId {
    if (![self _isInboxInitialized]) {
        return;
    }
    [self.inboxController deleteMessageWithId:messageId];
}

- (void)deleteInboxMessagesForIDs:(NSArray<NSString *> *_Nonnull)messageIds {
    if (![self _isInboxInitialized]) {
        return;
    }
    [self.inboxController deleteMessagesWithId:messageIds];
}

- (void)markReadInboxMessageForID:(NSString *)messageId{
    if (![self _isInboxInitialized]) {
        return;
    }
    [self.inboxController markReadMessageWithId:messageId];
}

- (void)markReadInboxMessagesForIDs:(NSArray<NSString *> *_Nonnull)messageIds{
    if (![self _isInboxInitialized]) {
        return;
    }
    if (messageIds != nil && [messageIds count] > 0) {
        [self.inboxController markReadMessagesWithId:messageIds];
    }
    else {
        CleverTapLogStaticDebug(@"App Inbox Message IDs array is null or empty");
    }
}

- (void)registerInboxUpdatedBlock:(CleverTapInboxUpdatedBlock)block {
    if (!_inboxUpdateBlocks) {
        _inboxUpdateBlocks = [NSMutableArray new];
    }
    [_inboxUpdateBlocks addObject:block];
}

- (CleverTapInboxViewController * _Nullable)newInboxViewControllerWithConfig:(CleverTapInboxStyleConfig * _Nullable )config andDelegate:(id<CleverTapInboxViewControllerDelegate> _Nullable )delegate {
    if (![self _isInboxInitialized]) {
        return nil;
    }
    NSArray *messages = [self getAllInboxMessages];
    if (! messages) {
        return nil;
    }
    return [[CleverTapInboxViewController alloc] initWithMessages:messages config:config delegate:delegate analyticsDelegate:self];
}

- (void)dismissAppInbox {
    [CTUtils runSyncMainQueue:^{
        UIApplication *application = [CTUIUtils getSharedApplication];
        UIWindow *window = [[application delegate] window];
        UIViewController *presentedViewcontoller = [[window rootViewController] presentedViewController];
        if ([presentedViewcontoller isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navigationController = (UINavigationController *)[[window rootViewController] presentedViewController];
            if ([navigationController.topViewController isKindOfClass:[CleverTapInboxViewController class]]) {
                [[window rootViewController] dismissViewControllerAnimated:YES completion:nil];
            }
        }
    }];
}

#pragma mark Private

- (void)_resetInbox {
    if (self.inboxController && self.inboxController.isInitialized && self.deviceInfo.deviceId) {
        self.inboxController = [[CTInboxController alloc] initWithAccountId: [self.config.accountId copy] guid: [self.deviceInfo.deviceId copy]];
        self.inboxController.delegate = self;
    }
}

- (BOOL)_isInboxInitialized {
    if ([CTUIUtils runningInsideAppExtension]) {
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
        if (self.urlDelegate && [self.urlDelegate respondsToSelector: @selector(shouldHandleCleverTapURL:forChannel:)] && ![self.urlDelegate shouldHandleCleverTapURL:ctaURL forChannel:CleverTapAppInbox]) {
            return;
        }
        [CTUtils runSyncMainQueue:^{
            [self openURL:ctaURL forModule:@"Inbox message"];
        }];
#endif
    }
}

- (void)messageDidSelectForPushPermission:(BOOL)fallbackToSettings {
    CleverTapLogDebug(self.config.logLevel, @"%@: App Inbox Campaign Push Primer Accepted:", self);
#if !CLEVERTAP_NO_INAPP_SUPPORT
    [self.pushPrimerManager promptForOSPushNotificationWithFallbackToSettings:fallbackToSettings
                                       andSkipSettingsAlert:NO];
#endif
}

- (void)recordInboxMessageStateEvent:(BOOL)clicked
                          forMessage:(CleverTapInboxMessage *)message andQueryParameters:(NSDictionary *)params {
    
    [self.dispatchQueueManager runSerialAsync:^{
        [CTEventBuilder buildInboxMessageStateEvent:clicked forMessage:message andQueryParameters:params completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
            if (event) {
                if (clicked) {
                    self.wzrkParams = [event[CLTAP_EVENT_DATA] copy];
                }
                [self queueEvent:event withType:CleverTapEventTypeRaised];
            };
            if (errors) {
                [self.validationResultStack pushValidationResults:errors];
            }
        }];
    }];
}


#pragma mark Inbox Message private

- (BOOL)didHandleInboxMessageTestFromPushNotificaton:(NSDictionary*)notification {
#if !CLEVERTAP_NO_INBOX_SUPPORT
    if ([CTUIUtils runningInsideAppExtension]) {
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
        NSInteger expireTime = (long)expireEpochSeconds;
        
        NSMutableDictionary *message = [NSMutableDictionary dictionary];
        [message setObject:nowEpoch forKey:@"_id"];
        [message setObject:[NSNumber numberWithLong:expireTime] forKey:@"wzrk_ttl"];
        [message addEntriesFromDictionary:msg ?: @{}];
        
        NSMutableArray<NSDictionary*> *inboxMsg = [NSMutableArray new];
        [inboxMsg addObject:message];
        
        if (inboxMsg) {
            float delay = self.isAppForeground ? 0.5 : 2.0;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                @try {
                    [self initializeInboxWithCallback:^(BOOL success) {
                        if (success) {
                            [self.dispatchQueueManager runSerialAsync:^{
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

#pragma mark - Display Units

#if !CLEVERTAP_NO_DISPLAY_UNIT_SUPPORT

- (void)initializeDisplayUnitWithCallback:(CleverTapDisplayUnitSuccessBlock)callback {
    [self.dispatchQueueManager runSerialAsync:^{
        if (self.displayUnitController) {
            [CTUtils runSyncMainQueue: ^{
                callback(self.displayUnitController.isInitialized);
            }];
            return;
        }
        if (self.deviceInfo.deviceId) {
            self.displayUnitController = [[CTDisplayUnitController alloc] initWithAccountId: [self.config.accountId copy] guid: [self.deviceInfo.deviceId copy]];
            self.displayUnitController.delegate = self;
            [CTUtils runSyncMainQueue: ^{
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
    if ([CTUIUtils runningInsideAppExtension]){
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
    if ([CTUIUtils runningInsideAppExtension]) {
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
    [self.dispatchQueueManager runSerialAsync:^{
        [CTEventBuilder buildDisplayViewStateEvent:NO forDisplayUnit:displayUnit andQueryParameters:nil completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
            if (event) {
                self.wzrkParams = [event[CLTAP_EVENT_DATA] copy];
                [self queueEvent:event withType:CleverTapEventTypeRaised];
            };
            if (errors) {
                [self.validationResultStack pushValidationResults:errors];
            }
        }];
    }];
#endif
}

- (void)recordDisplayUnitClickedEventForID:(NSString *)unitID {
    // get the display unit data
    CleverTapDisplayUnit *displayUnit = [self getDisplayUnitForID:unitID];
#if !defined(CLEVERTAP_TVOS)
    [self.dispatchQueueManager runSerialAsync:^{
        [CTEventBuilder buildDisplayViewStateEvent:YES forDisplayUnit:displayUnit andQueryParameters:nil completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
            if (event) {
                self.wzrkParams = [event[CLTAP_EVENT_DATA] copy];
                [self queueEvent:event withType:CleverTapEventTypeRaised];
            };
            if (errors) {
                [self.validationResultStack pushValidationResults:errors];
            }
        }];
    }];
#endif
}

#endif


#pragma mark - Feature Flags

// run off main
- (void) _initFeatureFlags {
    if (_config.analyticsOnly) {
        CleverTapLogDebug(self.config.logLevel, @"%@ is configured as analytics only, Feature Flag unavailable", self);
        return;
    }
    self.featureFlags = [[CleverTapFeatureFlags alloc] initWithPrivateDelegate:self];
    [self.dispatchQueueManager runSerialAsync:^{
        if (self.featureFlagsController) {
            return;
        }
        if (self.deviceInfo.deviceId) {
            self.featureFlagsController = [[CTFeatureFlagsController alloc] initWithConfig: self.config guid:[self.deviceInfo.deviceId copy] delegate:self];
        }
        [self fetchFeatureFlags];
    }];
}

// run off main
- (void)_resetFeatureFlags {
    if (self.featureFlagsController && self.featureFlagsController.isInitialized && self.deviceInfo.deviceId) {
        self.featureFlagsController = [[CTFeatureFlagsController alloc] initWithConfig: self.config guid:[self.deviceInfo.deviceId copy] delegate:self];
        [self fetchFeatureFlags];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)setFeatureFlagsDelegate:(id<CleverTapFeatureFlagsDelegate>)delegate {
    if (delegate && [delegate conformsToProtocol:@protocol(CleverTapFeatureFlagsDelegate)]) {
        _featureFlagsDelegate = delegate;
    } else {
        CleverTapLogDebug(self.config.logLevel, @"%@: CleverTap Feature Flags Delegate does not conform to the CleverTapFeatureFlagsDelegate protocol", self);
    }
}

- (id<CleverTapFeatureFlagsDelegate>)featureFlagsDelegate {
    return _featureFlagsDelegate;
}

- (void)featureFlagsDidUpdate {
    if (self.featureFlagsDelegate && [self.featureFlagsDelegate respondsToSelector:@selector(ctFeatureFlagsUpdated)]) {
        [self.featureFlagsDelegate ctFeatureFlagsUpdated];
    }
}
#pragma clang diagnostic pop

- (void)fetchFeatureFlags {
    [self queueEvent:@{CLTAP_EVENT_NAME: CLTAP_WZRK_FETCH_EVENT, CLTAP_EVENT_DATA: @{@"t": @1}} withType:CleverTapEventTypeFetch];
}

- (BOOL)getFeatureFlag:(NSString* _Nonnull)key withDefaultValue:(BOOL)defaultValue {
    if (self.featureFlagsController && self.featureFlagsController.isInitialized) {
        return [self.featureFlagsController get:key withDefaultValue: defaultValue];
    }
    CleverTapLogDebug(self.config.logLevel, @"%@: CleverTap Feature Flags not initialized", self);
    return defaultValue;
}


#pragma mark - Product Config

// run off main
- (void) _initProductConfig {
    if (_config.analyticsOnly) {
        CleverTapLogDebug(self.config.logLevel, @"%@ is configured as analytics only, Product Config unavailable", self);
        return;
    }
    self.productConfig = [[CleverTapProductConfig alloc]  initWithConfig: self.config privateDelegate:self];
    [self.dispatchQueueManager runSerialAsync:^{
        if (self.productConfigController) {
            return;
        }
        if (self.deviceInfo.deviceId) {
            self.productConfigController = [[CTProductConfigController alloc] initWithConfig: self.config guid:[self.deviceInfo.deviceId copy] delegate:self];
        }
    }];
}

// run off main
- (void)_resetProductConfig {
    if (self.productConfigController && self.productConfigController.isInitialized && self.deviceInfo.deviceId) {
        [self.productConfig resetProductConfigSettings];
        self.productConfig = [[CleverTapProductConfig alloc]  initWithConfig: self.config privateDelegate:self];
        self.productConfigController = [[CTProductConfigController alloc] initWithConfig: self.config guid:[self.deviceInfo.deviceId copy] delegate:self];
    }
}

// run off main
- (void)_resetVars {
    /// Clear content for current user
    /// Content for new user will be loaded in `recordAppLaunched:` using `CTVarCache.loadDiffs`
    [[self variables] clearUserContent];
}

- (NSDictionary *)_setProductConfig:(NSDictionary *)arp {
    if (arp) {
        NSMutableDictionary *configOptions = [NSMutableDictionary new];
        configOptions[@"rc_n"] = arp[@"rc_n"];
        configOptions[@"rc_w"] = arp[@"rc_w"];
        return [configOptions mutableCopy];
    }
    return nil;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)setProductConfigDelegate:(id<CleverTapProductConfigDelegate>)delegate {
    if (delegate && [delegate conformsToProtocol:@protocol(CleverTapProductConfigDelegate)]) {
        _productConfigDelegate = delegate;
    } else {
        CleverTapLogDebug(self.config.logLevel, @"%@: CleverTap Product Config Delegate does not conform to the CleverTapProductConfigDelegate protocol", self);
    }
}

- (id<CleverTapProductConfigDelegate>)productConfigDelegate {
    return _productConfigDelegate;
}

- (void)productConfigDidFetch {
    if (self.productConfigDelegate && [self.productConfigDelegate respondsToSelector:@selector(ctProductConfigFetched)]) {
        [self.productConfigDelegate ctProductConfigFetched];
    }
}

- (void)productConfigDidActivate {
    if (self.productConfigDelegate && [self.productConfigDelegate respondsToSelector:@selector(ctProductConfigActivated)]) {
        [self.productConfigDelegate ctProductConfigActivated];
    }
}

- (void)productConfigDidInitialize {
    if (self.productConfigDelegate && [self.productConfigDelegate respondsToSelector:@selector(ctProductConfigInitialized)]) {
        [self.productConfigDelegate ctProductConfigInitialized];
    }
}
#pragma clang diagnostic pop

- (void)fetchProductConfig {
    [self queueEvent:@{CLTAP_EVENT_NAME: CLTAP_WZRK_FETCH_EVENT, CLTAP_EVENT_DATA: @{@"t": @0}} withType:CleverTapEventTypeFetch];
}

- (void)activateProductConfig {
    if (self.productConfigController && self.productConfigController.isInitialized) {
        [self.productConfigController activate];
    }
}

- (void)fetchAndActivateProductConfig {
    if (self.productConfigController && self.productConfigController.isInitialized) {
        [self.productConfigController fetchAndActivate];
    }
}

- (void)resetProductConfig {
    if (self.productConfigController && self.productConfigController.isInitialized) {
        [self.productConfigController reset];
    }
}

- (void)setDefaultsProductConfig:(NSDictionary<NSString *,NSObject *> *)defaults {
    if (self.productConfigController && self.productConfigController.isInitialized) {
        [self.productConfigController setDefaults:defaults];
    }
}

- (void)setDefaultsFromPlistFileNameProductConfig:(NSString *)fileName {
    if (self.productConfigController && self.productConfigController.isInitialized) {
        [self.productConfigController setDefaultsFromPlistFileName:fileName];
    }
}

- (CleverTapConfigValue *_Nullable)getProductConfig:(NSString* _Nonnull)key {
    if (self.productConfigController && self.productConfigController.isInitialized) {
        return [self.productConfigController get:key];
    }
    CleverTapLogDebug(self.config.logLevel, @"%@: CleverTap Product Config not initialized", self);
    return nil;
}


#pragma mark - Geofence Public APIs

- (void)didFailToRegisterForGeofencesWithError:(NSError *)error {
    CTValidationResult *result = [[CTValidationResult alloc] init];
    [result setErrorCode:(int)error.code];
    [result setErrorDesc:error.localizedDescription];
    [self.validationResultStack pushValidationResult:result];
}

- (void)recordGeofenceEnteredEvent:(NSDictionary *_Nonnull)geofenceDetails {
    [self _buildGeofenceStateEvent:YES forGeofenceDetails:geofenceDetails];
}

- (void)recordGeofenceExitedEvent:(NSDictionary *_Nonnull)geofenceDetails {
    [self _buildGeofenceStateEvent:NO forGeofenceDetails:geofenceDetails];
}

- (void)_buildGeofenceStateEvent:(BOOL)entered forGeofenceDetails:(NSDictionary *_Nonnull)geofenceDetails {
#if !defined(CLEVERTAP_TVOS)
    [self.dispatchQueueManager runSerialAsync:^{
        [CTEventBuilder buildGeofenceStateEvent:entered forGeofenceDetails:geofenceDetails completionHandler:^(NSDictionary *event, NSArray<CTValidationResult*>*errors) {
            if (event) {
                [self queueEvent:event withType:CleverTapEventTypeRaised];
            };
            if (errors) {
                [self.validationResultStack pushValidationResults:errors];
            }
        }];
    }];
#endif
}

#pragma mark - Signed Call Public APIs

- (void)recordSignedCallEvent:(int)eventRawValue forCallDetails:(NSDictionary *)calldetails {
#if !defined(CLEVERTAP_TVOS)
    [self.dispatchQueueManager runSerialAsync:^{
        [CTEventBuilder buildSignedCallEvent: eventRawValue forCallDetails:calldetails completionHandler:^(NSDictionary * _Nullable event, NSArray<CTValidationResult *> * _Nullable errors) {
            if (event) {
                [self queueEvent:event withType:CleverTapEventTypeRaised];
            };
            if (errors) {
                [self.validationResultStack pushValidationResults:errors];
            }
        }];
    }];
#endif
}

- (void)setDomainDelegate:(id<CleverTapDomainDelegate>)delegate {
    if ([CTUIUtils runningInsideAppExtension]){
        CleverTapLogDebug(self.config.logLevel, @"%@: setDomainDelegate is a no-op in an app extension.", self);
        return;
    }
    if (delegate && [delegate conformsToProtocol:@protocol(CleverTapDomainDelegate)]) {
        _domainDelegate = delegate;
    } else {
        CleverTapLogDebug(self.config.logLevel, @"%@: CleverTap Domain Delegate does not conform to the CleverTapDomainDelegate protocol", self);
    }
}

- (void)onDomainAvailable {
    NSString *dcDomain = [self getDomainString];
    if (self.domainDelegate && [self.domainDelegate respondsToSelector:@selector(onSCDomainAvailable:)]) {
        [self.domainDelegate onSCDomainAvailable: dcDomain];
    } else if (dcDomain == nil) {
        [self onDomainUnavailable];
    }
}

- (void)onDomainUnavailable {
    if (self.domainDelegate && [self.domainDelegate respondsToSelector:@selector(onSCDomainUnavailable)]) {
        [self.domainDelegate onSCDomainUnavailable];
    }
}

//Updates the format of the domain - from `in1.clevertap-prod.com` to region.auth.domain (i.e. in1.auth.clevertap-prod.com)
- (NSString *)getDomainString {
    if (self.domainFactory.redirectDomain != nil) {
        NSArray *listItems = [self.domainFactory.redirectDomain componentsSeparatedByString:@"."];
        NSString *domainItem = [listItems[0] stringByAppendingString:@".auth"];
        for (int i = 1; i < listItems.count; i++ ) {
            NSString *dotString = [@"." stringByAppendingString: listItems[i]];
            domainItem = [domainItem stringByAppendingString: dotString];
        }
        self.signedCallDomain = domainItem;
        return domainItem;
    } else {
        return nil;
    }
}

#pragma mark - Push Permission

#if !CLEVERTAP_NO_INAPP_SUPPORT

- (void)setPushPermissionDelegate:(id<CleverTapPushPermissionDelegate>)delegate {
    [self.pushPrimerManager setPushPermissionDelegate:delegate];
}

- (id<CleverTapPushPermissionDelegate>)pushPermissionDelegate {
    return self.pushPrimerManager.pushPermissionDelegate;
}

- (void)promptPushPrimer:(NSDictionary *_Nonnull)json {
    [self.pushPrimerManager promptPushPrimer:json];
}

- (void)promptForPushPermission:(BOOL)isFallbackToSettings {
    [self.pushPrimerManager promptForOSPushNotificationWithFallbackToSettings:isFallbackToSettings andSkipSettingsAlert:NO];
}

- (void)getNotificationPermissionStatusWithCompletionHandler:(void (^)(UNAuthorizationStatus))completion {
    [self.pushPrimerManager getNotificationPermissionStatusWithCompletionHandler:completion];
}

- (void)notifyPushPermissionResponse:(BOOL)accepted {
    CleverTapLogInternal(self.config.logLevel, @"%@: Push Permission Response: %s", self, (accepted ? "accepted" : "denied"));
    if (self.pushPermissionDelegate && [self.pushPermissionDelegate respondsToSelector:@selector(onPushPermissionResponse:)]) {
        [self.pushPermissionDelegate onPushPermissionResponse:accepted];
    }
}
#endif

#pragma mark - Utility

+ (BOOL)isValidCleverTapId:(NSString *_Nullable)cleverTapID {
    return [CTValidator isValidCleverTapId:cleverTapID];
}

#pragma mark - Sync PE and Custom Templates

- (void)syncVariables {
    [self syncVariables:NO];
}

- (void)syncVariables:(BOOL)isProduction {
    NSDictionary *varsPayload = [[self variables] varsPayload];
    [self syncWithBlock:^{
        NSDictionary *meta = [self batchHeaderForQueue:CTQueueTypeUndefined];
        CTRequest *ctRequest = [CTRequestFactory syncVarsRequestWithConfig:self.config params:@[meta, varsPayload] domain:self.domainFactory.redirectDomain];
        [self syncRequest:ctRequest logMessage:@"Vars sync"];
    } methodName:NSStringFromSelector(_cmd) isProduction:isProduction];
}

#if !CLEVERTAP_NO_INAPP_SUPPORT
- (void)syncCustomTemplates {
    [self syncCustomTemplates:NO];
}

- (void)syncCustomTemplates:(BOOL)isProduction {
    NSDictionary *syncPayload = [[self customTemplatesManager] syncPayload];
    [self syncWithBlock:^{
        NSDictionary *meta = [self batchHeaderForQueue:CTQueueTypeUndefined];
        CTRequest *ctRequest = [CTRequestFactory syncTemplatesRequestWithConfig:self.config params:@[meta, syncPayload] domain:self.domainFactory.redirectDomain];
        [self syncRequest:ctRequest logMessage:@"Define Custom Templates"];
    } methodName:NSStringFromSelector(_cmd) isProduction:isProduction];
}
#endif

- (void)syncWithBlock:(void(^)(void))syncBlock methodName:(NSString *)methodName isProduction:(BOOL)isProduction {
    if (isProduction) {
#if DEBUG
        CleverTapLogInfo(_config.logLevel, @"%@: Calling %@ with isProduction:YES from Debug configuration/build. Do not use isProduction:YES in this case", self, methodName);
#else
        CleverTapLogInfo(_config.logLevel, @"%@: Calling %@ with isProduction:YES from Release configuration/build. Do not release this build and use with caution", self, methodName);
#endif
        [self runSerialAsyncEnsureHandshake:syncBlock];
    } else {
#if DEBUG
        [self runSerialAsyncEnsureHandshake:syncBlock];
#else
        CleverTapLogInfo(_config.logLevel, @"%@: %@ can only be called from Debug configurations/builds", self, methodName);
#endif
    }
}

- (void)syncRequest:(CTRequest *)request logMessage:(NSString *)logMessage {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [request onResponse:^(NSData * _Nullable data, NSURLResponse * _Nullable response) {
        [self handleSyncOnResponse:data response:response logMessage:logMessage];
        dispatch_semaphore_signal(semaphore);
    }];
    [request onError:^(NSError * _Nullable error) {
        CleverTapLogDebug(self->_config.logLevel, @"%@: Error %@: %@", self, logMessage, error.debugDescription);
        dispatch_semaphore_signal(semaphore);
    }];
    [self.requestSender send:request];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

- (void)handleSyncOnResponse:(NSData * _Nullable)data response:(NSURLResponse * _Nullable)response
                     logMessage:(NSString *)logMessage {
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200) {
            CleverTapLogDebug(self->_config.logLevel, @"%@: %@ successful.", self, logMessage);
        }
        else if (httpResponse.statusCode == 401) {
            CleverTapLogDebug(self->_config.logLevel, @"%@: Unauthorized access from a non-test profile. Please mark this profile as a test profile from the CleverTap dashboard.", self);
        }
    }
    CT_TRY
    id jsonResp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    if (jsonResp[@"error"]) {
        CleverTapLogDebug(self->_config.logLevel, @"%@: %@ error: %@", self, logMessage, jsonResp[@"error"]);
    }
    CT_END_TRY
}

#pragma mark - Product Experiences

- (void)onVariablesChanged:(CleverTapVariablesChangedBlock _Nonnull )block {
    [[self variables] onVariablesChanged:block];
}

- (void)onceVariablesChanged:(CleverTapVariablesChangedBlock _Nonnull )block {
    [[self variables] onceVariablesChanged:block];
}

- (void)fetchVariables:(CleverTapFetchVariablesBlock)block {
    [[self variables] setFetchVariablesBlock:block];
    [self queueEvent:@{CLTAP_EVENT_NAME: CLTAP_WZRK_FETCH_EVENT, CLTAP_EVENT_DATA: @{@"t": @4}} withType:CleverTapEventTypeFetch];
}

- (CTVar * _Nullable)getVariable:(NSString * _Nonnull)name {
    CTVar *var = [[self.variables varCache] getVariable:name];
    if (!var) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Variable with name: %@ not found.", self, name);
    }
    return var;
}

- (id _Nullable)getVariableValue:(NSString * _Nonnull)name {
    return [[self.variables varCache] getMergedValue:name];
}

- (void)onVariablesChangedAndNoDownloadsPending:(CleverTapVariablesChangedBlock _Nonnull )block {
    [[self variables] onVariablesChangedAndNoDownloadsPending:block];
}

- (void)onceVariablesChangedAndNoDownloadsPending:(CleverTapVariablesChangedBlock _Nonnull )block {
    [[self variables] onceVariablesChangedAndNoDownloadsPending:block];
}

#pragma mark - PE Vars

- (CTVar *)defineVar:(NSString *)name {
    return [self.variables define:name with:nil kind:nil];
}

- (CTVar *)defineVar:(NSString *)name withInt:(int)defaultValue {
    return [self.variables define:name with:[NSNumber numberWithInt:defaultValue] kind:CT_KIND_INT];
}

- (CTVar *)defineVar:(NSString *)name withFloat:(float)defaultValue {
    return [self.variables define:name with:[NSNumber numberWithFloat:defaultValue] kind:CT_KIND_FLOAT];
}

- (CTVar *)defineVar:(NSString *)name withDouble:(double)defaultValue {
    return [self.variables define:name
                         with:[NSNumber numberWithDouble:defaultValue]
                         kind:CT_KIND_FLOAT];
}

- (CTVar *)defineVar:(NSString *)name withCGFloat:(CGFloat)defaultValue {
    return [self.variables define:name
                         with:[NSNumber numberWithDouble:defaultValue]
                         kind:CT_KIND_FLOAT];
}

- (CTVar *)defineVar:(NSString *)name withShort:(short)defaultValue {
    return [self.variables define:name
                         with:[NSNumber numberWithShort:defaultValue]
                         kind:CT_KIND_INT];
}

- (CTVar *)defineVar:(NSString *)name withChar:(char)defaultValue {
    return [self.variables define:name
                         with:[NSNumber numberWithChar:defaultValue]
                         kind:CT_KIND_INT];
}

- (CTVar *)defineVar:(NSString *)name withBool:(BOOL)defaultValue {
    return [self.variables define:name
                         with:[NSNumber numberWithBool:defaultValue]
                         kind:CT_KIND_BOOLEAN];
}

- (CTVar *)defineVar:(NSString *)name withInteger:(NSInteger)defaultValue {
    return [self.variables define:name
                         with:[NSNumber numberWithInteger:defaultValue]
                         kind:CT_KIND_INT];
}

- (CTVar *)defineVar:(NSString *)name withLong:(long)defaultValue {
    return [self.variables define:name
                         with:[NSNumber numberWithLong:defaultValue]
                         kind:CT_KIND_INT];
}

- (CTVar *)defineVar:(NSString *)name withLongLong:(long long)defaultValue {
    return [self.variables define:name
                         with:[NSNumber numberWithLongLong:defaultValue]
                         kind:CT_KIND_INT];
}

- (CTVar *)defineVar:(NSString *)name withUnsignedChar:(unsigned char)defaultValue {
    return [self.variables define:name
                         with:[NSNumber numberWithUnsignedChar:defaultValue]
                         kind:CT_KIND_INT];
}

- (CTVar *)defineVar:(NSString *)name withUnsignedInt:(unsigned int)defaultValue {
    return [self.variables define:name
                         with:[NSNumber numberWithUnsignedInt:defaultValue]
                         kind:CT_KIND_INT];
}

- (CTVar *)defineVar:(NSString *)name withUnsignedInteger:(NSUInteger)defaultValue
{
    return [self.variables define:name
                         with:[NSNumber numberWithUnsignedInteger:defaultValue]
                         kind:CT_KIND_INT];
}

- (CTVar *)defineVar:(NSString *)name withUnsignedLong:(unsigned long)defaultValue {
    return [self.variables define:name
                         with:[NSNumber numberWithUnsignedLong:defaultValue]
                         kind:CT_KIND_INT];
}

- (CTVar *)defineVar:(NSString *)name withUnsignedLongLong:(unsigned long long)defaultValue {
    return [self.variables define:name
                         with:[NSNumber numberWithUnsignedLongLong:defaultValue]
                         kind:CT_KIND_INT];
}

- (CTVar *)defineVar:(NSString *)name withUnsignedShort:(unsigned short)defaultValue {
    return [self.variables define:name
                         with:[NSNumber numberWithUnsignedShort:defaultValue]
                         kind:CT_KIND_INT];
}

- (CTVar *)defineVar:(NSString *)name withString:(NSString *)defaultValue {
    return [self.variables define:name with:defaultValue kind:CT_KIND_STRING];
}

- (CTVar *)defineVar:(NSString *)name withNumber:(NSNumber *)defaultValue {
    return [self.variables define:name with:defaultValue kind:CT_KIND_FLOAT];
}

- (CTVar *)defineVar:(NSString *)name withDictionary:(NSDictionary *)defaultValue {
    return [self.variables define:name with:defaultValue kind:CT_KIND_DICTIONARY];
}

- (CTVar *)defineFileVar:(NSString *)name {
    return [self.variables define:name with:nil kind:CT_KIND_FILE];
}

@end

//
//  CTInAppDisplayManager.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 3.10.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//
#import "CleverTapInternal.h"
#import "CTInAppDisplayManager.h"
#import "CTPreferences.h"
#import "CTConstants.h"
#import "CTInAppNotification.h"
#import "CTInAppDisplayViewController.h"
#import "CleverTapJSInterface.h"
#import "CTInAppFCManager.h"
#import "CTDeviceInfo.h"
#import "CTEventBuilder.h"
#import "CTUtils.h"
#import "CTUIUtils.h"
#import "CleverTapURLDelegate.h"

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
#import "CleverTap+InAppNotifications.h"
#import "CTLocalInApp.h"
#import "CleverTap+PushPermission.h"
#import "CleverTapJSInterfacePrivate.h"

#import "CTCustomTemplatesManager-Internal.h"
#import "CTCustomTemplateInAppData-Internal.h"
#endif

#if !(TARGET_OS_TV)
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDAnimatedImageView.h>
#endif

static const void *const kNotificationQueueKey = &kNotificationQueueKey;
static const NSString *kInAppNotificationKey = @"inAppNotification";

// static here as we may have multiple instances handling inapps
static CTInAppDisplayViewController *currentDisplayController;
static CTInAppNotification *currentlyDisplayingNotification;
static NSMutableArray<NSArray *> *pendingNotifications;

// private class
@interface ImageLoadingResult : NSObject

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSData *imageData;
@property (nonatomic, copy) NSString *error;

@end

@implementation ImageLoadingResult

@end

@interface CTInAppDisplayManager() <CTInAppNotificationDisplayDelegate> {
}

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, assign) CleverTapInAppRenderingStatus inAppRenderingStatus;

@property (nonatomic, strong) CTDispatchQueueManager *dispatchQueueManager;

@property (nonatomic, strong) CTInAppFCManager *inAppFCManager;
@property (nonatomic, strong) CTInAppStore *inAppStore;

@property (nonatomic, weak) CleverTap* instance;

@property (nonatomic, strong) CTFileDownloader *fileDownloader;

@property (nonatomic, strong) CTCustomTemplatesManager *templatesManager;

@property (nonatomic, strong, readonly) NSString *imageInterstitialHtml;

@end

@implementation CTInAppDisplayManager

@synthesize imageInterstitialHtml = _imageInterstitialHtml;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pendingNotifications = [NSMutableArray new];
    });
}

- (instancetype _Nonnull)initWithCleverTap:(CleverTap * _Nonnull)instance
                            dispatchQueueManager:(CTDispatchQueueManager * _Nonnull)dispatchQueueManager
                            inAppFCManager:(CTInAppFCManager *)inAppFCManager
                         impressionManager:(CTImpressionManager *)impressionManager
                                inAppStore:(CTInAppStore *)inAppStore
                          templatesManager:(CTCustomTemplatesManager *)templatesManager
                            fileDownloader:(CTFileDownloader *)fileDownloader {
    if ((self = [super init])) {
        self.dispatchQueueManager = dispatchQueueManager;
        self.instance = instance;
        self.config = instance.config;
        self.inAppFCManager = inAppFCManager;
        self.inAppStore = inAppStore;
        self.templatesManager = templatesManager;
        self.fileDownloader = fileDownloader;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDisplayPendingNotification:)
                                                     name:[self.class pendingNotificationKey:self.config.accountId]
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:[self.class pendingNotificationKey:self.config.accountId]
                                                  object:nil];
}

- (void)setPushPrimerManager:(CTPushPrimerManager *)pushPrimerManagerObj {
    pushPrimerManager = pushPrimerManagerObj;
}

#pragma mark - CleverTapInAppNotificationDelegate
@synthesize inAppNotificationDelegate = _inAppNotificationDelegate;

- (void)setInAppNotificationDelegate:(id <CleverTapInAppNotificationDelegate>)delegate {
    if ([CTUIUtils runningInsideAppExtension]){
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

#pragma mark - InApp Notifications Queue

- (void)_addInAppNotificationsToQueue:(NSArray *)inappNotifs {
    @try {
        NSArray *filteredInAppNotifs = [self filterNonRegisteredTemplates:inappNotifs];
        [self.inAppStore enqueueInApps:filteredInAppNotifs];
        
        [CTUtils runSyncMainQueue:^{
            if (!self.isAppActiveForeground) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Application is not in the foreground, won't try to show in-app if available.", self);
                return;
            }
            
            // Fire the first notification, if any
            [self.dispatchQueueManager runOnNotificationQueue:^{
                [self _showNotificationIfAvailable];
            }];
        }];
    } @catch (NSException *e) {
        CleverTapLogInternal(self.config.logLevel, @"%@: InApp notification handling error: %@", self, e.debugDescription);
    }
}

- (void)_addInAppNotificationInFrontOfQueue:(CTInAppNotification *)inappNotif {
    @try {
        NSString *templateName = inappNotif.customTemplateInAppData.templateName;
        if ([self.templatesManager isRegisteredTemplateWithName:templateName]) {
            [self.inAppStore insertInFrontInApp:inappNotif.jsonDescription];
            
            if (!self.isAppActiveForeground) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Application is not in the foreground, won't try to show in-app if available.", self);
                return;
            }
            // Fire the first notification, if any
            [self.dispatchQueueManager runOnNotificationQueue:^{
                [self _showNotificationIfAvailable];
            }];
        }
    } @catch (NSException *e) {
        CleverTapLogInternal(self.config.logLevel, @"%@: InApp notification handling error: %@", self, e.debugDescription);
    }
}

- (NSArray *)filterNonRegisteredTemplates:(NSArray *)inappNotifs {
    NSMutableArray *filteredInAppNotifs = [NSMutableArray new];
    for (NSDictionary *inAppJSON in inappNotifs) {
        if ([self isTemplateRegistered:inAppJSON]) {
            [filteredInAppNotifs addObject:inAppJSON];
        }
    }
    return filteredInAppNotifs;
}

- (BOOL)isTemplateRegistered:(NSDictionary *)inAppJSON {
    CTCustomTemplateInAppData *customTemplateData = [CTCustomTemplateInAppData createWithJSON:inAppJSON];
    
    if (customTemplateData) {
        if ([self.templatesManager isRegisteredTemplateWithName:customTemplateData.templateName]) {
            return YES;
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Template with name: \"%@\" is not registered and cannot be presented.", self, customTemplateData.templateName);
            return NO;
        }
    } else {
        return YES;
    }
}

- (void)_showInAppNotificationIfAny {
    if ([CTUIUtils runningInsideAppExtension]){
        CleverTapLogDebug(self.config.logLevel, @"%@: showInAppNotificationIfAny is a no-op in an app extension.", self);
        return;
    }
    if (!self.config.analyticsOnly) {
        if (!self.isAppActiveForeground) {
            CleverTapLogInternal(self.config.logLevel, @"%@: Application is not in the foreground, won't try to show in-app if any.", self);
            return;
        }
        
        [self.dispatchQueueManager runOnNotificationQueue:^{
            [self _showNotificationIfAvailable];
        }];
    }
}

- (void)_suspendInAppNotifications {
    if ([CTUIUtils runningInsideAppExtension]) {
        CleverTapLogDebug(self.config.logLevel, @"%@: suspendInAppNotifications is a no-op in an app extension.", self);
        return;
    }
    if (!self.config.analyticsOnly) {
        self.inAppRenderingStatus = CleverTapInAppSuspend;
        CleverTapLogDebug(self.config.logLevel, @"%@: InApp Notifications will be suspended till resumeInAppNotifications() is not called again", self);
    }
}

- (void)_discardInAppNotifications {
    if ([CTUIUtils runningInsideAppExtension]) {
        CleverTapLogDebug(self.config.logLevel, @"%@: discardInAppNotifications is a no-op in an app extension.", self);
        return;
    }
    if (!self.config.analyticsOnly) {
        self.inAppRenderingStatus = CleverTapInAppDiscard;
        CleverTapLogDebug(self.config.logLevel, @"%@: InApp Notifications will be discarded till resumeInAppNotifications() is not called again", self);
    }
}

- (void)_resumeInAppNotifications {
    if ([CTUIUtils runningInsideAppExtension]) {
        CleverTapLogDebug(self.config.logLevel, @"%@: resumeInAppNotifications is a no-op in an app extension.", self);
        return;
    }
    if (!self.config.analyticsOnly) {
        self.inAppRenderingStatus = CleverTapInAppResume;
        CleverTapLogDebug(self.config.logLevel, @"%@: Resuming inApp Notifications", self);
    }
}

- (void)_showNotificationIfAvailable {
    if ([CTUIUtils runningInsideAppExtension]) return;

    if (self.inAppRenderingStatus == CleverTapInAppSuspend) {
        CleverTapLogDebug(self.config.logLevel, @"%@: InApp Notifications are set to be suspended, not showing the InApp Notification", self);
        return;
    }

    @try {
        NSDictionary *inApp = [self.inAppStore peekInApp];
        if (inApp) {
            // Prepare the in-app for display
            [self prepareNotificationForDisplay:inApp];
            // Remove in-app after prepare
            [self.inAppStore dequeueInApp];
        }
    } @catch (NSException *e) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Problem showing InApp: %@", self, e.debugDescription);
    }
}

- (void)prepareNotificationForDisplay:(NSDictionary*)jsonObj {
    if (self.inAppRenderingStatus == CleverTapInAppDiscard) {
        CleverTapLogDebug(self.config.logLevel, @"%@: InApp Notifications are set to be discarded, not saving and showing the InApp Notification", self);
        return;
    }
    
    [self.dispatchQueueManager runOnNotificationQueue:^{
        CleverTapLogInternal(self.config.logLevel, @"%@: processing inapp notification: %@", self, jsonObj);
        __block CTInAppNotification *notification = [[CTInAppNotification alloc] initWithJSON:jsonObj];
        if (notification.error) {
            CleverTapLogInternal(self.config.logLevel, @"%@: unable to parse inapp notification: %@ error: %@", self, jsonObj, notification.error);
            return;
        }

        NSTimeInterval now = (int)[[NSDate date] timeIntervalSince1970];
        if (now > notification.timeToLive) {
            CleverTapLogInternal(self.config.logLevel, @"%@: InApp has elapsed its time to live, not showing the InApp: %@ wzrk_ttl: %lu", self, jsonObj, (unsigned long)notification.timeToLive);
            return;
        }
        
        [self prepareNotification:notification withCompletion:^{
            [CTUtils runSyncMainQueue:^{
                [self notificationReady:notification];
            }];
        }];
    }];
}

- (void)prepareNotification:(CTInAppNotification *)notification withCompletion:(void (^)(void))completionHandler {
#if !(TARGET_OS_TV)
    if ([NSThread isMainThread]) {
        notification.error = [NSString stringWithFormat:@"[%@ prepareWithCompletionHandler] should not be called on the main thread", [self class]];
        completionHandler();
        return;
    }
    
    if (notification.imageURL) {
        ImageLoadingResult *result = [self loadImageWithURL:notification.imageURL contentType:notification.contentType];
        [notification setPreparedInAppImage:result.image inAppImageData:result.imageData error:result.error];
    }
    if (notification.imageUrlLandscape && notification.hasLandscape) {
        ImageLoadingResult *result = [self loadImageWithURL:notification.imageUrlLandscape contentType:notification.landscapeContentType];
        [notification setPreparedInAppImageLandscape:result.image inAppImageLandscapeData:result.imageData error:result.error];
    }
    
    NSArray *urls = [[self.templatesManager fileArgsURLsForInAppData:notification.customTemplateInAppData] allObjects];
    if (urls.count > 0) {
        [self.fileDownloader downloadFiles:urls withCompletionBlock:^(NSDictionary<NSString *,NSNumber *> * _Nonnull status) {
            for (NSString *url in status) {
                if (![status[url] boolValue]) {
                    notification.error = @"Failed to download custom template files.";
                    break;
                }
            }
            completionHandler();
        }];
        return;
    }
    
#endif
    
    completionHandler();
}

- (ImageLoadingResult *)loadImageWithURL:(NSURL *)url contentType:(NSString *)contentType {
    ImageLoadingResult *result = [[ImageLoadingResult alloc] init];
    
    UIImage *loadedImage = [self loadImageIfPresentInDiskCache:url];
    if (loadedImage) {
        result.image = loadedImage;
    } else {
        NSError *loadError = nil;
        NSData *imageData = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&loadError];
        if (loadError || !imageData) {
            result.error = [NSString stringWithFormat:@"unable to load image from URL: %@", url];
        } else {
            if ([contentType isEqualToString:@"image/gif"]) {
                SDAnimatedImage *gif = [SDAnimatedImage imageWithData:imageData];
                if (gif == nil) {
                    result.error = [NSString stringWithFormat:@"unable to decode gif for URL: %@", url];
                }
            }
            result.imageData = imageData;
        }
    }
    
    return result;
}

- (UIImage *)loadImageIfPresentInDiskCache:(NSURL *)imageURL {
    NSString *imageURLString = [imageURL absoluteString];
    UIImage *image = [self.fileDownloader loadImageFromDisk:imageURLString];
    if (image) return image;
    return nil;
}

- (void)notificationReady:(CTInAppNotification*)notification {
    if (![NSThread isMainThread]) {
        [CTUtils runSyncMainQueue:^{
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
        [CTUtils runSyncMainQueue:^{
            [self displayNotification:notification];
        }];
        return;
    }

    if (!self.isAppActiveForeground) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Application is not in the foreground, not displaying in-app: %@", self, notification.jsonDescription);
        return;
    }

    if (![self.inAppFCManager canShow:notification]) {
        CleverTapLogInternal(self.config.logLevel, @"%@: InApp %@ has been rejected by FC, not showing", self, notification.campaignId);
        [self _showInAppNotificationIfAny];  // auto try the next one
        return;
    }
    
    // if we are currently displaying a notification, cache this notification for later display
    if (currentlyDisplayingNotification) {
        if (self.config.accountId && notification) {
            [pendingNotifications addObject:@[self.config.accountId, notification]];
            CleverTapLogDebug(self.config.logLevel, @"%@: InApp already displaying, queueing to pending InApps", self);
        }
        return;
    }
    
    BOOL isHTMLType = (notification.inAppType == CTInAppTypeHTML);
    BOOL isInternetAvailable = self.instance.deviceInfo.isOnline;
    if (isHTMLType && !isInternetAvailable) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Not showing HTML InApp %@ due to no internet. An active internet connection is required to display the HTML InApp", self, notification.campaignId);
        [self _showInAppNotificationIfAny];  // auto try the next one
        return;
    }

    BOOL goFromDelegate = YES;
    if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(shouldShowInAppNotificationWithExtras:)]) {
        goFromDelegate = [self.inAppNotificationDelegate shouldShowInAppNotificationWithExtras:notification.customExtras];
    }

    if (!goFromDelegate) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Application has decided to not show this InApp: %@", self, notification.campaignId ? notification.campaignId : @"<unknown ID>");
        [self _showInAppNotificationIfAny];  // auto try the next one
        return;
    }

    CTInAppDisplayViewController *controller;
    NSString *errorString = nil;
    switch (notification.inAppType) {
        case CTInAppTypeHTML:
            controller = [[CTInAppHTMLViewController alloc] initWithNotification:notification config:self.config];
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
        case CTInAppTypeCustom:
            if ([self.templatesManager presentNotification:notification 
                                              withDelegate:self
                                         andFileDownloader:self.fileDownloader]) {
                currentlyDisplayingNotification = notification;
            } else {
                errorString = [NSString stringWithFormat:@"Cannot present custom notification with template name: %@.",
                               notification.customTemplateInAppData.templateName];
            }
            break;
        default:
            errorString = [NSString stringWithFormat:@"Unhandled notification type: %lu", (unsigned long)notification.inAppType];
            break;
    }
    if (controller) {
        currentlyDisplayingNotification = notification;
        CleverTapLogDebug(self.config.logLevel, @"%@: Will show new InApp: %@", self, notification.campaignId);
        controller.delegate = self;
        [[self class] displayInAppDisplayController:controller];

        // Update local in-app count only if it is from local push primer.
        if (notification.isLocalInApp && !notification.isPushSettingsSoftAlert) {
            [self.inAppFCManager incrementLocalInAppCount];
        }
    }
    if (errorString) {
        CleverTapLogDebug(self.config.logLevel, @"%@: %@", self, errorString);
    }
#endif
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

- (BOOL)isAppActiveForeground {
    UIApplication *app = [CTUIUtils getSharedApplication];
    if (app != nil) {
        return [app applicationState] == UIApplicationStateActive;
    }
    return NO;
}

#pragma mark - Pending Notification

- (void)onDisplayPendingNotification:(NSNotification *)notification {
    currentlyDisplayingNotification = nil;
    CleverTapLogDebug(self.config.logLevel, @"%@: Displaying pending notification.", self);
    [self displayNotification:notification.userInfo[kInAppNotificationKey]];
}

#pragma mark - InAppDisplayController static
+ (void)displayInAppDisplayController:(CTInAppDisplayViewController*)controller {
    currentDisplayController = controller;
    [controller show:YES];
}

+ (void)inAppDisplayControllerDidDismiss:(CTInAppDisplayViewController*)controller {
    if (controller) {
        if (currentDisplayController && currentDisplayController == controller) {
            currentDisplayController = nil;
            [self checkPendingNotifications];
        }
    } else {
        [self checkPendingNotifications];
    }
}

// static display handling as we may have more than one instance competing to show an inapp
+ (void)checkPendingNotifications {
    if (pendingNotifications && [pendingNotifications count] > 0) {
        NSArray *pendingNotification = [pendingNotifications objectAtIndex:0];
        [pendingNotifications removeObjectAtIndex:0];
        NSString *accountId = [pendingNotification objectAtIndex:0];
        CTInAppNotification *inAppNotification = [pendingNotification objectAtIndex:1];
        [[NSNotificationCenter defaultCenter] postNotificationName:[self pendingNotificationKey:accountId] object:nil userInfo:@{kInAppNotificationKey: inAppNotification}];
    } else {
        currentlyDisplayingNotification = nil;
    }
}

+ (NSString *)pendingNotificationKey:(NSString *)accountId {
    return [NSString stringWithFormat:@"%@:%@:onDisplayPendingNotification", [self class], accountId];
}

#pragma mark - CTInAppNotificationDisplayDelegate

- (void)notificationDidDismiss:(CTInAppNotification*)notification fromViewController:(CTInAppDisplayViewController*)controller {
    CleverTapLogInternal(self.config.logLevel, @"%@: InApp did dismiss: %@", self, notification.campaignId);
    [self notifyNotificationDismissed:notification];
    [[self class] inAppDisplayControllerDidDismiss:controller];
    [self _showInAppNotificationIfAny];
}

- (void)notificationDidShow:(CTInAppNotification*)notification {
    CleverTapLogInternal(self.config.logLevel, @"%@: InApp did show: %@", self, notification.campaignId);
    [self.instance recordInAppNotificationStateEvent:NO forNotification:notification andQueryParameters:nil];
    [self.inAppFCManager didShow:notification];
}

- (void)notifyNotificationButtonTappedWithCustomExtras:(NSDictionary *)customExtras {
    if (self.inAppNotificationDelegate && [self.inAppNotificationDelegate respondsToSelector:@selector(inAppNotificationButtonTappedWithCustomExtras:)]) {
        [self.inAppNotificationDelegate inAppNotificationButtonTappedWithCustomExtras:customExtras];
    }
}

- (void)handleNotificationAction:(CTNotificationAction *)action forNotification:(CTInAppNotification *)notification withExtras:(NSDictionary *)extras {
    CleverTapLogInternal(self.config.logLevel, @"%@: handle InApp action type:%@ with cta: %@ button custom extras: %@ with options:%@", self, [CTInAppUtils inAppActionTypeString:action.type], action.actionURL.absoluteString, action.keyValues, extras);
    // record the notification clicked event
    [self.instance recordInAppNotificationStateEvent:YES forNotification:notification andQueryParameters:extras];
    
    // add the action extras so they can be passed to the dismissedWithExtras delegate
    if (extras) {
        notification.actionExtras = extras;
    }
    
    switch (action.type) {
        case CTInAppActionTypeUnknown:
            CleverTapLogDebug(self.config.logLevel, @"%@: Triggered in-app action with unknown type.", self);
            break;
        case CTInAppActionTypeClose:
            // SDK in-apps are dismissed in CTInAppDisplayViewController buttonTapped: or tappedDismiss
            if (notification.inAppType == CTInAppTypeCustom) {
                [self.templatesManager closeNotification:notification];
            }
            break;
        case CTInAppActionTypeOpenURL:
            [self handleCTAOpenURL:action.actionURL];
            break;
        case CTInAppActionTypeKeyValues:
            if (action.keyValues && action.keyValues.count > 0) {
                CleverTapLogDebug(self.config.logLevel, @"%@: InApp: button tapped with custom extras: %@", self, action.keyValues);
                [self notifyNotificationButtonTappedWithCustomExtras:action.keyValues];
            }
            break;
        case CTInAppActionTypeCustom:
            [self triggerCustomTemplateAction:action.customTemplateInAppData forNotification:notification];
            break;
        case CTInAppActionTypeRequestForPermission:
            // Handled in CTInAppDisplayViewController handleButtonClickFromIndex:
            break;
    }
}

- (void)handleCTAOpenURL:(NSURL *)ctaURL {
#if !CLEVERTAP_NO_INAPP_SUPPORT
        if (self.instance.urlDelegate) {
            // URL DELEGATE FOUND. OPEN DEEP LINKS ONLY IF USER ALLOWS IT
            if ([self.instance.urlDelegate respondsToSelector: @selector(shouldHandleCleverTapURL: forChannel:)] && [self.instance.urlDelegate shouldHandleCleverTapURL: ctaURL forChannel: CleverTapInAppNotification]) {
                [CTUtils runSyncMainQueue:^{
                    [CTUIUtils openURL:ctaURL forModule:@"InApp"];
                }];
            }
        }
        else {
            // OPEN DEEP LINKS BY DEFAULT
            [CTUtils runSyncMainQueue:^{
                [CTUIUtils openURL:ctaURL forModule:@"InApp"];
            }];
        }
#endif
}

- (void)triggerCustomTemplateAction:(CTCustomTemplateInAppData *)actionData forNotification:(CTInAppNotification *)notification {
    if (actionData && actionData.templateName) {
        if ([self.templatesManager isRegisteredTemplateWithName:actionData.templateName]) {
            CTCustomTemplateInAppData *inAppData = [actionData copy];
            [inAppData setIsAction:YES];
            CTInAppNotification *notificationFromAction = [self createNotificationForAction:inAppData andParentNotification:notification];
            
            if ([self.templatesManager isVisualTemplateWithName:inAppData.templateName]) {
                [self _addInAppNotificationInFrontOfQueue:notificationFromAction];
            } else {
                NSSet *fileURLs = [self.templatesManager fileArgsURLsForInAppData:notificationFromAction.customTemplateInAppData];
                [self.fileDownloader downloadFiles:[fileURLs allObjects] withCompletionBlock:^(NSDictionary<NSString *,NSNumber *> * _Nonnull status) {
                    for (NSString *url in status) {
                        if (![status[url] boolValue]) {
                            CleverTapLogDebug(self.config.logLevel, @"%@: Cannot trigger action due to file download error.", [self class]);
                            return;
                        }
                    }
                    [CTUtils runSyncMainQueue:^{
                        [self.templatesManager presentNotification:notificationFromAction withDelegate:self andFileDownloader:self.fileDownloader];
                    }];
                }];
            }
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: Cannot trigger non-registered template with name: %@", [self class], actionData.templateName);
        }
    } else {
        CleverTapLogDebug(self.config.logLevel, @"%@: Cannot trigger action without template name.", [self class]);
    }
}

- (CTInAppNotification *)createNotificationForAction:(CTCustomTemplateInAppData *)inAppData andParentNotification:(CTInAppNotification *)notification {
    NSMutableDictionary *json = [@{
        CLTAP_INAPP_ID: notification.Id ? notification.Id : @"",
        CLTAP_PROP_WZRK_ID: notification.campaignId ? notification.campaignId : @"",
        CLTAP_INAPP_TYPE: [CTInAppUtils inAppTypeString:CTInAppTypeCustom],
        CLTAP_INAPP_EXCLUDE_GLOBAL_CAPS: @(YES),
        CLTAP_INAPP_EXCLUDE_FROM_CAPS: @(YES),
        CLTAP_INAPP_TTL: @(notification.timeToLive)
    } mutableCopy];
    
    if (notification.jsonDescription[CLTAP_NOTIFICATION_PIVOT]) {
        json[CLTAP_NOTIFICATION_PIVOT] = notification.jsonDescription[CLTAP_NOTIFICATION_PIVOT];
    }
    if (notification.jsonDescription[CLTAP_NOTIFICATION_CONTROL_GROUP_ID]) {
        json[CLTAP_NOTIFICATION_CONTROL_GROUP_ID] = notification.jsonDescription[CLTAP_NOTIFICATION_CONTROL_GROUP_ID];
    }
    
    [json addEntriesFromDictionary:inAppData.json];
    
    return [[CTInAppNotification alloc] initWithJSON:json];
}

- (void)handleInAppPushPrimer:(CTInAppNotification *)notification
           fromViewController:(CTInAppDisplayViewController *)controller
       withFallbackToSettings:(BOOL)isFallbackToSettings {
    CleverTapLogDebug(self.config.logLevel, @"%@: InApp Push Primer Accepted:", self);
    [pushPrimerManager promptForOSPushNotificationWithFallbackToSettings:isFallbackToSettings
                                       andSkipSettingsAlert:notification.skipSettingsAlert];
    
}

- (void)inAppPushPrimerDidDismissed {
    [pushPrimerManager notifyPushPermissionResponse:NO];
}

#pragma mark - Handle InApp test from Push
- (BOOL)didHandleInAppTestFromPushNotificaton:(NSDictionary * _Nullable)notification {
#if !CLEVERTAP_NO_INAPP_SUPPORT
    if ([CTUIUtils runningInsideAppExtension]) {
        return NO;
    }
    
    if (!notification || [notification count] <= 0 || !notification[@"wzrk_inapp"]) return NO;
    
    @try {
        [self.instance.impressionManager resetSession];
        CleverTapLogDebug(self.config.logLevel, @"%@: Received in-app notification from push payload: %@", self, notification);
        
        NSString *jsonString = notification[@"wzrk_inapp"];
        
        NSMutableDictionary *inapp = [[NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
                                                                      options:0
                                                                        error:nil] mutableCopy];
        if (!inapp) {
            CleverTapLogDebug(self.config.logLevel, @"%@: Failed to parse the inapp notification as JSON", self);
            return YES;
        }
        
        // Handle Image Interstitial and Advanced Builder InApp Test (Preview)
        NSString *inAppPreviewType = notification[CLTAP_INAPP_PREVIEW_TYPE];
        if ([inAppPreviewType isEqualToString:CLTAP_INAPP_IMAGE_INTERSTITIAL_TYPE] || [inAppPreviewType isEqualToString:CLTAP_INAPP_ADVANCED_BUILDER_TYPE]) {
            NSMutableDictionary *htmlInapp = [self handleHTMLInAppPreview:inapp];
            if (!htmlInapp) {
                return YES; // Failed to handle HTML inapp
            }
            inapp = htmlInapp;
        }
        
        float delay = self.isAppActiveForeground ? 0.5 : 2.0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @try {
                [self prepareNotificationForDisplay:inapp];
            } @catch (NSException *e) {
                CleverTapLogDebug(self.config.logLevel, @"%@: Failed to display the inapp notifcation from payload: %@", self, e.debugDescription);
            }
        });
    } @catch (NSException *e) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Failed to display the inapp notifcation from payload: %@", self, e.debugDescription);
        return YES;
    }
    
#endif
    return YES;
}

- (NSString *)imageInterstitialHtml {
    if (!_imageInterstitialHtml) {
        NSString *path = [[CTInAppUtils bundle] pathForResource:CLTAP_INAPP_IMAGE_INTERSTITIAL_HTML_NAME ofType:@"html"];
        NSData *data = [NSData dataWithContentsOfFile:path];
        _imageInterstitialHtml = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return _imageInterstitialHtml;
}

- (NSString *)wrapImageInterstitialContent:(NSString *)content {
    NSString *html = [self imageInterstitialHtml];
    if (html && content) {
        NSArray *parts = [html componentsSeparatedByString:CLTAP_INAPP_HTML_SPLIT];
        if ([parts count] == 2) {
            return [NSString stringWithFormat:@"%@%@%@", parts[0], content, parts[1]];
        }
    }
    return nil;
}

- (NSMutableDictionary *)handleHTMLInAppPreview:(NSMutableDictionary *)inapp {
    NSMutableDictionary *htmlInapp = [inapp mutableCopy];
    NSString *config = [htmlInapp valueForKeyPath:CLTAP_INAPP_IMAGE_INTERSTITIAL_CONFIG];
    NSString *htmlContent = [self wrapImageInterstitialContent:[CTUtils jsonObjectToString:config]];
    if (config && htmlContent) {
        htmlInapp[@"type"] = CLTAP_INAPP_HTML_TYPE;
        id data = htmlInapp[CLTAP_INAPP_DATA_TAG];
        if (data && [data isKindOfClass:[NSDictionary class]]) {
            data = [data mutableCopy];
            // Update the html
            data[CLTAP_INAPP_HTML] = htmlContent;
        } else {
            // If data key is not present or it is not a dictionary,
            // set it and overwrite it
            htmlInapp[CLTAP_INAPP_DATA_TAG] = @{
                CLTAP_INAPP_HTML: htmlContent
            };
        }
        return htmlInapp;
    } else {
        CleverTapLogDebug(self.config.logLevel, @"%@: Failed to parse the image-interstitial notification", self);
        return nil;
    }
}

@end


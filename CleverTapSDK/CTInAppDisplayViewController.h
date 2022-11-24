#import <UIKit/UIKit.h>
#import "CTInAppNotification.h"
#if !(TARGET_OS_TV)
#import "CleverTapJSInterface.h"
#endif

@class CTInAppDisplayViewController;

@protocol CTInAppNotificationDisplayDelegate <NSObject>
- (void)handleNotificationCTA:(NSURL*)ctaURL buttonCustomExtras:(NSDictionary *)buttonCustomExtras forNotification:(CTInAppNotification*)notification fromViewController:(CTInAppDisplayViewController*)controller withExtras:(NSDictionary*)extras;
- (void)notificationDidDismiss:(CTInAppNotification*)notification fromViewController:(CTInAppDisplayViewController*)controller;
/**
 Called when in-app button is tapped for requesting push permission.
 */
- (void)handleInAppPushPrimer:(CTInAppNotification*)notification
           fromViewController:(CTInAppDisplayViewController*)controller
       withFallbackToSettings:(BOOL)isFallbackToSettings;

/**
 Called to notify that local in-app push primer is dismissed.
 */
- (void)inAppPushPrimerDidDismissed;
@optional
- (void)notificationDidShow:(CTInAppNotification*)notification fromViewController:(CTInAppDisplayViewController*)controller;
@end

@interface CTInAppDisplayViewController : UIViewController

@property (nonatomic, weak) id <CTInAppNotificationDisplayDelegate> delegate;
@property (nonatomic, strong, readonly) CTInAppNotification *notification;

- (instancetype)init __unavailable;
- (instancetype)initWithNotification:(CTInAppNotification*)notification;
#if !(TARGET_OS_TV)
- (instancetype)initWithNotification:(CTInAppNotification*)notification jsInterface:(CleverTapJSInterface *)jsInterface;
#endif

- (void)show:(BOOL)animated;
- (void)hide:(BOOL)animated;
- (BOOL)deviceOrientationIsLandscape;

@end

#import <UIKit/UIKit.h>
#import "CTInAppNotification.h"
#if !(TARGET_OS_TV)
#import "CleverTapJSInterface.h"
#endif

@class CTInAppDisplayViewController;

@protocol CTInAppNotificationDisplayDelegate <NSObject>
- (void)handleNotificationCTA:(NSURL*)ctaURL buttonCustomExtras:(NSDictionary *)buttonCustomExtras forNotification:(CTInAppNotification*)notification fromViewController:(CTInAppDisplayViewController*)controller withExtras:(NSDictionary*)extras;
- (void)notificationDidDismiss:(CTInAppNotification*)notification fromViewController:(CTInAppDisplayViewController*)controller;
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

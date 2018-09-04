#import <UIKit/UIKit.h>
#import "CTInAppNotification.h"

@class CTInAppDisplayViewController;

@protocol CTInAppNotificationDisplayDelegate <NSObject>
- (void)handleNotificationCTA:(NSURL*)ctaURL forNotification:(CTInAppNotification*)notification fromViewController:(CTInAppDisplayViewController*)controller withExtras:(NSDictionary*)extras;
- (void)notificationDidDismiss:(CTInAppNotification*)notification fromViewController:(CTInAppDisplayViewController*)controller;
@optional
- (void)notificationDidShow:(CTInAppNotification*)notification fromViewController:(CTInAppDisplayViewController*)controller;
@end

@interface CTInAppDisplayViewController : UIViewController

@property (nonatomic, weak) id <CTInAppNotificationDisplayDelegate> delegate;
@property (nonatomic, strong, readonly) CTInAppNotification *notification;

- (instancetype)init __unavailable;
- (instancetype)initWithNotification:(CTInAppNotification*)notification;

- (void)show:(BOOL)animated;
- (void)hide:(BOOL)animated;

@end

#import <UIKit/UIKit.h>
#import "CTInAppNotification.h"
#import "CTInAppNotificationDisplayDelegate.h"
#if !(TARGET_OS_TV)
#import "CleverTapJSInterface.h"
#endif

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

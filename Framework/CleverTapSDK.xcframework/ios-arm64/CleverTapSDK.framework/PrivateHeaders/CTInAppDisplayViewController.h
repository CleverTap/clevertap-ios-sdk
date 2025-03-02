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

- (void)initializeWindowOfClass:(Class)windowClass animated:(BOOL)animated;

- (void)show:(BOOL)animated;
- (void)hide:(BOOL)animated;
- (BOOL)deviceOrientationIsLandscape;

- (void)triggerInAppAction:(CTNotificationAction *)action callToAction:(NSString *)callToAction buttonId:(NSString *)buttonId;

@end

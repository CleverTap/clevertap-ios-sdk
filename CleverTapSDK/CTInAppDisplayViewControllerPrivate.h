#import <UIKit/UIKit.h>
#import "CTConstants.h"

@interface CTInAppPassThroughWindow : UIWindow
@end

@protocol CTInAppPassThroughViewDelegate <NSObject>
@required
- (void)viewWillPassThroughTouch;
@end

@interface CTInAppPassThroughView : UIView
@property (nonatomic, weak) id<CTInAppPassThroughViewDelegate> delegate;
@end

@interface CTInAppDisplayViewController () <CTInAppPassThroughViewDelegate> {
}

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong, readwrite) CTInAppNotification *notification;
@property (nonatomic, assign) BOOL shouldPassThroughTouches;
// Guards against raising more than one Notification Clicked event for a single
// in-app display (e.g. repeated tap-outside/swipe gestures while the in-app is
// still animating out).
@property (nonatomic, assign) BOOL actionTriggered;

- (void)showFromWindow:(BOOL)animated;
- (void)hideFromWindow:(BOOL)animated;
- (void)hideFromWindow:(BOOL)animated withCompletion:(void (^)(void))completion;

- (void)tappedDismiss;
- (void)buttonTapped:(UIButton*)button;
- (void)triggerCloseActionWithCallToAction:(NSString *)callToAction elementId:(NSString *)elementId;
- (void)handleButtonClickFromIndex:(int)index;
- (void)handleImageTapGesture;
// Raises the Notification Clicked event for the given action, enriching the
// extras with the Split of Clicks descriptors (wzrk_action / wzrk_data) and
// deduping repeated triggers. Returns NO if an action was already triggered.
- (BOOL)notifyDelegateActionTriggered:(CTNotificationAction *)action withExtras:(NSMutableDictionary *)extras;
- (UIButton*)setupViewForButton:(UIButton *)buttonView withData:(CTNotificationButton *)button withIndex:(NSInteger)index;

@end

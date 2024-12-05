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

- (void)showFromWindow:(BOOL)animated;
- (void)hideFromWindow:(BOOL)animated;
- (void)hideFromWindow:(BOOL)animated withCompletion:(void (^)(void))completion;

- (void)tappedDismiss;
- (void)buttonTapped:(UIButton*)button;
- (void)handleButtonClickFromIndex:(int)index;
- (void)handleImageTapGesture;
- (UIButton*)setupViewForButton:(UIButton *)buttonView withData:(CTNotificationButton *)button withIndex:(NSInteger)index;

@end

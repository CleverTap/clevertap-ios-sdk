#import <UIKit/UIKit.h>

@protocol CTInboxActionViewDelegate <NSObject>
@required
- (void)handleInboxNotificationAtIndex:(int)index;
@end

NS_ASSUME_NONNULL_BEGIN

@interface CTInboxMessageActionView : UIView

@property (strong, nonatomic) IBOutlet UIButton *firstButton;
@property (strong, nonatomic) IBOutlet UIButton *secondButton;
@property (strong, nonatomic) IBOutlet UIButton *thirdButton;
@property (nonatomic, weak) id<CTInboxActionViewDelegate> delegate;

- (UIButton*)setupViewForButton:(UIButton *)buttonView forText:(NSDictionary *)messageButton withIndex:(int)index;

@end

NS_ASSUME_NONNULL_END

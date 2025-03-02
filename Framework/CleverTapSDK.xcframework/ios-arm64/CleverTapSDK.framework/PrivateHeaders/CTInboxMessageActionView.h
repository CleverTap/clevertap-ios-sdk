#import <UIKit/UIKit.h>

@protocol CTInboxActionViewDelegate <NSObject>
@required
- (void)handleInboxMessageTappedAtIndex:(int)index;
@end

NS_ASSUME_NONNULL_BEGIN

@interface CTInboxMessageActionView : UIView

@property (strong, nonatomic) IBOutlet UIButton *firstButton;
@property (strong, nonatomic) IBOutlet UIButton *secondButton;
@property (strong, nonatomic) IBOutlet UIButton *thirdButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *secondButtonWidthConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *thirdButtonWidthConstraint;
@property (nonatomic, weak) id<CTInboxActionViewDelegate> delegate;

- (UIButton*)setupViewForButton:(UIButton *)buttonView forText:(NSDictionary *)messageButton withIndex:(int)index;

@end

NS_ASSUME_NONNULL_END

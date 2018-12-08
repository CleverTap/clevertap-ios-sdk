#import <UIKit/UIKit.h>
#import "CleverTap+Inbox.h"

@protocol CTInboxActionViewDelegate <NSObject>
@required
- (void)inboxButtonDidTapped;
@end

NS_ASSUME_NONNULL_BEGIN

@interface CTInboxActionView : UIView

@property (strong, nonatomic) IBOutlet UIButton *firstButton;
@property (strong, nonatomic) IBOutlet UIButton *secondButton;
@property (strong, nonatomic) IBOutlet UIButton *thirdButton;
@property (nonatomic, weak) id<CTInboxActionViewDelegate> delegate;
@property (nonatomic, strong) CTInboxNotificationContentItem *notification;

- (UIButton*)setupViewForButton:(UIButton *)buttonView withData:(CTInboxNotificationContentItem *)message withIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END

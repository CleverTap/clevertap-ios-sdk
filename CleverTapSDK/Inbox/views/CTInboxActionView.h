#import <UIKit/UIKit.h>
#import "CTButton.h"

@protocol CTInboxActionViewDelegate <NSObject>
@required
- (void)inboxButtonDidTapped;
- (void)handleInboxNotificationFromIndex:(UIButton *)sender;
- (void)handleInboxNotificationFromIndexPath:(NSIndexPath *)indexPath withIndex:(int)index;
@end

NS_ASSUME_NONNULL_BEGIN

@interface CTInboxActionView : UIView

@property (strong, nonatomic) IBOutlet CTButton *firstButton;
@property (strong, nonatomic) IBOutlet CTButton *secondButton;
@property (strong, nonatomic) IBOutlet CTButton *thirdButton;
@property (nonatomic, weak) id<CTInboxActionViewDelegate> delegate;

- (CTButton*)setupViewForButton:(CTButton *)buttonView forText:(NSString *)text withIndexPath:(NSIndexPath *)indexPath andIndex:(int)index;

@end

NS_ASSUME_NONNULL_END

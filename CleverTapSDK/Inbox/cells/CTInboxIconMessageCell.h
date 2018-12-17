#import <UIKit/UIKit.h>
#import "CleverTap+Inbox.h"
#import "CTInboxActionView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTInboxIconMessageCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutlet UIImageView *cellImageView;
@property (strong, nonatomic) IBOutlet UIImageView *cellIcon;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *bodyLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewHeightContraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewRatioContraint;
@property (strong, nonatomic) IBOutlet CTInboxActionView *actionView;

- (void)setupIconMessage:(CTInboxNotificationContentItem *)message forIndexpath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END

#import <UIKit/UIKit.h>
#import "CleverTap+Inbox.h"
#import "CTInboxMessageActionView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTInboxIconMessageCell : UITableViewCell <CTInboxActionViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutlet UIImageView *cellImageView;
@property (strong, nonatomic) IBOutlet UIImageView *cellIcon;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *bodyLabel;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UIView *readView;
@property (strong, nonatomic) IBOutlet CTInboxMessageActionView *actionView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewHeightContraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewLRatioContraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageViewPRatioContraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *actionViewHeightContraint;

@property (strong, nonatomic) CleverTapInboxMessage *message;

- (void)setupIconMessage:(CleverTapInboxMessage *)message;
- (void)layoutNotification:(CleverTapInboxMessage *)message;

@end

NS_ASSUME_NONNULL_END

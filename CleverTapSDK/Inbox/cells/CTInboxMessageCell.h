#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FLAnimatedImageView;

@interface CTInboxMessageCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutlet FLAnimatedImageView *cellImageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *bodyLabel;

@end

NS_ASSUME_NONNULL_END

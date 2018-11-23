#import <UIKit/UIKit.h>
#import "CleverTap+Inbox.h"
#import "SwipeView.h"
#import "CTCaptionedImageView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTInboxMultiMediaCell : UITableViewCell <SwipeViewDataSource, SwipeViewDelegate>

@property (nonatomic, strong) NSMutableArray<CTCaptionedImageView*> *itemViews;
@property (nonatomic, strong) SwipeView *swipeView;
@property (strong, nonatomic) IBOutlet UIView *containerView;

- (void)setupSwipeView:(CleverTapInboxMessage *)message;

@end

NS_ASSUME_NONNULL_END

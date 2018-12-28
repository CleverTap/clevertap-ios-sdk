#import <UIKit/UIKit.h>
#import "CTCaptionedImageView.h"
#import "CleverTap+Inbox.h"
#import "SwipeView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTCarouselImageMessageCell : UITableViewCell <SwipeViewDataSource, SwipeViewDelegate>

@property (nonatomic, strong) NSMutableArray<CTCaptionedImageView*> *itemViews;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) SwipeView *swipeView;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UIView *readView;
@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *containerViewHeight;

@property (strong, nonatomic) CleverTapInboxMessage *message;

- (void)setupCarouselImageMessage:(CleverTapInboxMessage *)message;

@end

NS_ASSUME_NONNULL_END

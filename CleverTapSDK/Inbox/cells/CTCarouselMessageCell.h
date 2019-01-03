#import <UIKit/UIKit.h>
#import "CTCarouselImageView.h"
#import "CleverTap+Inbox.h"
#import "CTSwipeView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTCarouselMessageCell : UITableViewCell<SwipeViewDataSource, SwipeViewDelegate>{
    CGFloat captionHeight;
}

@property (nonatomic, strong) NSMutableArray<CTCarouselImageView*> *itemViews;
@property (nonatomic, assign) long currentItemIndex;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) CTSwipeView *swipeView;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UIView *readView;
@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutlet UIView *carouselView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *carouselViewHeight;

@property (strong, nonatomic) CleverTapInboxMessage *message;

- (void)setupCarouselMessage:(CleverTapInboxMessage *)message;

@end

NS_ASSUME_NONNULL_END

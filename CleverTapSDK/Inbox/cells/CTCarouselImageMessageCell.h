#import <UIKit/UIKit.h>
#import "CTCarouselImageView.h"
#import "CleverTap+Inbox.h"
#import "CTSwipeView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTCarouselImageMessageCell : UITableViewCell <SwipeViewDataSource, SwipeViewDelegate>

@property (nonatomic, strong) NSMutableArray<CTCarouselImageView*> *itemViews;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) CTSwipeView *swipeView;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UIView *readView;
@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet UIView *carouselView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *carouselViewHeight;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *readViewWidthContraint;

@property (nonatomic, strong) CleverTapInboxMessage *message;

- (void)setupCarouselImageMessage:(CleverTapInboxMessage *)message;

@end

NS_ASSUME_NONNULL_END

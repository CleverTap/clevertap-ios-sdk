#import "CTInboxBaseMessageCell.h"
#import "CTSwipeView.h"
#import "CTCarouselImageView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTCarouselMessageCell : CTInboxBaseMessageCell<SwipeViewDataSource, SwipeViewDelegate>{
    CGFloat captionHeight;
}

@property (nonatomic, strong) NSMutableArray<CTCarouselImageView*> *itemViews;
@property (nonatomic, assign) long currentItemIndex;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, strong) CTSwipeView *swipeView;
@property (nonatomic, strong) IBOutlet UIView *carouselView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *carouselViewHeight;

- (CGFloat)heightForPageControl;
- (float)getLandscapeMultiplier;
- (BOOL)orientationIsLandscape;
- (void)configurePageControlWithRect:(CGRect)rect;
- (void)configureSwipeViewWithHeightAdjustment:(CGFloat)adjustment;
- (void)handleItemViewTapGesture:(UITapGestureRecognizer *)sender;

@end

NS_ASSUME_NONNULL_END

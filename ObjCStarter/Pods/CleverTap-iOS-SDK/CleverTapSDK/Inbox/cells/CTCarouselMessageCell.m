#import "CTCarouselMessageCell.h"
#import "CTCarouselImageView.h"

@implementation CTCarouselMessageCell

static const float kLandscapeMultiplier = 0.5625; // 16:9 in landscape
static const float kPageControlViewHeight = 30.f;

- (void)awakeFromNib {
    [super awakeFromNib];
    [self onAwake];
}

-(void)onAwake {
    self.containerView.layer.masksToBounds = YES;
}

- (CGFloat)heightForPageControl {
    return kPageControlViewHeight;
}

- (float)getLandscapeMultiplier {
    return kLandscapeMultiplier;
}

- (CGFloat)calculateHeight:(CGFloat)viewWidth {
    CGFloat viewHeight = viewWidth + captionHeight;
    if (![self orientationIsPortrait]) {
        viewHeight = (viewWidth*kLandscapeMultiplier) + captionHeight;
    }
    return viewHeight;
}

- (void)populateLandscapeViews {
    self.itemViews = [NSMutableArray new];
    NSUInteger index = 0;
    for (CleverTapInboxMessageContent *content in (self.message.content)) {
        CTCarouselImageView *carouselItemView;
        if (carouselItemView == nil){
          carouselItemView  = [[[CTInAppUtils bundle] loadNibNamed: NSStringFromClass([CTCarouselImageView class]) owner:nil options:nil] lastObject];
            carouselItemView.backgroundColor = [UIColor clearColor];
            [carouselItemView.cellImageView sd_setImageWithURL:[NSURL URLWithString:content.mediaUrl]
                                          placeholderImage:[self orientationIsPortrait] ? [self getPortraitPlaceHolderImage] : [self getLandscapePlaceHolderImage]
                                                       options:self.sdWebImageOptions context:self.sdWebImageContext];
            carouselItemView.imageViewLandRatioConstraint.priority = [self orientationIsPortrait] ? 750 : 999;
            carouselItemView.imageViewPortRatioConstraint.priority = [self orientationIsPortrait] ? 999 : 750;
            carouselItemView.titleLabel.text = content.title;
            carouselItemView.titleLabel.textColor = content.titleColor ? [CTInAppUtils ct_colorWithHexString:content.titleColor] : [CTInAppUtils ct_colorWithHexString:@"#000000"];
            carouselItemView.bodyLabel.text = content.message;
            carouselItemView.bodyLabel.textColor = content.messageColor ? [CTInAppUtils ct_colorWithHexString:content.messageColor] :  [CTInAppUtils ct_colorWithHexString:@"#7E7E7E"];
        }
        
        UITapGestureRecognizer *carouselViewTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleItemViewTapGesture:)];
        carouselItemView.userInteractionEnabled = YES;
        carouselItemView.tag = index;
        [carouselItemView addGestureRecognizer:carouselViewTapGesture];
        [self.itemViews addObject:carouselItemView];
        index++;
    }
}

-(void)populateItemViews {
    self.itemViews = [NSMutableArray new];
    NSUInteger index = 0;
    for (CleverTapInboxMessageContent *content in (self.message.content)) {
        NSString *caption = content.title;
        NSString *subcaption = content.message;
        NSString *imageUrl = content.mediaUrl;
        NSString *actionUrl = content.actionUrl;
        NSString *captionColor = content.titleColor ? content.titleColor : @"#000000";
        NSString *subcaptionColor = content.messageColor ? content.messageColor : @"#7E7E7E";
        
        if (imageUrl == nil) {
            continue;
        }
        CTCarouselImageView *itemView;
        if (itemView == nil){
            CGRect frame = self.carouselView.bounds;
            frame.size.height =  frame.size.height;
            itemView = [[CTCarouselImageView alloc] initWithFrame:self.carouselView.bounds
                     caption:caption subcaption:subcaption captionColor:captionColor subcaptionColor:subcaptionColor imageUrl:imageUrl actionUrl:actionUrl orientationPortrait: [self orientationIsPortrait]];
        }
        
        UITapGestureRecognizer *itemViewTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleItemViewTapGesture:)];
        itemView.userInteractionEnabled = YES;
        itemView.tag = index;
        [itemView addGestureRecognizer:itemViewTapGesture];
        [self.itemViews addObject:itemView];
        index++;
    }
}
- (void)setupMessage:(CleverTapInboxMessage *)message {
    self.dateLabel.text = message.relativeDate;
    self.readView.hidden = message.isRead;
    self.readViewWidthConstraint.constant = message.isRead ? 0 : 16;
    for (UIView *view in self.itemViews) {
        [view removeFromSuperview];
    }
    for (UIView *subview in [self.carouselView subviews]) {
        [subview removeFromSuperview];
    }
    
    if ([self deviceOrientationIsLandscape]) {
        CGFloat margins = 0;
        if (@available(iOS 11.0, *)) {
            UIWindow *window = [CTInAppResources getSharedApplication].keyWindow;
            margins = window.safeAreaInsets.left;
        }
        CGFloat viewWidth = (CGFloat)  [[UIScreen mainScreen] bounds].size.width - margins*2;
        CGFloat viewHeight = viewWidth / 3.5;
        CGRect frame = CGRectMake(0, 0, viewWidth, viewHeight);
        self.frame = frame;
        self.carouselView.frame = frame;
        self.carouselViewHeight.constant  = viewHeight;
        [self layoutIfNeeded];
        [self layoutSubviews];
        [self populateLandscapeViews];
        [self configurePageControlWithRect:CGRectMake(viewWidth/2, self.carouselView.frame.size.height - kPageControlViewHeight, 22 * [self.itemViews count], kPageControlViewHeight)];
    } else {
        captionHeight = [CTCarouselImageView captionHeight];
        CGFloat viewWidth = (CGFloat) [[UIScreen mainScreen] bounds].size.width;
        CGFloat viewHeight = [self calculateHeight:viewWidth];
        CGRect frame = CGRectMake(0, 0, viewWidth, viewHeight);
        self.frame = frame;
        self.carouselView.frame = frame;
        self.carouselViewHeight.constant = viewHeight;
        [self layoutIfNeeded];
        [self layoutSubviews];
        [self populateItemViews];
        [self configurePageControlWithRect:CGRectMake(0, viewHeight-(captionHeight), viewWidth, kPageControlViewHeight)];
    }
    [self configureSwipeViewWithHeightAdjustment:0];
    [self.swipeView reloadData];
}

- (void)configureSwipeViewWithHeightAdjustment:(CGFloat)adjustment {
    self.swipeView = [[CTSwipeView alloc] init];
    CGRect swipeViewFrame = self.carouselView.bounds;
    if (adjustment > 0) {
        swipeViewFrame.size.height =  self.frame.size.height - adjustment;
    }
    self.swipeView.frame = swipeViewFrame;
    self.swipeView.delegate = self;
    self.swipeView.dataSource = self;
    self.swipeView.bounces = NO;
    [self.carouselView addSubview:self.swipeView];
}

- (void)configurePageControlWithRect:(CGRect)rect {
    self.pageControl = [[UIPageControl alloc] initWithFrame:rect];
    self.pageControl.userInteractionEnabled = YES;
    [self.pageControl addTarget:self action:@selector(pageControlTapped:) forControlEvents:UIControlEventValueChanged];
    self.pageControl.numberOfPages = [self.itemViews count];
    self.pageControl.hidesForSinglePage = YES;
    self.pageControl.currentPageIndicatorTintColor = [UIColor blueColor];
    self.pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    for (UIPageControl *pageControl in self.containerView.subviews) {
        if ([pageControl isKindOfClass:[UIPageControl class]]) {
            [pageControl removeFromSuperview];
        }
    }
    [self.containerView addSubview:self.pageControl];
}

#pragma mark - Swipe View Delegates

- (NSInteger)numberOfItemsInSwipeView:(CTSwipeView *)swipeView{
    return [self.itemViews count];
}

- (UIView *)swipeView:(CTSwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view{
    return self.itemViews[index];
}

- (void)swipeViewDidScroll:(CTSwipeView *)swipeView {
    self.pageControl.currentPage = (int)swipeView.currentItemIndex;
}

- (CGSize)swipeViewItemSize:(CTSwipeView *)swipeView{
    return self.swipeView.bounds.size;
}

#pragma mark - Actions

- (void)pageControlTapped:(UIPageControl *)sender {
    [self.swipeView scrollToItemAtIndex:sender.currentPage duration:0.5];
}

- (void)copyTapped:(NSString *)text {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = text;
}

- (void)handleItemViewTapGesture:(UITapGestureRecognizer *)sender {
    CTCarouselImageView *itemView = (CTCarouselImageView*)sender.view;
    NSInteger index = itemView.tag;
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:[NSNumber numberWithInt:(int)index] forKey:@"index"];
    [userInfo setObject:[NSNumber numberWithInt:-1] forKey:@"buttonIndex"];
    [[NSNotificationCenter defaultCenter] postNotificationName:CLTAP_INBOX_MESSAGE_TAPPED_NOTIFICATION object:self.message userInfo:userInfo];
}

@end

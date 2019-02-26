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
        CTCarouselImageView *carouselView = [[[CTInAppUtils bundle] loadNibNamed:@"CTCarouselImageView" owner:nil options:nil] lastObject];
        [carouselView.cellImageView sd_setImageWithURL:[NSURL URLWithString:content.mediaUrl]
                              placeholderImage:[self orientationIsPortrait] ? [self getPortraitPlaceHolderImage] : [self getLandscapePlaceHolderImage] options:self.sdWebImageOptions];
        carouselView.titleLabel.text = content.title;
        carouselView.titleLabel.textColor = content.titleColor ? [CTInAppUtils ct_colorWithHexString:content.titleColor] : [CTInAppUtils ct_colorWithHexString:@"#000000"];
        carouselView.bodyLabel.text = content.message;
        carouselView.bodyLabel.textColor = content.messageColor ? [CTInAppUtils ct_colorWithHexString:content.messageColor] :  [CTInAppUtils ct_colorWithHexString:@"#7E7E7E"];
        UITapGestureRecognizer *itemViewTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleItemViewTapGesture:)];
        carouselView.userInteractionEnabled = YES;
        carouselView.tag = index;
        [carouselView addGestureRecognizer:itemViewTapGesture];
        [self.itemViews addObject:carouselView];
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
    if ([self deviceOrientationIsLandscape]) {
        self.carouselLandRatioConstraint.priority = [self orientationIsPortrait]? 750 : 999;
        self.carouselPortRatioConstraint.priority = [self orientationIsPortrait]? 999 : 750;
        [self populateLandscapeViews];
        [self configurePageControlWithRect:CGRectMake(0, self.carouselView.frame.size.height, self.carouselView.frame.size.width, kPageControlViewHeight)];
    } else {
        captionHeight = [CTCarouselImageView captionHeight];
        CGFloat viewWidth = (CGFloat) [[UIScreen mainScreen] bounds].size.width;
        CGFloat viewHeight = [self calculateHeight:viewWidth];
        CGRect frame = CGRectMake(0, 0, viewWidth, viewHeight);
        self.frame = frame;
        self.carouselView.frame = frame;
        self.carouselViewHeight.constant = viewHeight;
        for (UIView *view in self.itemViews) {
            [view removeFromSuperview];
        }
        for (UIView *subview in [self.carouselView subviews]) {
            [subview removeFromSuperview];
        }
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
    for (UIPageControl *pageControl in self.carouselView.subviews) {
        if ([pageControl isKindOfClass:[UIPageControl class]]) {
            [pageControl removeFromSuperview];
        }
    }
    for (UIPageControl *pageControl in self.containerView.subviews) {
        if ([pageControl isKindOfClass:[UIPageControl class]]) {
            [pageControl removeFromSuperview];
        }
    }
    CTInboxMessageType messageType = [CTInboxUtils inboxMessageTypeFromString:self.message.type];
    if (messageType == CTInboxMessageTypeCarousel && ![self deviceOrientationIsLandscape])  {
         [self.carouselView addSubview:self.pageControl];
    } else {
         [self.containerView addSubview:self.pageControl];
    }
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

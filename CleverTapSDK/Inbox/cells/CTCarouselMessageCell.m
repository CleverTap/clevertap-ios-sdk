#import "CTCarouselMessageCell.h"
#import "CTInAppResources.h"
#import "CTConstants.h"

@implementation CTCarouselMessageCell

static const float kLandscapeMultiplier = 0.5625; // 16:9 in landscape
static const float kPageControlViewHeight = 30.f;
static NSString * const kOrientationLandscape = @"l";

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

- (BOOL)orientationIsLandscape {
    return [self.message.orientation.uppercaseString isEqualToString:kOrientationLandscape.uppercaseString];
}

- (CGFloat)calculateHeight:(CGFloat)viewWidth {
    CGFloat viewHeight = viewWidth + captionHeight;
    NSString *orientation = self.message.orientation;
    if ([orientation.uppercaseString isEqualToString:kOrientationLandscape.uppercaseString]) {
        viewHeight = (viewWidth*kLandscapeMultiplier) + captionHeight;
    }
    return viewHeight;
}

-(CGFloat) calculatePageControlY {
    return 0;
}

-(void)populateItemViews {
    self.itemViews = [NSMutableArray new];
    NSUInteger index = 0;
    for (CleverTapInboxMessageContent *content in (self.message.content)) {
        NSString *caption = content.title;
        NSString *subcaption = content.message;
        NSString *imageUrl = content.mediaUrl;
        NSString *actionUrl = content.actionUrl;
        NSString *captionColor = content.titleColor? content.titleColor : @"#000000";
        NSString *subcaptionColor = content.messageColor? content.messageColor : @"#7E7E7E";
        
        if (imageUrl == nil) {
            continue;
        }
        CTCarouselImageView *itemView;
        if (itemView == nil){
            CGRect frame = self.carouselView.bounds;
            frame.size.height =  frame.size.height ;
            itemView = [[CTCarouselImageView alloc] initWithFrame:self.carouselView.bounds
                                                          caption:caption subcaption:subcaption captionColor:captionColor subcaptionColor:subcaptionColor imageUrl:imageUrl actionUrl:actionUrl];
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
    self.message = message;
    self.dateLabel.text = message.relativeDate;
    if (message.isRead) {
        self.readView.hidden = YES;
        self.readViewWidthContraint.constant = 0;
    } else {
        self.readView.hidden = NO;
        self.readViewWidthContraint.constant = 16;
    }
    captionHeight = [CTCarouselImageView captionHeight];
    // assume square image orientation
    CGFloat leftMargin = 0;
    if (@available(iOS 11.0, *)) {
        UIWindow *window = [CTInAppResources getSharedApplication].keyWindow;
        leftMargin = window.safeAreaInsets.left;
    }
    
    CGFloat viewWidth = (CGFloat) [[UIScreen mainScreen] bounds].size.width - (leftMargin*2);
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
    [self configureSwipeViewWithHeightAdjustment:0];
    [self populateItemViews];
    [self configurePageControlWithRect:CGRectMake(0, viewHeight-(captionHeight), viewWidth, kPageControlViewHeight)];
    [self.swipeView reloadData];
}

- (void)configureSwipeViewWithHeightAdjustment:(CGFloat)adjustment {
    self.swipeView = [[CTSwipeView alloc] init];
    CGRect swipeViewFrame = self.carouselView.bounds;
    if (adjustment > 0) {
        swipeViewFrame.size.height =  self.frame.size.height - adjustment;
    }
    self.swipeView.frame = swipeViewFrame;
    self.swipeView.frame = self.carouselView.bounds;
    self.swipeView.delegate = self;
    self.swipeView.dataSource = self;
    self.swipeView.bounces = NO;
    [self.carouselView addSubview:self.swipeView];
}

- (void)configurePageControlWithRect:(CGRect)rect {
    self.pageControl = [[UIPageControl alloc] initWithFrame:rect];
    [self.pageControl addTarget:self action:@selector(pageControlTapped:) forControlEvents:UIControlEventValueChanged];
    self.pageControl.numberOfPages = [self.itemViews count];
    self.pageControl.hidesForSinglePage = YES;
    self.pageControl.currentPageIndicatorTintColor = [UIColor blueColor];
    self.pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    [self.carouselView addSubview:self.pageControl];
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

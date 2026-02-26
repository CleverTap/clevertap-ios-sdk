
#import "CTCarouselMessageCell.h"
#import "CTCarouselImageView.h"

@implementation CTCarouselMessageCell

static const float kLandscapeMultiplier = 0.5625; // 16:9 in landscape
static const float kPageControlViewHeight = 30.f;

- (void)awakeFromNib {
    [super awakeFromNib];
    [self onAwake];
}

- (void)onAwake {
    self.containerView.layer.masksToBounds = YES;
}

#if TARGET_OS_TV
- (void)setupTVLayout {
    // containerView — fills contentView (do NOT call [super setupTVLayout]; carousel has its own hierarchy)
    self.containerView = [[UIView alloc] init];
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.containerView.backgroundColor = [UIColor whiteColor];
    self.containerView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.containerView];
    [NSLayoutConstraint activateConstraints:@[
        [self.containerView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.containerView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.containerView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.containerView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
    ]];

    // carouselView — top of containerView, fixed height (default 200)
    self.carouselView = [[UIView alloc] init];
    self.carouselView.translatesAutoresizingMaskIntoConstraints = NO;
    self.carouselView.clipsToBounds = YES;
    [self.containerView addSubview:self.carouselView];

    self.carouselViewHeight = [self.carouselView.heightAnchor constraintEqualToConstant:200];
    [NSLayoutConstraint activateConstraints:@[
        [self.carouselView.topAnchor constraintEqualToAnchor:self.containerView.topAnchor],
        [self.carouselView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
        [self.carouselView.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
        self.carouselViewHeight,
    ]];

    // infoView — below carouselView, holds dateLabel + readView, height 38
    UIView *infoView = [[UIView alloc] init];
    infoView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:infoView];
    [NSLayoutConstraint activateConstraints:@[
        [infoView.topAnchor constraintEqualToAnchor:self.carouselView.bottomAnchor],
        [infoView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor],
        [infoView.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor],
        [infoView.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor],
        [infoView.heightAnchor constraintEqualToConstant:38],
    ]];

    // dateLabel — right side of infoView
    self.dateLabel = [[UILabel alloc] init];
    self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.dateLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    self.dateLabel.textColor = [CTUIUtils ct_colorWithHexString:@"#757575"];
    self.dateLabel.textAlignment = NSTextAlignmentRight;
    [infoView addSubview:self.dateLabel];
    [NSLayoutConstraint activateConstraints:@[
        [self.dateLabel.centerYAnchor constraintEqualToAnchor:infoView.centerYAnchor],
        [self.dateLabel.trailingAnchor constraintEqualToAnchor:infoView.trailingAnchor constant:-40],
    ]];

    // readView + readIndicator
    self.readView = [[UIView alloc] init];
    self.readView.translatesAutoresizingMaskIntoConstraints = NO;
    [infoView addSubview:self.readView];

    self.readViewWidthConstraint = [self.readView.widthAnchor constraintEqualToConstant:16];
    [NSLayoutConstraint activateConstraints:@[
        [self.readView.trailingAnchor constraintEqualToAnchor:infoView.trailingAnchor constant:-20],
        [self.readView.centerYAnchor constraintEqualToAnchor:self.dateLabel.centerYAnchor],
        [self.readView.heightAnchor constraintEqualToConstant:10],
        self.readViewWidthConstraint,
    ]];

    UIView *readIndicator = [[UIView alloc] init];
    readIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    readIndicator.backgroundColor = [CTUIUtils ct_colorWithHexString:@"#3D7DFF"];
    readIndicator.layer.cornerRadius = 5;
    [self.readView addSubview:readIndicator];
    [NSLayoutConstraint activateConstraints:@[
        [readIndicator.centerXAnchor constraintEqualToAnchor:self.readView.centerXAnchor],
        [readIndicator.centerYAnchor constraintEqualToAnchor:self.readView.centerYAnchor],
        [readIndicator.widthAnchor constraintEqualToConstant:10],
        [readIndicator.heightAnchor constraintEqualToConstant:10],
    ]];
}
#endif

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
    int imageNumber = 1;
    for (CleverTapInboxMessageContent *content in (self.message.content)) {
        CTCarouselImageView *carouselItemView;
        if (carouselItemView == nil){
#if TARGET_OS_TV
            carouselItemView = [[CTCarouselImageView alloc] initWithFrame:self.carouselView.bounds];
#else
            carouselItemView  = [[[CTUIUtils bundle] loadNibNamed: NSStringFromClass([CTCarouselImageView class]) owner:nil options:nil] lastObject];
#endif
            carouselItemView.backgroundColor = [UIColor clearColor];
            [carouselItemView.cellImageView sd_setImageWithURL:[NSURL URLWithString:content.mediaUrl]
                                              placeholderImage:[self orientationIsPortrait] ? [self getPortraitPlaceHolderImage] : [self getLandscapePlaceHolderImage]
                                                       options:self.sdWebImageOptions context:self.sdWebImageContext];
            carouselItemView.imageViewLandRatioConstraint.priority = [self orientationIsPortrait] ? 750 : 999;
            carouselItemView.imageViewPortRatioConstraint.priority = [self orientationIsPortrait] ? 999 : 750;
            carouselItemView.titleLabel.text = content.title;
            carouselItemView.titleLabel.textColor = content.titleColor ? [CTUIUtils ct_colorWithHexString:content.titleColor] : [CTUIUtils ct_colorWithHexString:@"#000000"];
            carouselItemView.bodyLabel.text = content.message;
            carouselItemView.bodyLabel.textColor = content.messageColor ? [CTUIUtils ct_colorWithHexString:content.messageColor] : [CTUIUtils ct_colorWithHexString:@"#7E7E7E"];
            
            NSString *imageDescription = content.mediaDescription ? content.mediaDescription : [NSString stringWithFormat:@"Message Image %d", imageNumber];
            imageNumber = imageNumber + 1;
            carouselItemView.viewDescription = [NSString stringWithFormat:@"%@ %@ %@", imageDescription, content.title, content.message];
        }
        
        UITapGestureRecognizer *carouselViewTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleItemViewTapGesture:)];
        carouselItemView.userInteractionEnabled = YES;
        carouselItemView.tag = index;
        [carouselItemView addGestureRecognizer:carouselViewTapGesture];
        [self.itemViews addObject:carouselItemView];
        index++;
    }
}

- (void)populateItemViews {
    self.itemViews = [NSMutableArray new];
    NSUInteger index = 0;
    int imageNumber = 1;
    for (CleverTapInboxMessageContent *content in (self.message.content)) {
        NSString *caption = content.title;
        NSString *subcaption = content.message;
        NSString *imageUrl = content.mediaUrl;
        NSString *actionUrl = content.actionUrl;
        NSString *captionColor = content.titleColor ? content.titleColor : @"#000000";
        NSString *subcaptionColor = content.messageColor ? content.messageColor : @"#7E7E7E";
        NSString *imageDescription = content.mediaDescription ? content.mediaDescription : [NSString stringWithFormat:@"Message Image %d", imageNumber];
        imageNumber = imageNumber + 1;
        
        if (imageUrl == nil) {
            continue;
        }
        CTCarouselImageView *itemView;
        if (itemView == nil){
            CGRect frame = self.carouselView.bounds;
            frame.size.height =  frame.size.height;
            itemView = [[CTCarouselImageView alloc] initWithFrame:self.carouselView.bounds caption:caption subcaption:subcaption captionColor:captionColor subcaptionColor:subcaptionColor imageUrl:imageUrl actionUrl:actionUrl orientationPortrait: [self orientationIsPortrait] imageDescription:imageDescription];
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
        CGFloat margins = [CTUIUtils getLeftMargin];
        CGFloat viewWidth = (CGFloat)  [[UIScreen mainScreen] bounds].size.width - margins*2;
        CGFloat viewHeight = viewWidth / 3.5;
        CGRect frame = CGRectMake(0, 0, viewWidth, viewHeight);
        self.frame = frame;
        self.carouselView.frame = frame;
        self.carouselViewHeight.constant  = viewHeight;
        [self populateLandscapeViews];
        [self configurePageControlWithRect:CGRectMake(viewWidth/2, self.carouselView.frame.size.height - kPageControlViewHeight, 64 * [self.itemViews count], kPageControlViewHeight)];
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
    self.carouselView.isAccessibilityElement = YES;
    self.carouselView.accessibilityLabel = [NSString stringWithFormat:@"%@ %@", self.itemViews[index].viewDescription, self.dateLabel.text];
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
#if !TARGET_OS_TV
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = text;
#endif
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

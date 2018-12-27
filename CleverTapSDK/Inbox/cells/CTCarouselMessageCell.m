#import "CTCarouselMessageCell.h"
#import "CTConstants.h"

@implementation CTCarouselMessageCell

static CGFloat kBorderWidth = 2.0;
static CGFloat kCornerRadius = 0.0;
static const float kLandscapeMultiplier = 0.5625; // 16:9 in landscape
static const float kPageControlViewHeight = 30.f;

static NSString * const kOrientationLandscape = @"l";

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    // no-op for now
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)awakeFromNib {
    [super awakeFromNib];
//    self.containerView.layer.cornerRadius = kCornerRadius;
//    self.containerView.layer.masksToBounds = YES;
//    self.containerView.layer.borderColor = [UIColor colorWithWhite:0.5f alpha:1.0].CGColor;
//    self.containerView.layer.borderWidth = kBorderWidth;
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void)setupCarouselMessage:(CleverTapInboxMessage *)message {
    
    self.message = message;
    
    self.dateLabel.text = message.relativeDate;
    self.carouselView.translatesAutoresizingMaskIntoConstraints = NO;
    captionHeight = [CTCaptionedImageView captionHeight];
    
    NSString *orientation = message.orientation;
    // assume square image orientation
    CGFloat viewWidth = self.frame.size.width;
    CGFloat viewHeight = viewWidth + captionHeight;
    
    if ([orientation.uppercaseString isEqualToString:kOrientationLandscape.uppercaseString]) {
        viewHeight = (viewWidth*kLandscapeMultiplier) + captionHeight;
    }
    
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
    
    self.swipeView = [[SwipeView alloc] init];
    self.swipeView.frame = self.carouselView.bounds;
    self.swipeView.delegate = self;
    self.swipeView.dataSource = self;
    
    [self.carouselView addSubview:self.swipeView];
    self.itemViews = [NSMutableArray new];
    
    NSUInteger index = 0;
    
    for (CleverTapInboxMessageContent *content in (message.content)) {
        NSString *caption = content.title;
        NSString *subcaption = content.message;
        NSString *imageUrl = content.mediaUrl;
        NSString *actionUrl = content.actionUrl;
        
        if (imageUrl == nil) {
            continue;
        }
        CTCaptionedImageView *itemView;
        if (itemView == nil){
            CGRect frame = self.carouselView.bounds;
            frame.size.height =  frame.size.height ;
            itemView = [[CTCaptionedImageView alloc] initWithFrame:self.carouselView.bounds
                                                           caption:caption subcaption:subcaption  imageUrl:imageUrl actionUrl:actionUrl];
        }
        
        UITapGestureRecognizer *itemViewTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleItemViewTapGesture:)];
        itemView.userInteractionEnabled = YES;
        itemView.tag = index;
        [itemView addGestureRecognizer:itemViewTapGesture];
        [self.itemViews addObject:itemView];
        index++;
    }

    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, viewHeight-(captionHeight), viewWidth, kPageControlViewHeight)];
    [self.pageControl addTarget:self action:@selector(pageControlTapped:) forControlEvents:UIControlEventValueChanged];
    self.pageControl.numberOfPages = [self.itemViews count];
    self.pageControl.hidesForSinglePage = YES;
    self.pageControl.currentPageIndicatorTintColor = [UIColor blueColor];
    self.pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    [self.carouselView addSubview:self.pageControl];
    
    [self.swipeView reloadData];
}

#pragma mark - Swipe View Delegates

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView{
    
    return [self.itemViews count];
}
- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view{
    
    return self.itemViews[index];
}
- (void)swipeViewDidScroll:(SwipeView *)swipeView {
    self.pageControl.currentPage = (int)swipeView.currentItemIndex;
}

- (CGSize)swipeViewItemSize:(SwipeView *)swipeView{
    
    return self.swipeView.bounds.size;
}

#pragma mark - Actions

-(void)pageControlTapped:(UIPageControl *)sender{
    [self.swipeView scrollToItemAtIndex:sender.currentPage duration:0.5];
}

- (void)copyTapped:(NSString *)text {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = text;
}

- (void)handleItemViewTapGesture:(UITapGestureRecognizer *)sender{
    
    CTCaptionedImageView *itemView = (CTCaptionedImageView*)sender.view;
    NSInteger index = itemView.tag;
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:[NSNumber numberWithInt:(int)index] forKey:@"index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:CLTAP_INBOX_MESSAGE_TAPPED_NOTIFICATION object:self.message userInfo:userInfo];
}

@end

#import "CTCarouselImageMessageCell.h"
#import "CTConstants.h"

@implementation CTCarouselImageMessageCell

static CGFloat kBorderWidth = 0.0;
static CGFloat kCornerRadius = 0.0;
static const float kLandscapeMultiplier = 0.5625; // 16:9 in landscape
static const float kPageControlViewHeight = 44.f;

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
    self.selectionStyle = UITableViewCellSelectionStyleNone;
//
//    self.containerView.layer.cornerRadius = kCornerRadius;
//    self.containerView.layer.masksToBounds = YES;
//    self.containerView.layer.borderColor = [UIColor colorWithWhite:0.5f alpha:1.0].CGColor;
//    self.containerView.layer.borderWidth = kBorderWidth;
    
    self.readView.layer.cornerRadius = 5;
    self.readView.layer.masksToBounds = YES;
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void)setupCarouselImageMessage:(CleverTapInboxMessage *)message {
    
    self.message = message;
    self.dateLabel.text = message.relativeDate;
    
    if (message.isRead) {
        self.readView.hidden = YES;
    } else {
        self.readView.hidden = NO;
    }
    
    NSString *orientation = message.orientation;
    // assume square image orientation
    CGFloat viewWidth = self.frame.size.width;
    CGFloat viewHeight = viewWidth + kPageControlViewHeight;
    
    if ([orientation.uppercaseString isEqualToString:kOrientationLandscape.uppercaseString]) {
        viewHeight = (viewWidth*kLandscapeMultiplier) + kPageControlViewHeight;
    }
    
    CGRect frame = CGRectMake(0, 0, viewWidth, viewHeight);
    self.frame = frame;
    self.containerView.frame = frame;
    self.containerViewHeight.constant = viewHeight;
    
    for (UIView *view in self.itemViews) {
        [view removeFromSuperview];
    }
    
    for (UIView *subview in [self.containerView subviews]) {
        [subview removeFromSuperview];
    }
    
    self.swipeView = [[SwipeView alloc] init];
    CGRect swipeViewFrame = self.containerView.bounds;
    swipeViewFrame.size.height =  frame.size.height - kPageControlViewHeight;
    self.swipeView.frame = swipeViewFrame;
    self.swipeView.delegate = self;
    self.swipeView.dataSource = self;
  
    [self.containerView addSubview:self.swipeView];
    self.itemViews = [NSMutableArray new];
    
    int index = 0;
    for (CleverTapInboxMessageContent *content in (message.content)) {
        NSString *imageUrl = content.mediaUrl;
        NSString *actionUrl = content.actionUrl;
        
        if (imageUrl == nil) {
            continue;
        }
        CTCaptionedImageView *itemView;
        if (itemView == nil){
            CGRect frame = self.containerView.bounds;
            frame.size.height =  frame.size.height - kPageControlViewHeight;
            itemView = [[CTCaptionedImageView alloc] initWithFrame:frame
                                                  imageUrl:imageUrl actionUrl:actionUrl];
        }
        
        
        UITapGestureRecognizer *itemViewTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleItemViewTapGesture:)];
        itemView.userInteractionEnabled = YES;
        itemView.tag = index;
        [itemView addGestureRecognizer:itemViewTapGesture];
        [self.itemViews addObject:itemView];
        index++;
    }

    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, self.containerView.frame.size.height - kPageControlViewHeight, viewWidth, kPageControlViewHeight)];
    [self.pageControl addTarget:self action:@selector(pageControlTapped:) forControlEvents:UIControlEventValueChanged];
    self.pageControl.numberOfPages = [self.itemViews count];
    self.pageControl.hidesForSinglePage = YES;
    self.pageControl.currentPageIndicatorTintColor = [UIColor blueColor];
    self.pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    [self.containerView addSubview:self.pageControl];
    [self.swipeView reloadData];
}

#pragma mark - Swipe View

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

- (void)pageControlTapped:(UIPageControl *)sender{
    [self.swipeView scrollToItemAtIndex:sender.currentPage duration:0.5];
}

- (void)handleItemViewTapGesture:(UITapGestureRecognizer *)sender{
    
    CTCaptionedImageView *itemView = (CTCaptionedImageView*)sender.view;
    NSInteger index = itemView.tag;
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:[NSNumber numberWithInt:(int)index] forKey:@"index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:CLTAP_INBOX_MESSAGE_TAPPED_NOTIFICATION object:self.message userInfo:userInfo];
    
}

@end

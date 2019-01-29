#import "CTCarouselImageMessageCell.h"


@implementation CTCarouselImageMessageCell

-(void)onAwake {
    // no-op here
}

-(void)populateItemViews {
    self.itemViews = [NSMutableArray new];
    int index = 0;
    for (CleverTapInboxMessageContent *content in (self.message.content)) {
        NSString *imageUrl = content.mediaUrl;
        NSString *actionUrl = content.actionUrl;
        
        if (imageUrl == nil) {
            continue;
        }
        CTCarouselImageView *itemView;
        if (itemView == nil){
            CGRect frame = self.carouselView.bounds;
            frame.size.height =  frame.size.height - [self heightForPageControl];
            frame.size.width = frame.size.width;
            itemView = [[CTCarouselImageView alloc] initWithFrame:frame
                                                         imageUrl:imageUrl actionUrl:actionUrl];
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
    self.readView.hidden = message.isRead;
    self.readViewWidthContraint.constant = message.isRead ? 0 : 16;
    
    // assume square image orientation
    CGFloat leftMargin = 0;
    if (@available(iOS 11.0, *)) {
        UIWindow *window = [CTInAppResources getSharedApplication].keyWindow;
        leftMargin = window.safeAreaInsets.left;
    }
    
    CGFloat viewWidth = (CGFloat) [[UIScreen mainScreen] bounds].size.width - (leftMargin*2);
    CGFloat viewHeight = viewWidth + [self heightForPageControl];
    
    if ([self orientationIsLandscape]) {
        viewHeight = (viewWidth*[self getLandscapeMultiplier]) + [self heightForPageControl];
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
    [self configureSwipeViewWithHeightAdjustment:[self heightForPageControl]];
    [self populateItemViews];
    [self configurePageControlWithRect:CGRectMake(0, self.carouselView.frame.size.height -[self heightForPageControl], viewWidth, [self heightForPageControl])];
    [self.swipeView reloadData];
    
}

@end

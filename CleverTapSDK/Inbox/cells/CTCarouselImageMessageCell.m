#import "CTCarouselImageMessageCell.h"
#import "CTCarouselImageView.h"

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
                                                         imageUrl:imageUrl actionUrl:actionUrl
                                              orientationPortrait: [self orientationIsPortrait]];
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
    UIInterfaceOrientation orientation = [[CTInAppResources getSharedApplication] statusBarOrientation];
    BOOL landscape = (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight);
    CGFloat viewWidth = landscape ? self.frame.size.width : (CGFloat) [[UIScreen mainScreen] bounds].size.width;
    CGFloat viewHeight = viewWidth + [self heightForPageControl];
    if (![self orientationIsPortrait]) {
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

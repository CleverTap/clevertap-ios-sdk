#import "CTCarouselImageMessageCell.h"
#import "CTCarouselImageView.h"

@implementation CTCarouselImageMessageCell

-(void)onAwake {
    // no-op here
}

- (void)populateItemViews {
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
            frame.size.height =  frame.size.height;
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
    
    if ([self deviceOrientationIsLandscape]) {
        CGFloat margins = 0;
        if (@available(iOS 11.0, *)) {
            UIWindow *window = [CTInAppResources getSharedApplication].keyWindow;
            margins = window.safeAreaInsets.left;
        }
        CGFloat viewWidth = (CGFloat)  [[UIScreen mainScreen] bounds].size.width - margins*2;
        CGFloat viewHeight = viewWidth / 3.5;
        self.carouselViewHeight.constant  = viewHeight;
        self.carouselLandRatioConstraint.priority = [self orientationIsPortrait] ? 750 : 999;
        self.carouselPortRatioConstraint.priority = [self orientationIsPortrait] ? 999 : 750;
    } else {
        CGFloat viewWidth = (CGFloat)  [[UIScreen mainScreen] bounds].size.width;
        CGFloat viewHeight = viewWidth;
        if (![self orientationIsPortrait]) {
            viewHeight = (viewWidth*[self getLandscapeMultiplier]);
        }
        CGRect frame = CGRectMake(0, 0, viewWidth, viewHeight);
        self.frame = frame;
        self.carouselViewHeight.constant = viewHeight;
        self.carouselView.frame = frame;
    }
    
    for (UIView *view in self.itemViews) {
        [view removeFromSuperview];
    }
    for (UIView *subview in [self.carouselView subviews]) {
        [subview removeFromSuperview];
    }
    [self layoutIfNeeded];
    [self layoutSubviews];
    [self configureSwipeViewWithHeightAdjustment:0];
    [self populateItemViews];
    [self configurePageControlWithRect:CGRectMake(0, self.carouselView.frame.size.height, self.containerView.frame.size.width, [self heightForPageControl])];
    [self.swipeView reloadData];
}

@end

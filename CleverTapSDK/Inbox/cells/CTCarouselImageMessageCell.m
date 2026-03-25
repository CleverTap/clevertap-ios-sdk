#import "CTCarouselImageMessageCell.h"
#import "CTCarouselImageView.h"

@implementation CTCarouselImageMessageCell

- (void)onAwake {
    // no-op here
}

- (void)populateItemViews {
    self.itemViews = [NSMutableArray new];
    int index = 0;
    int imageNumber = 1;
    for (CleverTapInboxMessageContent *content in (self.message.content)) {
        NSString *imageUrl = content.mediaUrl;
        NSString *actionUrl = content.actionUrl;
        NSString *imageDescription = content.mediaDescription ? content.mediaDescription : [NSString stringWithFormat:@"Message Image %d", imageNumber];
        imageNumber = imageNumber + 1;
        
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
                                              orientationPortrait: [self orientationIsPortrait]
                                                 imageDescription:imageDescription];
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
    
#if TARGET_OS_TV
    CGFloat screenWidth = (CGFloat)[[UIScreen mainScreen] bounds].size.width;
    CGFloat viewWidth = screenWidth - 80; 
    CGFloat viewHeight = round(screenWidth * 0.25);
    self.carouselViewHeight.constant = viewHeight;
#else
    if ([self deviceOrientationIsLandscape]) {
        CGFloat margins = [CTUIUtils getLeftMargin];
        CGFloat viewWidth = (CGFloat)[[UIScreen mainScreen] bounds].size.width - margins*2;
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
#endif
    
    for (UIView *view in self.itemViews) {
        [view removeFromSuperview];
    }
    for (UIView *subview in [self.carouselView subviews]) {
        [subview removeFromSuperview];
    }
    [self layoutIfNeeded];
    [self layoutSubviews];
#if TARGET_OS_TV
    self.carouselView.frame = CGRectMake(0, 0, viewWidth, viewHeight);
#endif
    [self configureSwipeViewWithHeightAdjustment:0];
    [self populateItemViews];
    [self configurePageControlWithRect:CGRectMake(0, self.carouselView.frame.size.height, self.containerView.frame.size.width, [self heightForPageControl])];
    [self.swipeView reloadData];
}

#if TARGET_OS_TV
- (void)handleOnMessageTapGesture:(UITapGestureRecognizer *)sender {
    NSInteger index = self.swipeView.currentItemIndex;
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:[NSNumber numberWithInt:(int)index] forKey:@"index"];
    [userInfo setObject:[NSNumber numberWithInt:-1] forKey:@"buttonIndex"];
    [[NSNotificationCenter defaultCenter] postNotificationName:CLTAP_INBOX_MESSAGE_TAPPED_NOTIFICATION
                                                        object:self.message
                                                      userInfo:userInfo];
}

- (BOOL)shouldUpdateFocusInContext:(UIFocusUpdateContext *)context {
    if ([context.nextFocusedView isDescendantOfView:self]) {
        return YES;
    }
    UIFocusHeading heading = context.focusHeading;
    if (heading == UIFocusHeadingLeft || heading == UIFocusHeadingRight) {
        return NO;
    }
    return YES;
}

- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event {
    for (UIPress *press in presses) {
        if (press.type == UIPressTypeLeftArrow) {
            NSInteger prev = self.swipeView.currentItemIndex - 1;
            if (prev >= 0) {
                [self.swipeView scrollToItemAtIndex:prev duration:0.3];
                self.pageControl.currentPage = (int)prev;
            }
            return;
        }
        if (press.type == UIPressTypeRightArrow) {
            NSInteger next = self.swipeView.currentItemIndex + 1;
            if (next < (NSInteger)self.itemViews.count) {
                [self.swipeView scrollToItemAtIndex:next duration:0.3];
                self.pageControl.currentPage = (int)next;
            }
            return;
        }
    }
    [super pressesBegan:presses withEvent:event];
}
#endif

@end

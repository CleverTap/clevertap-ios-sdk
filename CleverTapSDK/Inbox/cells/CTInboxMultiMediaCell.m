#import "CTInboxMultiMediaCell.h"

@implementation CTInboxMultiMediaCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setupSwipeView:(CleverTapInboxMessage *)message {
    
//    if (_swipeView == nil) {
    
        for (UIView *view in self.itemViews) {
            [view removeFromSuperview];
        }
        
        for (UIView *subview in [self.containerView subviews]) {
            [subview removeFromSuperview];
        }
        
        _swipeView = [[SwipeView alloc] init];
        _swipeView.frame = self.containerView.bounds;
        _swipeView.delegate = self;
        _swipeView.dataSource = self;
        [self.containerView addSubview:_swipeView];
        
        self.itemViews = [NSMutableArray new];
        
        for (NSDictionary *item in (message.media[@"items"])) {
            NSString *caption = item[@"caption"];
            NSString *subcaption = item[@"subcaption"];
            NSString *imageUrl = item[@"imageUrl"];
            NSString *actionUrl = item[@"actionUrl"];
            
            if (imageUrl == nil) {
                continue;
            }
            
            CTCaptionedImageView *itemView;
            
            if (itemView == nil){
                itemView = [[CTCaptionedImageView alloc] initWithFrame:self.containerView.bounds
                            caption:caption subcaption:subcaption  imageUrl:imageUrl actionUrl:actionUrl];
                itemView.backgroundColor = [UIColor redColor];
            }
            
            [self.itemViews addObject:itemView];
        }
        
        [self.swipeView reloadData];
//    }
}

#pragma mark - Swipe View

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView{
    
    return [self.itemViews count];
}
- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view{
    
    return self.itemViews[index];
}
- (void)swipeViewDidScroll:(SwipeView *)swipeView {
    
//    self.pageControl.currentPage = (int)swipeView.currentItemIndex;
//    self.currentItemIndex = (int)swipeView.currentItemIndex;
}

- (CGSize)swipeViewItemSize:(SwipeView *)swipeView{
    
    return self.swipeView.bounds.size;
}

@end

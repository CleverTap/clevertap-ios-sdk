#import "CTInboxActionView.h"

@implementation CTInboxActionView

/*
 Only override drawRect: if you perform custom drawing.
 An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
     Drawing code
}
*/

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
    self.firstButton.hidden = YES;
    self.secondButton.hidden = YES;
    self.thirdButton.hidden = YES;
}

- (CTButton*)setupViewForButton:(CTButton *)buttonView forText:(NSString *)text withIndexPath:(NSIndexPath *)indexPath andIndex:(int)index; {
    [buttonView setTag:index];
    buttonView.indexPath = indexPath;
    buttonView.index = index;
    buttonView.titleLabel.adjustsFontSizeToFitWidth = YES;
    buttonView.hidden = NO;
    [buttonView addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [buttonView setTitle:text forState:UIControlStateNormal];
    return buttonView;
}

- (void)buttonTapped:(CTButton*)button {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(inboxButtonDidTapped)]) {
        [self.delegate handleInboxNotificationFromIndex:button];
        [self.delegate handleInboxNotificationFromIndexPath:button.indexPath withIndex:button.index];
    }
}


@end
    

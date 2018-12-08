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

- (UIButton*)setupViewForButton:(UIButton *)buttonView withData:(CTInboxNotificationContentItem *)message withIndex:(NSInteger)index {
    [buttonView setTag: index];
    buttonView.titleLabel.adjustsFontSizeToFitWidth = YES;
    buttonView.hidden = NO;
    [buttonView addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.notification = message;
    NSDictionary *button = message.links[index];
    [buttonView setTitle:button[@"text"] forState:UIControlStateNormal];
    return buttonView;
}

- (void)buttonTapped:(UIButton*)button {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(inboxButtonDidTapped)]) {
        [self.delegate inboxButtonDidTapped];
    }
    
    NSDictionary *data = self.notification.links[button.tag];
    
//    NSURL *buttonCTA = data[@"url"];
//    NSString *buttonText = data[@""]
//    NSString *campaignId = self.notification.campaignId;
    
    if ([data[@"type"]  isEqual: @"copy"]) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = data[@"copyText"];
    }
}


@end
    

#import "CTInboxMessageActionView.h"
#import "CTInAppUtils.h"

@implementation CTInboxMessageActionView

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

- (UIButton*)setupViewForButton:(UIButton *)buttonView forText:(NSDictionary *)messageButton withIndex:(int)index; {
    buttonView.tag = index;
    buttonView.titleLabel.adjustsFontSizeToFitWidth = NO;
    buttonView.hidden = NO;
    [buttonView addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [buttonView setTitle:messageButton[@"text"] forState:UIControlStateNormal];
    buttonView.backgroundColor = [CTInAppUtils ct_colorWithHexString:messageButton[@"bg"]];
    [buttonView setTitleColor:[CTInAppUtils ct_colorWithHexString:messageButton[@"color"]] forState:UIControlStateNormal];
    return buttonView;
}

- (void)buttonTapped:(UIButton*)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(handleInboxMessageTappedAtIndex:)]) {
        [self.delegate handleInboxMessageTappedAtIndex:(int)button.tag];
    }
}

@end
    

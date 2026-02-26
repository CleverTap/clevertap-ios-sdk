
#import "CTInboxMessageActionView.h"
#import "CTUIUtils.h"

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
#if TARGET_OS_TV
    [self setupTVLayout];
#endif
    self.firstButton.hidden = YES;
    self.secondButton.hidden = YES;
    self.thirdButton.hidden = YES;
}

#if TARGET_OS_TV
- (void)setupTVLayout {
    // Top divider line (1pt, #AAAAAA)
    UIView *divider = [[UIView alloc] init];
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    divider.backgroundColor = [CTUIUtils ct_colorWithHexString:@"#AAAAAA"];
    [self addSubview:divider];
    [NSLayoutConstraint activateConstraints:@[
        [divider.topAnchor constraintEqualToAnchor:self.topAnchor],
        [divider.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [divider.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [divider.heightAnchor constraintEqualToConstant:1],
    ]];

    // Three buttons in a horizontal stack, equal widths, filling self below divider
    self.firstButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.secondButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.thirdButton = [UIButton buttonWithType:UIButtonTypeCustom];

    for (UIButton *btn in @[self.firstButton, self.secondButton, self.thirdButton]) {
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        btn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        btn.titleLabel.adjustsFontSizeToFitWidth = NO;
        [btn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventPrimaryActionTriggered];
        [self addSubview:btn];
    }

    // Pin first button: left edge to self, top below divider, bottom to self bottom
    [NSLayoutConstraint activateConstraints:@[
        [self.firstButton.topAnchor constraintEqualToAnchor:divider.bottomAnchor],
        [self.firstButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.firstButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];

    // Pin second button to the right of first, equal width
    [NSLayoutConstraint activateConstraints:@[
        [self.secondButton.topAnchor constraintEqualToAnchor:divider.bottomAnchor],
        [self.secondButton.leadingAnchor constraintEqualToAnchor:self.firstButton.trailingAnchor],
        [self.secondButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.secondButton.widthAnchor constraintEqualToAnchor:self.firstButton.widthAnchor],
    ]];

    // Pin third button to the right of second, equal width, right edge to self
    [NSLayoutConstraint activateConstraints:@[
        [self.thirdButton.topAnchor constraintEqualToAnchor:divider.bottomAnchor],
        [self.thirdButton.leadingAnchor constraintEqualToAnchor:self.secondButton.trailingAnchor],
        [self.thirdButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.thirdButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.thirdButton.widthAnchor constraintEqualToAnchor:self.firstButton.widthAnchor],
    ]];

    // secondButtonWidthConstraint: priority 750 so it's overridden by equal-width when visible
    self.secondButtonWidthConstraint = [self.secondButton.widthAnchor constraintEqualToConstant:0];
    self.secondButtonWidthConstraint.priority = 750;

    // thirdButtonWidthConstraint: priority 750 so it's overridden by equal-width when visible
    self.thirdButtonWidthConstraint = [self.thirdButton.widthAnchor constraintEqualToConstant:0];
    self.thirdButtonWidthConstraint.priority = 750;
}
#endif

- (UIButton*)setupViewForButton:(UIButton *)buttonView forText:(NSDictionary *)messageButton withIndex:(int)index; {
    buttonView.tag = index;
    buttonView.titleLabel.adjustsFontSizeToFitWidth = NO;
    buttonView.hidden = NO;
#if TARGET_OS_TV
    [buttonView addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventPrimaryActionTriggered];
#else
    [buttonView addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
#endif
    [buttonView setTitle:messageButton[@"text"] forState:UIControlStateNormal];
    buttonView.backgroundColor = [CTUIUtils ct_colorWithHexString:messageButton[@"bg"]];
    [buttonView setTitleColor:[CTUIUtils ct_colorWithHexString:messageButton[@"color"]] forState:UIControlStateNormal];
    return buttonView;
}

- (void)buttonTapped:(UIButton*)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(handleInboxMessageTappedAtIndex:)]) {
        [self.delegate handleInboxMessageTappedAtIndex:(int)button.tag];
    }
}

@end


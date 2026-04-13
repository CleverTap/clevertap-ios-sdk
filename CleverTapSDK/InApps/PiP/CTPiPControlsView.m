#import "CTPiPControlsView.h"
#import "CTUIUtils.h"

static const CGFloat kPiPControlButtonSizeCollapsed = 24.0;
static const CGFloat kPiPControlButtonSizeExpanded  = 48.0;
static const CGFloat kPiPControlPadding             = 8.0;
static const CGFloat kPiPRowSpacingCollapsed        = 8.0;
static const CGFloat kPiPRowSpacingExpanded         = 16.0;

static NSString * const kPiPImageMute     = @"ct_pip_mute.png";
static NSString * const kPiPImageSpeaker  = @"ct_pip_speaker.png";
static NSString * const kPiPImagePlay     = @"ct_pip_play.png";
static NSString * const kPiPImagePause    = @"ct_pip_pause.png";
static NSString * const kPiPImageExpand   = @"ct_pip_expand.png";
static NSString * const kPiPImageCollapse = @"ct_pip_collapse.png";
static NSString * const kPiPImageDeeplink = @"ct_pip_deeplink.png";
static NSString * const kPiPImageClose   = @"ct_pip_close.png";

@interface CTPiPControlsView ()
@property (nonatomic, strong) CTPiPConfigModel *config;
@property (nonatomic, assign) BOOL isVideoType;
@property (nonatomic, assign) BOOL hasDeeplink;
@property (nonatomic, assign) BOOL isExpanded;

@property (nonatomic, strong, nullable) UIButton *closeButton;
@property (nonatomic, strong, nullable) UIButton *expandCollapseButton;
@property (nonatomic, strong, nullable) UIButton *muteButton;
@property (nonatomic, strong, nullable) UIButton *playPauseButton;
@property (nonatomic, strong, nullable) UIButton *deeplinkButton;
@end

@implementation CTPiPControlsView

- (instancetype)initWithConfig:(CTPiPConfigModel *)config isVideoType:(BOOL)isVideoType {
    self = [super init];
    if (self) {
        _config = config;
        _isVideoType = isVideoType;
        // Show deeplink button for any actionable onClick (URL, KV, or CustomCode).
        // onClick model is always non-nil (returns Unknown type when missing from JSON).
        _hasDeeplink = (config.onClick.type != CTPiPOnClickActionTypeUnknown &&
                        config.onClick.type != CTPiPOnClickActionTypeClose);
        self.userInteractionEnabled = YES;
        [self setupButtons];
    }
    return self;
}

// MARK: - Setup

- (void)setupButtons {
    // Close — always present
    UIButton *close = [self makeButtonWithImage:[CTUIUtils getImageForName:kPiPImageClose]];
    [close addTarget:self action:@selector(closeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    close.accessibilityLabel = @"Close";
    [self addSubview:close];
    self.closeButton = close;

    // Expand/Collapse
    if (self.config.controls.expandCollapse) {
        UIButton *btn = [self makeButtonWithImage:[CTUIUtils getImageForName:kPiPImageExpand]];
        [btn addTarget:self action:@selector(expandCollapseButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        btn.accessibilityLabel = @"Expand";
        [self addSubview:btn];
        self.expandCollapseButton = btn;
    }

    // Mute — video only
    if (self.isVideoType && self.config.controls.mute) {
        UIButton *btn = [self makeButtonWithImage:[CTUIUtils getImageForName:kPiPImageMute]];
        [btn addTarget:self action:@selector(muteButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        btn.accessibilityLabel = @"Unmute";
        [self addSubview:btn];
        self.muteButton = btn;
    }

    // Play/Pause — video only, centred in both collapsed and expanded
    if (self.isVideoType && self.config.controls.playPause) {
        UIButton *btn = [self makeButtonWithImage:[CTUIUtils getImageForName:kPiPImagePause]];
        [btn addTarget:self action:@selector(playPauseButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        btn.accessibilityLabel = @"Pause";
        [self addSubview:btn];
        self.playPauseButton = btn;
    }

    // Deeplink
    if (self.hasDeeplink) {
        UIButton *btn = [self makeButtonWithImage:[CTUIUtils getImageForName:kPiPImageDeeplink]];
        [btn addTarget:self action:@selector(deeplinkButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        btn.accessibilityLabel = @"Open link";
        [self addSubview:btn];
        self.deeplinkButton = btn;
    }
}

// MARK: - Button factory

- (CGFloat)buttonSize {
    return self.isExpanded ? kPiPControlButtonSizeExpanded : kPiPControlButtonSizeCollapsed;
}

- (UIButton *)makeButtonWithImage:(UIImage *)image {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    btn.clipsToBounds = YES;
    // Frame-based layout — size set dynamically in layoutSubviews.
    btn.translatesAutoresizingMaskIntoConstraints = YES;

    UIImageView *iv = [[UIImageView alloc] initWithImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.userInteractionEnabled = NO;
    iv.tintColor = UIColor.whiteColor;
    iv.translatesAutoresizingMaskIntoConstraints = NO;
    [btn addSubview:iv];
    [NSLayoutConstraint activateConstraints:@[
        [iv.topAnchor constraintEqualToAnchor:btn.topAnchor],
        [iv.bottomAnchor constraintEqualToAnchor:btn.bottomAnchor],
        [iv.leadingAnchor constraintEqualToAnchor:btn.leadingAnchor],
        [iv.trailingAnchor constraintEqualToAnchor:btn.trailingAnchor],
    ]];
    iv.tag = 1;
    return btn;
}

// MARK: - Hit-test passthrough

/// Passes through touches that don't land on a button so the CTA overlay below
/// can toggle controls visibility.
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    return (view == self) ? nil : view;
}

// MARK: - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.isVideoType) {
        self.isExpanded ? [self layoutVideoExpanded] : [self layoutVideoCollapsed];
    } else {
        [self layoutImageGIF];
    }
}

/// Sets a button's frame and updates its corner radius to match the current button size.
- (void)placeButton:(UIButton *)btn x:(CGFloat)x y:(CGFloat)y {
    CGFloat s = [self buttonSize];
    btn.frame = CGRectMake(x, y, s, s);
    btn.layer.cornerRadius = s / 2.0;
}

/// Image/GIF — Close: top-right | Bottom-right row: deeplink → expand/collapse
- (void)layoutImageGIF {
    UIEdgeInsets safe = self.safeAreaInsets;
    CGFloat p       = kPiPControlPadding;
    CGFloat s       = [self buttonSize];
    CGFloat spacing = self.isExpanded ? kPiPRowSpacingExpanded : kPiPRowSpacingCollapsed;
    CGFloat w       = self.bounds.size.width;

    if (self.closeButton) {
        [self placeButton:self.closeButton x:w - safe.right - s - p y:safe.top + p];
    }

    [self layoutBottomRightRowWithSpacing:spacing buttonSize:s safeInsets:safe];
}

/// Video collapsed:
/// - Close: top-right
/// - Play/Pause: centre
/// - Bottom-right row (8pt gap, left→right): deeplink → mute → expand/collapse
- (void)layoutVideoCollapsed {
    UIEdgeInsets safe = self.safeAreaInsets;
    CGFloat p       = kPiPControlPadding;
    CGFloat s       = [self buttonSize];
    CGFloat spacing = kPiPRowSpacingCollapsed;
    CGFloat w       = self.bounds.size.width;
    CGFloat h       = self.bounds.size.height;

    if (self.closeButton) {
        [self placeButton:self.closeButton x:w - safe.right - s - p y:safe.top + p];
    }

    if (self.playPauseButton) {
        self.playPauseButton.hidden = NO;
        [self placeButton:self.playPauseButton x:(w - s) / 2.0 y:(h - s) / 2.0];
    }

    [self layoutBottomRightRowWithSpacing:spacing buttonSize:s safeInsets:safe];
}

/// Video expanded:
/// - Close: top-right
/// - Play/Pause: centre
/// - Bottom-right row (16pt gap, left→right): deeplink → mute → expand/collapse
- (void)layoutVideoExpanded {
    UIEdgeInsets safe = self.safeAreaInsets;
    CGFloat p       = kPiPControlPadding;
    CGFloat s       = [self buttonSize];
    CGFloat spacing = kPiPRowSpacingExpanded;
    CGFloat w       = self.bounds.size.width;
    CGFloat h       = self.bounds.size.height;

    if (self.closeButton) {
        [self placeButton:self.closeButton x:w - safe.right - s - p y:safe.top + p];
    }

    if (self.playPauseButton) {
        self.playPauseButton.hidden = NO;
        [self placeButton:self.playPauseButton x:(w - s) / 2.0 y:(h - s) / 2.0];
    }

    [self layoutBottomRightRowWithSpacing:spacing buttonSize:s safeInsets:safe];
}

/// Places the additional buttons (deeplink → mute → expand/collapse) anchored to the
/// bottom-right corner, growing leftward with the given gap between each button.
- (void)layoutBottomRightRowWithSpacing:(CGFloat)spacing
                             buttonSize:(CGFloat)s
                             safeInsets:(UIEdgeInsets)safe {
    // Only include buttons that are currently visible — respects hidden state set
    // by switchToImageLayout (e.g. mute is hidden when video falls back to image).
    NSMutableArray<UIButton *> *row = [NSMutableArray array];
    if (self.deeplinkButton       && !self.deeplinkButton.hidden)       [row addObject:self.deeplinkButton];
    if (self.muteButton           && !self.muteButton.hidden)           [row addObject:self.muteButton];
    if (self.expandCollapseButton && !self.expandCollapseButton.hidden) [row addObject:self.expandCollapseButton];

    NSInteger count = row.count;
    if (count == 0) return;

    CGFloat w          = self.bounds.size.width;
    CGFloat h          = self.bounds.size.height;
    CGFloat rowY       = h - safe.bottom - s - kPiPControlPadding;
    CGFloat rightEdge  = w - safe.right - kPiPControlPadding;

    // i=0 → leftmost (deeplink), i=count-1 → rightmost (expand/collapse)
    for (NSInteger i = 0; i < count; i++) {
        CGFloat x = rightEdge - (count - i) * s - (count - i - 1) * spacing;
        [self placeButton:row[i] x:x y:rowY];
    }
}

// MARK: - Actions

- (void)closeButtonTapped          { [self.delegate pipControlsDidTapClose]; }
- (void)muteButtonTapped           { [self.delegate pipControlsDidTapMute]; }
- (void)playPauseButtonTapped      { [self.delegate pipControlsDidTapPlayPause]; }
- (void)deeplinkButtonTapped       { [self.delegate pipControlsDidTapDeeplink]; }

- (void)expandCollapseButtonTapped {
    self.isExpanded = !self.isExpanded;
    [self updateLayout:self.isExpanded];
    [self.delegate pipControlsDidTapExpandCollapse:self.isExpanded];
}

// MARK: - State updates

- (void)updateLayout:(BOOL)isExpanded {
    self.isExpanded = isExpanded;
    // Update expand/collapse icon
    if (self.expandCollapseButton) {
        [self setImage:[CTUIUtils getImageForName:isExpanded ? kPiPImageCollapse : kPiPImageExpand]
             forButton:self.expandCollapseButton];
        self.expandCollapseButton.accessibilityLabel = isExpanded ? @"Collapse" : @"Expand";
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)updateMuteButtonMuted:(BOOL)isMuted {
    if (!self.muteButton) return;
    [self setImage:[CTUIUtils getImageForName:isMuted ? kPiPImageMute : kPiPImageSpeaker]
         forButton:self.muteButton];
    self.muteButton.accessibilityLabel = isMuted ? @"Unmute" : @"Mute";
}

- (void)updatePlayPauseButtonPlaying:(BOOL)isPlaying {
    if (!self.playPauseButton) return;
    [self setImage:[CTUIUtils getImageForName:isPlaying ? kPiPImagePause : kPiPImagePlay]
         forButton:self.playPauseButton];
    self.playPauseButton.accessibilityLabel = isPlaying ? @"Pause" : @"Play";
}

- (void)setCloseButtonVisible:(BOOL)visible {
    self.closeButton.hidden = !visible;
}

- (void)switchToImageLayout {
    self.isVideoType = NO;
    self.muteButton.hidden = YES;
    self.playPauseButton.hidden = YES;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

// MARK: - Helpers

- (UIImageView *)imageViewForButton:(UIButton *)btn {
    return (UIImageView *)[btn viewWithTag:1];
}

- (void)setImage:(UIImage *)image forButton:(UIButton *)btn {
    [self imageViewForButton:btn].image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

@end

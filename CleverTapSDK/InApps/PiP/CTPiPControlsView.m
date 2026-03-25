#import "CTPiPControlsView.h"
#import "CTUIUtils.h"

static const CGFloat kPiPControlButtonSizeCollapsed = 20.0;
static const CGFloat kPiPControlButtonSizeExpanded  = 40.0;
static const CGFloat kPiPControlPadding             = 8.0;
static const CGFloat kPiPRowSpacing                 = 20.0;

static NSString * const kPiPImageMute     = @"ct_pip_mute.png";
static NSString * const kPiPImageSpeaker  = @"ct_pip_speaker.png";
static NSString * const kPiPImagePlay     = @"ct_pip_play.png";
static NSString * const kPiPImagePause    = @"ct_pip_pause.png";
static NSString * const kPiPImageExpand   = @"ct_pip_expand.png";
static NSString * const kPiPImageCollapse = @"ct_pip_collapse.png";
static NSString * const kPiPImageDeeplink = @"ct_pip_deeplink.png";

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
    UIButton *close = [self makeButtonWithImage:[self closeImage]];
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

    // Play/Pause — video only, hidden in collapsed state
    if (self.isVideoType && self.config.controls.playPause) {
        UIButton *btn = [self makeButtonWithImage:[CTUIUtils getImageForName:kPiPImagePause]];
        [btn addTarget:self action:@selector(playPauseButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        btn.accessibilityLabel = @"Pause";
        btn.hidden = YES; // shown only when expanded
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

/// Image/GIF — same layout for both collapsed and expanded.
/// Close: top-right | Expand/Collapse: bottom-right | Deeplink: bottom-left
- (void)layoutImageGIF {
    UIEdgeInsets safe = self.safeAreaInsets;
    CGFloat p = kPiPControlPadding;
    CGFloat s = [self buttonSize];
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;

    CGFloat topY    = safe.top + p;
    CGFloat bottomY = h - safe.bottom - s - p;
    CGFloat leftX   = safe.left + p;
    CGFloat rightX  = w - safe.right - s - p;

    if (self.closeButton)          [self placeButton:self.closeButton          x:rightX y:topY];
    if (self.expandCollapseButton) [self placeButton:self.expandCollapseButton x:rightX y:bottomY];
    if (self.deeplinkButton)       [self placeButton:self.deeplinkButton       x:leftX  y:bottomY];
}

/// Video collapsed: Close: top-right | Expand: bottom-right | Deeplink: top-left | Mute: bottom-left
- (void)layoutVideoCollapsed {
    UIEdgeInsets safe = self.safeAreaInsets;
    CGFloat p = kPiPControlPadding;
    CGFloat s = [self buttonSize];
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;

    CGFloat topY    = safe.top + p;
    CGFloat bottomY = h - safe.bottom - s - p;
    CGFloat leftX   = safe.left + p;
    CGFloat rightX  = w - safe.right - s - p;

    if (self.closeButton)          [self placeButton:self.closeButton          x:rightX y:topY];
    if (self.expandCollapseButton) [self placeButton:self.expandCollapseButton x:rightX y:bottomY];
    if (self.deeplinkButton)       [self placeButton:self.deeplinkButton       x:leftX  y:topY];
    if (self.muteButton)           [self placeButton:self.muteButton           x:leftX  y:bottomY];
    if (self.playPauseButton)      self.playPauseButton.hidden = YES;
}

/// Video expanded: Close: top-right | Bottom-center row: [deeplink,] mute, play, expand
- (void)layoutVideoExpanded {
    UIEdgeInsets safe = self.safeAreaInsets;
    CGFloat p = kPiPControlPadding;
    CGFloat s = [self buttonSize];
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;

    // Close — top-right
    if (self.closeButton) {
        [self placeButton:self.closeButton x:w - safe.right - s - p y:safe.top + p];
    }

    // Bottom-center row: [deeplink, mute, play, expand]
    NSMutableArray<UIButton *> *rowButtons = [NSMutableArray array];
    if (self.deeplinkButton)       [rowButtons addObject:self.deeplinkButton];
    if (self.muteButton)           [rowButtons addObject:self.muteButton];
    if (self.playPauseButton)      [rowButtons addObject:self.playPauseButton];
    if (self.expandCollapseButton) [rowButtons addObject:self.expandCollapseButton];

    NSInteger count = rowButtons.count;
    if (count == 0) return;

    CGFloat totalWidth = count * s + (count - 1) * kPiPRowSpacing;
    CGFloat startX = (w - totalWidth) / 2.0;
    CGFloat rowY = h - safe.bottom - s - p;

    for (NSInteger i = 0; i < count; i++) {
        UIButton *btn = rowButtons[i];
        btn.hidden = NO;
        [self placeButton:btn x:startX + i * (s + kPiPRowSpacing) y:rowY];
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

// MARK: - Helpers

- (UIImageView *)imageViewForButton:(UIButton *)btn {
    return (UIImageView *)[btn viewWithTag:1];
}

- (void)setImage:(UIImage *)image forButton:(UIButton *)btn {
    [self imageViewForButton:btn].image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (UIImage *)closeImage {
    if (@available(iOS 13.0, *)) {
        return [UIImage systemImageNamed:@"xmark.circle.fill"];
    }
    CGSize size = CGSizeMake(kPiPControlButtonSizeCollapsed, kPiPControlButtonSizeCollapsed);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    NSAttributedString *x = [[NSAttributedString alloc] initWithString:@"✕"
        attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18 weight:UIFontWeightMedium],
                     NSForegroundColorAttributeName: UIColor.whiteColor}];
    [x drawAtPoint:CGPointMake(13, 13)];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@end

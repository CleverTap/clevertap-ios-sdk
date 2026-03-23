#import "CTPiPControlsView.h"
#import "CTUIUtils.h"

static const CGFloat kPiPControlButtonSize = 20.0;
static const CGFloat kPiPControlPadding = 8.0;

// Asset names in the CleverTapSDK resource bundle
static NSString * const kPiPImageMute     = @"ct_pip_mute.png";
static NSString * const kPiPImageSpeaker  = @"ct_pip_speaker.png";
static NSString * const kPiPImagePlay     = @"ct_pip_play.png";
static NSString * const kPiPImagePause    = @"ct_pip_pause.png";
static NSString * const kPiPImageExpand   = @"ct_pip_expand.png";
static NSString * const kPiPImageCollapse = @"ct_pip_collapse.png";

@interface CTPiPControlsView ()
@property (nonatomic, strong) CTPiPConfigModel *config;
@property (nonatomic, strong, nullable) UIButton *closeButton;
@property (nonatomic, strong, nullable) UIButton *expandCollapseButton;
@property (nonatomic, strong, nullable) UIButton *muteButton;
@property (nonatomic, strong, nullable) UIButton *playPauseButton;
@property (nonatomic, assign) BOOL isExpanded;
@end

@implementation CTPiPControlsView

- (instancetype)initWithConfig:(CTPiPConfigModel *)config {
    self = [super init];
    if (self) {
        _config = config;
        self.userInteractionEnabled = YES;
        [self setupButtons];
    }
    return self;
}

- (void)setupButtons {
    // Close button — top-right corner (always created; visibility set by setCloseButtonVisible:)
    {
        UIButton *btn = [self makeButtonWithImage:[self closeImage]];
        [btn addTarget:self action:@selector(closeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        btn.accessibilityLabel = @"Close";
        [self addSubview:btn];
        self.closeButton = btn;
    }

    // Expand — top-left (shows expand icon by default)
    if (self.config.controls.expandCollapse) {
        UIButton *btn = [self makeButtonWithImage:[CTUIUtils getImageForName:kPiPImageExpand]];
        [btn addTarget:self action:@selector(expandCollapseButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        btn.accessibilityLabel = @"Expand";
        [self addSubview:btn];
        self.expandCollapseButton = btn;
    }

    // Mute — bottom-left (starts muted, so shows mute icon)
    if (self.config.controls.mute) {
        UIButton *btn = [self makeButtonWithImage:[CTUIUtils getImageForName:kPiPImageMute]];
        [btn addTarget:self action:@selector(muteButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        btn.accessibilityLabel = @"Unmute";
        [self addSubview:btn];
        self.muteButton = btn;
    }

    // Play/Pause — bottom-right (starts playing, so shows pause icon)
    if (self.config.controls.playPause) {
        UIButton *btn = [self makeButtonWithImage:[CTUIUtils getImageForName:kPiPImagePause]];
        [btn addTarget:self action:@selector(playPauseButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        btn.accessibilityLabel = @"Pause";
        [self addSubview:btn];
        self.playPauseButton = btn;
    }
}

- (UIButton *)makeButtonWithImage:(UIImage *)image {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    btn.layer.cornerRadius = 10.0;
    btn.clipsToBounds = YES;
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [btn.widthAnchor constraintEqualToConstant:kPiPControlButtonSize],
        [btn.heightAnchor constraintEqualToConstant:kPiPControlButtonSize],
    ]];

    // Embed an image view with explicit insets so small PNGs scale up correctly.
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

/// Pass through touches that don't land on a button — lets the CTA overlay beneath
/// receive taps on empty areas so it can toggle controls visibility.
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    return (view == self) ? nil : view;
}

/// Returns the embedded UIImageView for a button created by makeButtonWithImage:.
- (UIImageView *)imageViewForButton:(UIButton *)btn {
    return (UIImageView *)[btn viewWithTag:1];
}

/// Updates the icon of a button created by makeButtonWithImage:.
- (void)setImage:(UIImage *)image forButton:(UIButton *)btn {
    [self imageViewForButton:btn].image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

/// Returns a close (✕) icon — uses SF Symbol on iOS 13+ and falls back to a drawn image.
- (UIImage *)closeImage {
    if (@available(iOS 13.0, *)) {
        return [UIImage systemImageNamed:@"xmark.circle.fill"];
    }
    CGSize size = CGSizeMake(kPiPControlButtonSize, kPiPControlButtonSize);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    NSAttributedString *x = [[NSAttributedString alloc] initWithString:@"✕"
        attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18 weight:UIFontWeightMedium],
                     NSForegroundColorAttributeName: UIColor.whiteColor}];
    [x drawAtPoint:CGPointMake(13, 13)];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat p = kPiPControlPadding;
    // Use UIKit's safe area insets — zero for small PiP, correct for full-screen expanded.
    UIEdgeInsets safe = self.safeAreaInsets;
    CGFloat topEdge    = safe.top    + p;
    CGFloat bottomEdge = self.bounds.size.height - safe.bottom - kPiPControlButtonSize - p;
    CGFloat leftEdge   = safe.left   + p;
    CGFloat rightEdge  = self.bounds.size.width  - safe.right  - kPiPControlButtonSize - p;

    // Close — top-right
    if (self.closeButton) {
        self.closeButton.frame = CGRectMake(rightEdge, topEdge,
                                            kPiPControlButtonSize, kPiPControlButtonSize);
    }
    // Expand/Collapse — top-left
    if (self.expandCollapseButton) {
        self.expandCollapseButton.frame = CGRectMake(leftEdge, topEdge,
                                                     kPiPControlButtonSize, kPiPControlButtonSize);
    }
    // Mute — bottom-left
    if (self.muteButton) {
        self.muteButton.frame = CGRectMake(leftEdge, bottomEdge,
                                           kPiPControlButtonSize, kPiPControlButtonSize);
    }
    // Play/Pause — bottom-right
    if (self.playPauseButton) {
        self.playPauseButton.frame = CGRectMake(rightEdge, bottomEdge,
                                                kPiPControlButtonSize, kPiPControlButtonSize);
    }
}

// MARK: - Actions

- (void)closeButtonTapped {
    [self.delegate pipControlsDidTapClose];
}

- (void)expandCollapseButtonTapped {
    self.isExpanded = !self.isExpanded;
    [self updateExpandCollapseButtonExpanded:self.isExpanded];
    [self.delegate pipControlsDidTapExpandCollapse:self.isExpanded];
}

- (void)muteButtonTapped {
    [self.delegate pipControlsDidTapMute];
}

- (void)playPauseButtonTapped {
    [self.delegate pipControlsDidTapPlayPause];
}

// MARK: - State updates

- (void)updateMuteButtonMuted:(BOOL)isMuted {
    if (!self.muteButton) return;
    // isMuted=YES → video is muted → show mute icon (tap to unmute)
    // isMuted=NO  → video is live  → show speaker icon (tap to mute)
    [self setImage:[CTUIUtils getImageForName:isMuted ? kPiPImageMute : kPiPImageSpeaker]
         forButton:self.muteButton];
    self.muteButton.accessibilityLabel = isMuted ? @"Unmute" : @"Mute";
}

- (void)updatePlayPauseButtonPlaying:(BOOL)isPlaying {
    if (!self.playPauseButton) return;
    // isPlaying=YES → show pause icon (tap to pause)
    // isPlaying=NO  → show play icon  (tap to play)
    [self setImage:[CTUIUtils getImageForName:isPlaying ? kPiPImagePause : kPiPImagePlay]
         forButton:self.playPauseButton];
    self.playPauseButton.accessibilityLabel = isPlaying ? @"Pause" : @"Play";
}

- (void)updateExpandCollapseButtonExpanded:(BOOL)isExpanded {
    if (!self.expandCollapseButton) return;
    // isExpanded=YES → show collapse icon (tap to collapse)
    // isExpanded=NO  → show expand icon  (tap to expand)
    [self setImage:[CTUIUtils getImageForName:isExpanded ? kPiPImageCollapse : kPiPImageExpand]
         forButton:self.expandCollapseButton];
    self.expandCollapseButton.accessibilityLabel = isExpanded ? @"Collapse" : @"Expand";
}

// MARK: - Show/hide close independently (driven by outer config)

- (void)setCloseButtonVisible:(BOOL)visible {
    self.closeButton.hidden = !visible;
}

@end

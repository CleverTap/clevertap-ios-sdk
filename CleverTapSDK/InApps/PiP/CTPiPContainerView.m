#import "CTPiPContainerView.h"

@interface CTPiPContainerView () <CTPiPControlsViewDelegate, CTPiPCTAOverlayViewDelegate>
@property (nonatomic, strong) CTPiPConfigModel *config;
@property (nonatomic, assign) BOOL showClose;
@property (nonatomic, strong, readwrite) CTPiPMediaView *mediaView;
@property (nonatomic, strong, readwrite) CTPiPControlsView *controlsView;
@property (nonatomic, strong) CTPiPCTAOverlayView *ctaOverlay;
@property (nonatomic, assign) CGRect parentBounds;
@property (nonatomic, assign) UIEdgeInsets pipSafeAreaInsets;
@property (nonatomic, assign) BOOL isExpanded;
@property (nonatomic, assign) CGRect collapsedFrame;
@property (nonatomic, assign) BOOL controlsVisible;
@end

@implementation CTPiPContainerView

- (instancetype)initWithConfig:(CTPiPConfigModel *)config
                     showClose:(BOOL)showClose
                     mediaView:(CTPiPMediaView *)mediaView {
    self = [super init];
    if (self) {
        _config = config;
        _showClose = showClose;
        _mediaView = mediaView;
        [self setupAppearance];
        [self setupSubviews];
        if (config.controls.drag) {
            [self setupDragGesture];
        }
    }
    return self;
}

// MARK: - Auto-hide controls

- (void)setAutoHideControls:(BOOL)autoHideControls {
    _autoHideControls = autoHideControls;
    if (autoHideControls) {
        self.controlsVisible = NO;
        self.controlsView.alpha = 0;
        self.controlsView.userInteractionEnabled = NO;
    }
}

- (void)toggleControlsAnimated {
    self.controlsVisible = !self.controlsVisible;
    BOOL show = self.controlsVisible;
    [UIView animateWithDuration:0.25 animations:^{
        self.controlsView.alpha = show ? 1.0 : 0.0;
    } completion:^(BOOL finished) {
        self.controlsView.userInteractionEnabled = show;
    }];
}

// MARK: - Appearance

- (void)setupAppearance {
    self.clipsToBounds = YES;
    self.layer.cornerRadius = self.config.cornerRadius;
    if (self.config.border.enabled) {
        self.layer.borderWidth = self.config.border.width;
        self.layer.borderColor = self.config.border.color.CGColor;
    }
}

// MARK: - Subviews

- (void)setupSubviews {
    // Media (bottom layer)
    self.mediaView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.mediaView];
    [NSLayoutConstraint activateConstraints:@[
        [self.mediaView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.mediaView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.mediaView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.mediaView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    ]];

    // CTA overlay (above media, below controls)
    CTPiPCTAOverlayView *cta = [[CTPiPCTAOverlayView alloc] init];
    cta.delegate = self;
    cta.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:cta];
    [NSLayoutConstraint activateConstraints:@[
        [cta.topAnchor constraintEqualToAnchor:self.topAnchor],
        [cta.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [cta.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [cta.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    ]];
    self.ctaOverlay = cta;

    // Controls overlay (top layer)
    CTPiPControlsView *controls = [[CTPiPControlsView alloc] initWithConfig:self.config];
    controls.delegate = self;
    controls.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:controls];
    [NSLayoutConstraint activateConstraints:@[
        [controls.topAnchor constraintEqualToAnchor:self.topAnchor],
        [controls.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [controls.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [controls.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    ]];
    self.controlsView = controls;

    if (!self.showClose) {
        [controls setCloseButtonVisible:NO];
    }
}

// MARK: - Drag & Snap

- (void)setupDragGesture {
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self addGestureRecognizer:pan];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.superview];
    [pan setTranslation:CGPointZero inView:self.superview];

    if (pan.state == UIGestureRecognizerStateBegan || pan.state == UIGestureRecognizerStateChanged) {
        UIEdgeInsets insets = self.pipSafeAreaInsets;
        CGRect bounds = self.parentBounds;
        CGFloat minX = insets.left;
        CGFloat maxX = bounds.size.width - insets.right - self.bounds.size.width;
        CGFloat minY = insets.top;
        CGFloat maxY = bounds.size.height - insets.bottom - self.bounds.size.height;
        CGFloat newX = MIN(MAX(self.frame.origin.x + translation.x, minX), maxX);
        CGFloat newY = MIN(MAX(self.frame.origin.y + translation.y, minY), maxY);
        self.frame = CGRectMake(newX, newY, self.bounds.size.width, self.bounds.size.height);
    } else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        [self snapToNearestAnchorInBounds:self.parentBounds safeAreaInsets:self.pipSafeAreaInsets];
    }
}

// MARK: - Initial placement

- (void)updateBounds:(CGRect)bounds safeAreaInsets:(UIEdgeInsets)insets {
    self.parentBounds = bounds;
    self.pipSafeAreaInsets = insets;
}

- (void)placeInitialPositionInBounds:(CGRect)bounds safeAreaInsets:(UIEdgeInsets)insets {
    self.parentBounds = bounds;
    self.pipSafeAreaInsets = insets;

    CGSize size = [self pipSizeForBounds:bounds];
    CGPoint origin = [self originForPosition:self.config.position
                                    pipSize:size
                                     bounds:bounds
                             safeAreaInsets:insets];
    self.frame = CGRectMake(origin.x, origin.y, size.width, size.height);
    self.collapsedFrame = self.frame;
}

- (CGSize)pipSizeForBounds:(CGRect)bounds {
    CGFloat screenWidth = bounds.size.width;
    CGFloat pipWidth = screenWidth * (self.config.widthPercent / 100.0);
    CGFloat pipHeight = pipWidth * self.config.aspectRatio.ratio;
    return CGSizeMake(pipWidth, pipHeight);
}

- (CGPoint)originForPosition:(CTPiPPosition)position
                     pipSize:(CGSize)size
                      bounds:(CGRect)bounds
              safeAreaInsets:(UIEdgeInsets)insets {
    CGFloat vm = self.config.margins.vertical;
    CGFloat hm = self.config.margins.horizontal;

    CGFloat left = insets.left + hm;
    CGFloat right = bounds.size.width - insets.right - hm - size.width;
    CGFloat top = insets.top + vm;
    CGFloat bottom = bounds.size.height - insets.bottom - vm - size.height;
    CGFloat centerX = (bounds.size.width - size.width) / 2.0;
    CGFloat centerY = (bounds.size.height - size.height) / 2.0;

    switch (position) {
        case CTPiPPositionTopLeft:     return CGPointMake(left, top);
        case CTPiPPositionTopCenter:   return CGPointMake(centerX, top);
        case CTPiPPositionTopRight:    return CGPointMake(right, top);
        case CTPiPPositionCenterLeft:  return CGPointMake(left, centerY);
        case CTPiPPositionCenter:      return CGPointMake(centerX, centerY);
        case CTPiPPositionCenterRight: return CGPointMake(right, centerY);
        case CTPiPPositionBottomLeft:  return CGPointMake(left, bottom);
        case CTPiPPositionBottomCenter:return CGPointMake(centerX, bottom);
        case CTPiPPositionBottomRight: return CGPointMake(right, bottom);
    }
}

// MARK: - 9-Point Snap

- (void)snapToNearestAnchorInBounds:(CGRect)bounds safeAreaInsets:(UIEdgeInsets)insets {
    CGPoint currentCenter = self.center;
    CTPiPPosition bestPosition = CTPiPPositionBottomRight;
    CGFloat bestDistance = CGFLOAT_MAX;

    for (NSInteger pos = CTPiPPositionTopLeft; pos <= CTPiPPositionBottomRight; pos++) {
        CGPoint origin = [self originForPosition:(CTPiPPosition)pos
                                         pipSize:self.bounds.size
                                          bounds:bounds
                                  safeAreaInsets:insets];
        CGPoint anchorCenter = CGPointMake(origin.x + self.bounds.size.width / 2.0,
                                           origin.y + self.bounds.size.height / 2.0);
        CGFloat dx = currentCenter.x - anchorCenter.x;
        CGFloat dy = currentCenter.y - anchorCenter.y;
        CGFloat distance = fabs(dx) + fabs(dy); // Manhattan distance
        if (distance < bestDistance) {
            bestDistance = distance;
            bestPosition = (CTPiPPosition)pos;
        }
    }

    CGPoint snapOrigin = [self originForPosition:bestPosition
                                         pipSize:self.bounds.size
                                          bounds:bounds
                                  safeAreaInsets:insets];
    CGRect snapFrame = CGRectMake(snapOrigin.x, snapOrigin.y, self.bounds.size.width, self.bounds.size.height);

    [UIView animateWithDuration:0.4
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.frame = snapFrame;
    } completion:nil];
    self.collapsedFrame = snapFrame;
}

// MARK: - Expand / Collapse

- (void)expandInBounds:(CGRect)bounds {
    self.collapsedFrame = self.frame;
    self.isExpanded = YES;
    [self.mediaView setContentFitMode:YES];
    [UIView animateWithDuration:0.35
                          delay:0
         usingSpringWithDamping:0.85
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.frame = bounds;
        self.layer.cornerRadius = 0;
    } completion:nil];
}

- (void)collapseToFrame:(CGRect)frame {
    self.isExpanded = NO;
    [self.mediaView setContentFitMode:YES];
    [UIView animateWithDuration:0.35
                          delay:0
         usingSpringWithDamping:0.85
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.frame = frame;
        self.layer.cornerRadius = self.config.cornerRadius;
    } completion:nil];
}

// MARK: - CTPiPControlsViewDelegate

- (void)pipControlsDidTapClose {
    [self.delegate pipContainerDidTapClose];
}

- (void)pipControlsDidTapExpandCollapse:(BOOL)isExpanded {
    if (isExpanded) {
        [self expandInBounds:self.parentBounds];
    } else {
        [self collapseToFrame:self.collapsedFrame];
    }
    [self.delegate pipContainerDidToggleExpand:isExpanded];
}

- (void)pipControlsDidTapMute {
    [self.delegate pipContainerDidTapMute];
}

- (void)pipControlsDidTapPlayPause {
    [self.delegate pipContainerDidTapPlayPause];
}

// MARK: - CTPiPCTAOverlayViewDelegate

- (void)pipCTAOverlayDidTap {
    if (self.autoHideControls) {
        [self toggleControlsAnimated];
    } else {
        [self.delegate pipContainerDidTapCTA];
    }
}

@end

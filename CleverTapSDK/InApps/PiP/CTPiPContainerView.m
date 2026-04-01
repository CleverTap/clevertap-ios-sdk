#import "CTPiPContainerView.h"

static const NSTimeInterval kPiPAutoHideDelay = 3.0;
static const CGFloat kPiPMaxHeightPercent = 40.0;

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
@property (nonatomic, assign) BOOL isVideoType;
@property (nonatomic, strong, nullable) NSTimer *autoHideTimer;
@property (nonatomic, assign) CTPiPPosition currentPosition;
@property (nonatomic, assign) UIDeviceOrientation currentOrientation;
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
        _isVideoType = (mediaView.contentType == CTPiPContentTypeVideo);
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

    [self cancelAutoHideTimer];
    if (show) {
        [self scheduleAutoHideTimer];
    }
}

- (void)showControlsAndScheduleAutoHide {
    self.controlsVisible = YES;
    self.controlsView.alpha = 1.0;
    self.controlsView.userInteractionEnabled = YES;
    [self cancelAutoHideTimer];
    [self scheduleAutoHideTimer];
}

- (void)scheduleAutoHideTimer {
    self.autoHideTimer = [NSTimer scheduledTimerWithTimeInterval:kPiPAutoHideDelay
                                                         target:self
                                                       selector:@selector(autoHideTimerFired)
                                                       userInfo:nil
                                                        repeats:NO];
}

- (void)cancelAutoHideTimer {
    [self.autoHideTimer invalidate];
    self.autoHideTimer = nil;
}

- (void)autoHideTimerFired {
    self.autoHideTimer = nil;
    if (self.controlsVisible) {
        [self toggleControlsAnimated];
    }
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
    CTPiPControlsView *controls = [[CTPiPControlsView alloc] initWithConfig:self.config
                                                                isVideoType:self.isVideoType];
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
    if (self.isExpanded) {
        return;
    }

    CGPoint translation = [pan translationInView:self.superview];
    [pan setTranslation:CGPointZero inView:self.superview];

    if (pan.state == UIGestureRecognizerStateBegan || pan.state == UIGestureRecognizerStateChanged) {
        UIEdgeInsets insets = self.pipSafeAreaInsets;
        CGRect bounds = self.parentBounds;
        // Use self.frame.size for visual dimensions — correct even when a ±90° transform is applied.
        // Never set self.frame on a transformed view; use self.center instead.
        CGSize visualSize = self.frame.size;
        CGFloat halfW = visualSize.width  / 2.0;
        CGFloat halfH = visualSize.height / 2.0;
        CGFloat minCX = insets.left   + halfW;
        CGFloat maxCX = bounds.size.width  - insets.right  - halfW;
        CGFloat minCY = insets.top    + halfH;
        CGFloat maxCY = bounds.size.height - insets.bottom - halfH;
        CGFloat newCX = MIN(MAX(self.center.x + translation.x, minCX), maxCX);
        CGFloat newCY = MIN(MAX(self.center.y + translation.y, minCY), maxCY);
        self.center = CGPointMake(newCX, newCY);
    } else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        [self snapToNearestAnchorInBounds:self.parentBounds safeAreaInsets:self.pipSafeAreaInsets];
    }
}

// MARK: - Initial placement

- (void)updateBounds:(CGRect)bounds safeAreaInsets:(UIEdgeInsets)insets {
    self.parentBounds = bounds;
    self.pipSafeAreaInsets = insets;

    if (self.isExpanded || CGRectIsEmpty(bounds)) { return; }

    CGSize newSize = [self pipSizeForBounds:bounds];
    CGPoint origin = [self originForPosition:self.currentPosition
                                     pipSize:newSize
                                      bounds:bounds
                              safeAreaInsets:insets];
    CGRect targetFrame = CGRectMake(origin.x, origin.y, newSize.width, newSize.height);
    if (!CGRectEqualToRect(targetFrame, self.frame)) {
        self.frame = targetFrame;
        self.collapsedFrame = targetFrame;
    }
}

- (void)placeInitialPositionInBounds:(CGRect)bounds safeAreaInsets:(UIEdgeInsets)insets {
    self.parentBounds = bounds;
    self.pipSafeAreaInsets = insets;
    self.currentPosition = self.config.position;
    self.currentOrientation = UIDeviceOrientationPortrait;

    CGSize size = [self pipSizeForBounds:bounds];
    CGPoint origin = [self originForPosition:self.currentPosition
                                    pipSize:size
                                     bounds:bounds
                             safeAreaInsets:insets];
    self.frame = CGRectMake(origin.x, origin.y, size.width, size.height);
    self.collapsedFrame = self.frame;
}

- (CGSize)pipSizeForBounds:(CGRect)bounds {
    CGFloat pipWidth = bounds.size.width * (self.config.widthPercent / 100.0);
    CGFloat pipHeight = pipWidth * self.config.aspectRatio.ratio;

    // Clamp height to 40% of container to prevent overflow in landscape
    // with tall aspect ratios (e.g. 9:16 at 30% width). Width is recalculated
    // from the clamped height to preserve the aspect ratio.
    CGFloat maxHeight = bounds.size.height * (kPiPMaxHeightPercent / 100.0);
    if (pipHeight > maxHeight) {
        pipHeight = maxHeight;
        pipWidth = pipHeight / self.config.aspectRatio.ratio;
    }

    return CGSizeMake(pipWidth, pipHeight);
}

- (CGPoint)originForPosition:(CTPiPPosition)position
                     pipSize:(CGSize)size
                      bounds:(CGRect)bounds
              safeAreaInsets:(UIEdgeInsets)insets {
    CGFloat vm = self.config.margins.vertical;
    CGFloat hm = self.config.margins.horizontal;

    CGFloat left    = insets.left  + hm;
    CGFloat right   = bounds.size.width  - insets.right  - hm - size.width;
    CGFloat top     = insets.top   + vm;
    CGFloat bottom  = bounds.size.height - insets.bottom - vm  - size.height;
    CGFloat centerX = (bounds.size.width  - size.width)  / 2.0;
    CGFloat centerY = (bounds.size.height - size.height) / 2.0;

    switch (position) {
        case CTPiPPositionTopLeft:      return CGPointMake(left,    top);
        case CTPiPPositionTopCenter:    return CGPointMake(centerX, top);
        case CTPiPPositionTopRight:     return CGPointMake(right,   top);
        case CTPiPPositionCenterLeft:   return CGPointMake(left,    centerY);
        case CTPiPPositionCenter:       return CGPointMake(centerX, centerY);
        case CTPiPPositionCenterRight:  return CGPointMake(right,   centerY);
        case CTPiPPositionBottomLeft:   return CGPointMake(left,    bottom);
        case CTPiPPositionBottomCenter: return CGPointMake(centerX, bottom);
        case CTPiPPositionBottomRight:  return CGPointMake(right,   bottom);
    }
}

// MARK: - Portrait-space center for a named position

/// Returns the center point in portrait-window coordinate space for the given named position,
/// taking into account the current device orientation (stored in self.currentOrientation).
/// Used by both applyDeviceOrientation: and snap so the math lives in one place.
- (CGPoint)portraitCenterForPosition:(CTPiPPosition)position {
    CGRect wb    = self.parentBounds;
    UIEdgeInsets pi = self.pipSafeAreaInsets;
    CGFloat wW   = wb.size.width;
    CGFloat wH   = wb.size.height;
    UIDeviceOrientation orientation = self.currentOrientation;

    BOOL isLandscapeLeft  = (orientation == UIDeviceOrientationLandscapeLeft);
    BOOL isLandscapeRight = (orientation == UIDeviceOrientationLandscapeRight);

    if (isLandscapeLeft || isLandscapeRight) {
        CGFloat lW = wH;  // landscape visual width
        CGFloat lH = wW;  // landscape visual height

        CGSize landscapePipSize = [self pipSizeForBounds:CGRectMake(0, 0, lW, lH)];
        CGFloat visualW = landscapePipSize.width;
        CGFloat visualH = landscapePipSize.height;

        UIEdgeInsets li;
        if (isLandscapeLeft) {
            li = UIEdgeInsetsMake(pi.right, pi.top, pi.left, pi.bottom);
        } else {
            li = UIEdgeInsetsMake(pi.left, pi.bottom, pi.right, pi.top);
        }

        CGFloat vm = self.config.margins.vertical;
        CGFloat hm = self.config.margins.horizontal;
        CGFloat l  = li.left   + hm;
        CGFloat r  = lW - li.right  - hm - visualW;
        CGFloat t  = li.top    + vm;
        CGFloat b  = lH - li.bottom - vm  - visualH;
        CGFloat cx = (lW - visualW) / 2.0;
        CGFloat cy = (lH - visualH) / 2.0;

        CGFloat lx, ly;
        switch (position) {
            case CTPiPPositionTopLeft:      lx = l;  ly = t;  break;
            case CTPiPPositionTopCenter:    lx = cx; ly = t;  break;
            case CTPiPPositionTopRight:     lx = r;  ly = t;  break;
            case CTPiPPositionCenterLeft:   lx = l;  ly = cy; break;
            case CTPiPPositionCenter:       lx = cx; ly = cy; break;
            case CTPiPPositionCenterRight:  lx = r;  ly = cy; break;
            case CTPiPPositionBottomLeft:   lx = l;  ly = b;  break;
            case CTPiPPositionBottomCenter: lx = cx; ly = b;  break;
            case CTPiPPositionBottomRight:  lx = r;  ly = b;  break;
        }

        CGFloat landscapeCX = lx + visualW / 2.0;
        CGFloat landscapeCY = ly + visualH / 2.0;

        if (isLandscapeLeft) {
            return CGPointMake(lH - landscapeCY, landscapeCX);
        } else {
            return CGPointMake(landscapeCY, lW - landscapeCX);
        }
    } else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
        CGSize pipSize = [self pipSizeForBounds:wb];
        CGPoint origin = [self originForPosition:position pipSize:pipSize bounds:wb safeAreaInsets:pi];
        return CGPointMake(wW - (origin.x + pipSize.width  / 2.0),
                           wH - (origin.y + pipSize.height / 2.0));
    } else {
        // Portrait (default)
        CGSize pipSize = [self pipSizeForBounds:wb];
        CGPoint origin = [self originForPosition:position pipSize:pipSize bounds:wb safeAreaInsets:pi];
        return CGPointMake(origin.x + pipSize.width  / 2.0,
                           origin.y + pipSize.height / 2.0);
    }
}

// MARK: - 9-Point Snap

- (void)snapToNearestAnchorInBounds:(CGRect)bounds safeAreaInsets:(UIEdgeInsets)insets {
    BOOL hasTransform = !CGAffineTransformIsIdentity(self.transform);
    CGPoint currentCenter = self.center;
    CTPiPPosition bestPosition = CTPiPPositionBottomRight;
    CGFloat bestDistance = CGFLOAT_MAX;

    for (NSInteger pos = CTPiPPositionTopLeft; pos <= CTPiPPositionBottomRight; pos++) {
        CGPoint anchorCenter;
        if (hasTransform) {
            // Landscape: compare in portrait-window space using the same mapping as applyDeviceOrientation:
            anchorCenter = [self portraitCenterForPosition:(CTPiPPosition)pos];
        } else {
            CGPoint origin = [self originForPosition:(CTPiPPosition)pos
                                             pipSize:self.bounds.size
                                              bounds:bounds
                                     safeAreaInsets:insets];
            anchorCenter = CGPointMake(origin.x + self.bounds.size.width  / 2.0,
                                       origin.y + self.bounds.size.height / 2.0);
        }
        CGFloat distance = fabs(currentCenter.x - anchorCenter.x) + fabs(currentCenter.y - anchorCenter.y);
        if (distance < bestDistance) {
            bestDistance = distance;
            bestPosition = (CTPiPPosition)pos;
        }
    }

    self.currentPosition = bestPosition;

    if (hasTransform) {
        // Never set self.frame on a transformed view — animate self.center instead.
        CGPoint snapCenter = [self portraitCenterForPosition:bestPosition];
        [UIView animateWithDuration:0.4
                              delay:0
             usingSpringWithDamping:0.7
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.center = snapCenter;
        } completion:nil];
        self.collapsedFrame = self.frame;
    } else {
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
}

// MARK: - Expand / Collapse

- (void)expandInBounds:(CGRect)bounds {
    self.collapsedFrame = self.frame;
    self.isExpanded = YES;
    [self.mediaView setContentFitMode:YES];
    [self.controlsView updateLayout:YES];
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
    [self cancelAutoHideTimer];
    [self.mediaView setContentFitMode:YES];
    [self.controlsView updateLayout:NO];

    if (self.isVideoType) {
        // Video collapsed: reset to hidden state
        self.controlsVisible = NO;
        self.controlsView.alpha = 0;
        self.controlsView.userInteractionEnabled = NO;
    } else {
        // Image/GIF: show controls and restart the 3-sec auto-hide timer
        [self showControlsAndScheduleAutoHide];
    }

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

// MARK: - Device orientation (transform-based rotation for non-rotating portrait window)

- (void)applyDeviceOrientation:(UIDeviceOrientation)orientation
                  windowBounds:(CGRect)windowBounds
               safeAreaInsets:(UIEdgeInsets)portraitInsets {
    if (self.isExpanded) { return; }

    // Store orientation first — portraitCenterForPosition: reads this during snap after drag.
    self.currentOrientation = orientation;

    CGFloat wW = windowBounds.size.width;   // portrait window width  (e.g. 390)
    CGFloat wH = windowBounds.size.height;  // portrait window height (e.g. 844)

    BOOL isLandscapeLeft  = (orientation == UIDeviceOrientationLandscapeLeft);
    BOOL isLandscapeRight = (orientation == UIDeviceOrientationLandscapeRight);
    BOOL isLandscape      = isLandscapeLeft || isLandscapeRight;

    // --- 1. Rotation transform ---
    // UIDeviceOrientationLandscapeLeft  = device top points LEFT, home on RIGHT
    //   → device rotated CCW from portrait → content must rotate CW (+π/2) to appear upright
    // UIDeviceOrientationLandscapeRight = device top points RIGHT, home on LEFT
    //   → device rotated CW from portrait → content must rotate CCW (-π/2) to appear upright
    CGAffineTransform transform;
    switch (orientation) {
        case UIDeviceOrientationLandscapeLeft:
            transform = CGAffineTransformMakeRotation(M_PI_2);
            break;
        case UIDeviceOrientationLandscapeRight:
            transform = CGAffineTransformMakeRotation(-M_PI_2);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            transform = CGAffineTransformMakeRotation(M_PI);
            break;
        default:
            transform = CGAffineTransformIdentity;
            break;
    }

    // --- 2. PiP size ---
    // For portrait/upsidedown: size from portrait window bounds.
    // For landscape: size from landscape bounds (lW=wH, lH=wW) so widthPercent and
    // aspectRatio are applied to the actual landscape screen dimensions.
    CGSize pipSize = [self pipSizeForBounds:windowBounds]; // portrait fallback
    CGFloat pipW = pipSize.width;
    CGFloat pipH = pipSize.height;

    // --- 3. Center in portrait window space for the named position ---
    CGPoint portraitCenter;

    if (isLandscape) {
        // Landscape visual dimensions: lW = portrait height, lH = portrait width.
        CGFloat lW = wH;
        CGFloat lH = wW;

        // Compute pip size against real landscape bounds so widthPercent and
        // aspectRatio (numerator/denominator) are honoured in landscape.
        CGSize landscapePipSize = [self pipSizeForBounds:CGRectMake(0, 0, lW, lH)];
        CGFloat visualW = landscapePipSize.width;   // landscape pip width
        CGFloat visualH = landscapePipSize.height;  // landscape pip height
        self.bounds = CGRectMake(0, 0, visualW, visualH);

        // Map portrait safe-area insets → landscape insets.
        // LandscapeLeft  (device top→LEFT,  home RIGHT): landscape edges map as:
        //   top=portrait right, left=portrait top, bottom=portrait left, right=portrait bottom
        // LandscapeRight (device top→RIGHT, home LEFT): landscape edges map as:
        //   top=portrait left, left=portrait bottom, bottom=portrait right, right=portrait top
        UIEdgeInsets li;
        if (isLandscapeLeft) {
            li = UIEdgeInsetsMake(portraitInsets.right, portraitInsets.top,
                                  portraitInsets.left,  portraitInsets.bottom);
        } else {
            li = UIEdgeInsetsMake(portraitInsets.left,  portraitInsets.bottom,
                                  portraitInsets.right, portraitInsets.top);
        }

        CGFloat vm = self.config.margins.vertical;
        CGFloat hm = self.config.margins.horizontal;

        CGFloat l  = li.left  + hm;
        CGFloat r  = lW - li.right  - hm - visualW;
        CGFloat t  = li.top   + vm;
        CGFloat b  = lH - li.bottom - vm  - visualH;
        CGFloat cx = (lW - visualW) / 2.0;
        CGFloat cy = (lH - visualH) / 2.0;

        CGFloat lx, ly;
        switch (self.currentPosition) {
            case CTPiPPositionTopLeft:      lx = l;  ly = t;  break;
            case CTPiPPositionTopCenter:    lx = cx; ly = t;  break;
            case CTPiPPositionTopRight:     lx = r;  ly = t;  break;
            case CTPiPPositionCenterLeft:   lx = l;  ly = cy; break;
            case CTPiPPositionCenter:       lx = cx; ly = cy; break;
            case CTPiPPositionCenterRight:  lx = r;  ly = cy; break;
            case CTPiPPositionBottomLeft:   lx = l;  ly = b;  break;
            case CTPiPPositionBottomCenter: lx = cx; ly = b;  break;
            case CTPiPPositionBottomRight:  lx = r;  ly = b;  break;
        }

        CGFloat landscapeCX = lx + visualW / 2.0;
        CGFloat landscapeCY = ly + visualH / 2.0;

        // Map landscape center → portrait window center.
        //
        // LandscapeLeft (device top→LEFT, home RIGHT):
        //   portrait_x = lH - landscape_y
        //   portrait_y = landscape_x
        //
        // LandscapeRight (device top→RIGHT, home LEFT):
        //   portrait_x = landscape_y
        //   portrait_y = lW - landscape_x
        if (isLandscapeLeft) {
            portraitCenter = CGPointMake(lH - landscapeCY, landscapeCX);
        } else {
            portraitCenter = CGPointMake(landscapeCY, lW - landscapeCX);
        }

    } else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
        CGPoint origin = [self originForPosition:self.currentPosition
                                         pipSize:pipSize
                                          bounds:windowBounds
                                  safeAreaInsets:portraitInsets];
        self.bounds = CGRectMake(0, 0, pipW, pipH);
        portraitCenter = CGPointMake(wW - (origin.x + pipW / 2.0),
                                     wH - (origin.y + pipH / 2.0));
    } else {
        // Portrait — reset transform and use normal frame.
        self.transform = CGAffineTransformIdentity;
        self.bounds = CGRectMake(0, 0, pipW, pipH);
        CGPoint origin = [self originForPosition:self.currentPosition
                                         pipSize:pipSize
                                          bounds:windowBounds
                                  safeAreaInsets:portraitInsets];
        CGRect frame = CGRectMake(origin.x, origin.y, pipW, pipH);
        self.frame = frame;
        self.collapsedFrame = frame;
        self.parentBounds = windowBounds;
        self.pipSafeAreaInsets = portraitInsets;
        return;
    }

    self.transform = transform;
    self.center = portraitCenter;
    self.collapsedFrame = self.frame;
    self.parentBounds = windowBounds;
    self.pipSafeAreaInsets = portraitInsets;
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

- (void)pipControlsDidTapDeeplink {
    [self.delegate pipContainerDidTapCTA];
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

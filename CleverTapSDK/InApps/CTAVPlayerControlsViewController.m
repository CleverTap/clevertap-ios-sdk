#import "CTAVPlayerControlsViewController.h"
#import "CTAVPlayerViewController.h"
#import "CTInAppUtils.h"
#import "CTSlider.h"

static const float kAVSliderHeight = 18;

@interface CTAVPlayerControlsViewController ()

@property (nonatomic, strong) IBOutlet UIView *containerView;
@property (nonatomic, strong) IBOutlet CTSlider *avSlider;
@property (nonatomic, strong) IBOutlet UIButton *playButton;
@property (nonatomic, strong) IBOutlet UILabel *currentTimeLabel;
@property (nonatomic, strong) IBOutlet UILabel *remainingTimeLabel;
@property (nonatomic, strong) IBOutlet UIButton *fullscreenButton;
@property (nonatomic, weak) NSTimer *controllersTimer;
@property (nonatomic, assign) NSInteger controllersTimeoutPeriod;
@property (nonatomic, assign) BOOL isControlsHidden;
@property (nonatomic, assign) BOOL allowsFullscreen;

@property (nonatomic, strong, readwrite) AVPlayer *player;
@property (nonatomic, strong) id periodicTimeObserver;

@end

@implementation CTAVPlayerControlsViewController

- (instancetype)initWithPlayer:(AVPlayer*)player andConfig:(NSDictionary *)config {
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:[CTInAppUtils bundle]];
    if (self) {
        _player = player;
        _allowsFullscreen = [config[@"fullscreen"] boolValue];
    }
    return self;
}

- (void)dealloc {
    [self.player pause];
    self.player = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.containerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.65f];
    
    // setup fullscreen button
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    UIImage *imageShrink = [UIImage imageNamed:@"ic_shrink.png" inBundle:bundle compatibleWithTraitCollection:nil];
    UIImage *imageExpand = [UIImage imageNamed:@"ic_expand.png" inBundle:bundle compatibleWithTraitCollection:nil];
    [self.fullscreenButton setImage:imageExpand forState:UIControlStateNormal];
    [self.fullscreenButton setImage:imageShrink forState:UIControlStateSelected];
    [self.fullscreenButton addTarget:self action:@selector(toggleFullscreen:) forControlEvents:UIControlEventTouchUpInside];
    
    self.fullscreenButton.hidden = !_allowsFullscreen;
    
    // setup progress slider
    UIImage *imagethumb = [UIImage imageNamed:@"ic_thumb.png" inBundle:bundle compatibleWithTraitCollection:nil];
    imagethumb = [imagethumb resizableImageWithCapInsets:UIEdgeInsetsZero resizingMode:UIImageResizingModeTile];
    [self.avSlider setThumbImage:imagethumb  forState:UIControlStateNormal];
    self.avSlider.tintColor = [UIColor whiteColor];
    self.avSlider.maximumTrackTintColor = [UIColor whiteColor];
    self.avSlider.minimumTrackTintColor = [UIColor redColor];
    [self.avSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.avSlider.minimumValue = 0;
    CGFloat availableDuration = [self duration];
    self.avSlider.maximumValue = round(availableDuration);
    
    [[NSLayoutConstraint constraintWithItem:self.avSlider
                                  attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                     toItem:nil attribute:NSLayoutAttributeNotAnAttribute
                                 multiplier:1 constant:kAVSliderHeight] setActive:YES];

    // setup time-labels
    self.currentTimeLabel.text = @"00:00";
    self.remainingTimeLabel.text = @"00:00";
    

    // setup play button
    UIImage *imagePlay = [UIImage imageNamed:@"ic_play.png" inBundle:bundle compatibleWithTraitCollection:nil];
    UIImage *imagePause = [UIImage imageNamed:@"ic_pause.png" inBundle:bundle compatibleWithTraitCollection:nil];
    [self.playButton setImage:imagePlay forState:UIControlStateNormal];
    [self.playButton setImage:imagePause forState:UIControlStateSelected];
    [self.playButton addTarget:self action:@selector(togglePlay) forControlEvents:UIControlEventTouchUpInside];
    
    self.controllersTimeoutPeriod = 3;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlayControls:)];
    [self.view addGestureRecognizer:tapGesture];
    
    __weak typeof(self) weakSelf = self;
    _periodicTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 2) queue:nil usingBlock:^(CMTime progressTime) {
        [weakSelf progressDidUpdate:progressTime];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self pause];
    [self.player removeTimeObserver:_periodicTimeObserver];
    _periodicTimeObserver = nil;
}

#pragma mark - Actions

- (void)play {
    if (self.player != nil) {
        [self.player play];
        [self.playButton setSelected:YES];
        [self startAVIdleCountdown];
    }
}

- (void)stop {
    [self pause];
    if (self.player != nil) {
        [self.player seekToTime:kCMTimeZero];
        [self.playButton setSelected:NO];
        [self stopAVIdleCountdown];
    }
}

- (void)pause {
    if (self.player != nil) {
        [self.player pause];
        [self.playButton setSelected:NO];
        [self stopAVIdleCountdown];
    }
}

- (CGFloat)duration {
    return (self.player && self.player.currentItem) ?  CMTimeGetSeconds(self.player.currentItem.asset.duration) : 0;
}

- (BOOL)isPlaying {
    return self.player && self.player.rate > 0;
}

- (CGFloat)currentTime {
    return self.player ? CMTimeGetSeconds(self.player.currentTime) : 0.0;
}

- (AVPlayerItemStatus)currentStatus {
    return (self.player && self.player.currentItem) ? self.player.currentItem.status : AVPlayerItemStatusUnknown;
}

- (void)togglePlay {
    if (![self isPlaying]){
        [self play];
    } else {
        [self pause];
    }
}

- (void)seekTo:(CMTime)time {
    if(self.player) {
        [self pause];
        [self.player seekToTime:time];
        if (![self isPlaying]) {
            [self play];
        }
    }
}

- (void)progressDidUpdate:(CMTime)progressTime {
    CGFloat availableDuration = [self duration];
    Float64 seconds = CMTimeGetSeconds(progressTime);
    NSString *secondsString = [NSString stringWithFormat:@"%02d", (int)(((int)seconds % 60))];
    NSString *minutesString = [NSString stringWithFormat:@"%02d", (int)(seconds/60)];
    self.currentTimeLabel.text = [NSString stringWithFormat:@"%@:%@", minutesString, secondsString];
    
    Float64 remaininingSeconds = round(availableDuration) - CMTimeGetSeconds(progressTime);
    NSString *secondsString1 = [NSString stringWithFormat:@"%02d", (int)(((int)remaininingSeconds % 60))];
    NSString *minutesString1 = [NSString stringWithFormat:@"%02d", (int)(remaininingSeconds/60)];
    self.remainingTimeLabel.text = [NSString stringWithFormat:@"-%@:%@", minutesString1, secondsString1];
    
    // move the slider thumb
    if ([self currentStatus] == AVPlayerStatusReadyToPlay) {
        CGFloat currentTime = [self currentTime];
        [self.avSlider setValue:round(currentTime) animated:NO];
    }
    
    if (round(seconds) >= round(availableDuration)) {
        [self stop];
    }
}

- (void)sliderValueChanged:(UISlider *)sender {
    Float64 seconds = self.avSlider.value;
    CMTime targetTime = CMTimeMake(seconds, 2);
    [self seekTo:targetTime];
}

- (void)togglePlayControls:(UIGestureRecognizer *)sender {
    if (self.isControlsHidden) {
        [self showControls:YES];
    }else {
        [self hideControls:YES];
    }
}

- (void)toggleFullscreen:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (self.delegate && [self.delegate respondsToSelector:@selector(toggleFullscreen)]) {
        [self.delegate toggleFullscreen];
    }
    [self hideControls:NO];
}

- (void)showControls:(BOOL)animated {
    if (!animated) {
        [self.containerView setAlpha:1.0f];
        self.isControlsHidden = YES;
        return;
    }
    [UIView animateWithDuration:0.3f animations:^{
        [self.containerView setAlpha:1.0f];
    } completion:^(BOOL finished) {
        self.isControlsHidden = false;
    }];
}

- (void)hideControls:(BOOL)animated {
    if (!animated) {
        [self.containerView setAlpha:0.0f];
        self.isControlsHidden = YES;
        return;
    }
    [UIView animateWithDuration:0.3f animations:^{
        [self.containerView setAlpha:0.0f];
    } completion:^(BOOL finished) {
        self.isControlsHidden = true;
    }];
}

- (void)startAVIdleCountdown {
    if (self.controllersTimer) {
        [self.controllersTimer invalidate];
    }
    if (self.controllersTimeoutPeriod > 0) {
        self.controllersTimer = [NSTimer scheduledTimerWithTimeInterval:self.controllersTimeoutPeriod target:self selector:@selector(hideControls:) userInfo:nil repeats:NO];
    }
}

- (void)stopAVIdleCountdown {
    if (self.controllersTimer) {
        [self.controllersTimer invalidate];
    }
}

@end

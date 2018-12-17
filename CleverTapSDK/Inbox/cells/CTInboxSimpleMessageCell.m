#import "CTInboxSimpleMessageCell.h"
#import <SDWebImage/FLAnimatedImageView+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>

static CGFloat kBorderWidth = 0.0;
static CGFloat kCornerRadius = 0.0;

@implementation CTInboxSimpleMessageCell

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
    self.avPlayerContainerView.hidden = YES;
    self.actionView.hidden = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _playerLayer.frame = self.avPlayerContainerView.bounds;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.containerView.layer.cornerRadius = kCornerRadius;
    self.containerView.layer.masksToBounds = YES;
    self.containerView.layer.borderColor = [UIColor colorWithWhite:0.5f alpha:1.0].CGColor;
    self.containerView.layer.borderWidth = kBorderWidth;
    self.cellImageView.contentMode = UIViewContentModeScaleAspectFit;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    for (AVPlayerLayer *layer in self.cellImageView.layer.sublayers) {
        [layer removeFromSuperlayer];
    }
    [self.cellImageView sd_cancelCurrentAnimationImagesLoad];
}

- (void)setupSimpleMessage:(CTInboxNotificationContentItem *)message {
    
    self.actionView.hidden = YES;
    self.volume.hidden = YES;
    self.playButton.hidden = YES;
    self.cellImageView.image = nil;
    self.cellImageView.animatedImage = nil;
    self.titleLabel.text = message.title;
    self.bodyLabel.text = message.message;
    if (message.mediaUrl) {
        self.cellImageView.hidden = NO;
        [self.cellImageView sd_setImageWithURL:[NSURL URLWithString:message.mediaUrl]
                              placeholderImage:nil
                                       options:(SDWebImageQueryDataWhenInMemory | SDWebImageQueryDiskSync)];
    }
}

- (void)setupVideoPlayer: (CleverTapInboxMessage *)message  {
    
    self.avPlayerContainerView.backgroundColor = [UIColor blackColor];

    self.avPlayerContainerView.hidden = NO;
    self.cellImageView.hidden = YES;
    self.volume.hidden = NO;
    self.playButton.hidden = NO;
    
    self.playButton.layer.cornerRadius = 30;
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    UIImage *imagePlay = [UIImage imageNamed:@"ic_play.png" inBundle:bundle compatibleWithTraitCollection:nil];
    UIImage *imagePause = [UIImage imageNamed:@"ic_pause.png" inBundle:bundle compatibleWithTraitCollection:nil];
    [self.playButton setImage:imagePlay forState:UIControlStateNormal];
    [self.playButton setImage:imagePause forState:UIControlStateSelected];
    [self.playButton addTarget:self action:@selector(togglePlay) forControlEvents:UIControlEventTouchUpInside];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
//    _avPlayer = [AVPlayer playerWithURL:[NSURL URLWithString:message.media[@"url"]]];
    _avPlayer = [[AVPlayer alloc] initWithURL: [NSURL URLWithString:message.media[@"url"]]];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    _avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    _playerLayer.frame = self.avPlayerContainerView.bounds;
    _playerLayer.needsDisplayOnBoundsChange = YES;
    for (AVPlayerLayer *layer in self.avPlayerContainerView.layer.sublayers) {
        [layer removeFromSuperlayer];
    }
    for (AVPlayerLayer *layer in self.cellImageView.layer.sublayers) {
        [layer removeFromSuperlayer];
    }
    [self.avPlayerContainerView.layer addSublayer:_playerLayer];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlayControls:)];
    [self.avPlayerContainerView addGestureRecognizer:tapGesture];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loopVideo) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
    
    if (self.isVideoMuted) {
        [_avPlayer setMuted:YES];
        [self.volume setTitle:@"🔇" forState:UIControlStateNormal];
    } else {
        [_avPlayer setMuted:NO];
        [self.volume setTitle:@"🔈" forState:UIControlStateNormal];
    }
    
    [self layoutSubviews];
//    [_avPlayer play];
//    [self.avPlayerContainerView addSubview:_avPlayer];
}

#pragma mark - Player Controls

- (IBAction)volumeButtonTapped:(UIButton *)sender {
    if (self.avPlayer.isMuted) {
        [self.avPlayer setMuted:NO];
        self.isVideoMuted = NO;
        [sender setTitle:@"🔈" forState:UIControlStateNormal];
    } else {
        [self.avPlayer setMuted:YES];
        self.isVideoMuted = YES;
        [sender setTitle:@"🔇" forState:UIControlStateNormal];
    }
}

- (BOOL)isPlaying {
    return self.avPlayer && self.avPlayer.rate > 0;
}

- (void)togglePlay {
    if (![self isPlaying]){
        [self play];
    } else {
        [self pause];
    }
}

- (void)play {
    if (self.avPlayer != nil) {
        [self.avPlayer play];
        [self.playButton setSelected:YES];
    }
}

- (void)stop {
    [self pause];
    if (self.avPlayer != nil) {
        [self.avPlayer seekToTime:kCMTimeZero];
        [self.playButton setSelected:NO];
//        [self stopAVIdleCountdown];
    }
}

- (void)pause {
    if (self.avPlayer != nil) {
        [self.avPlayer pause];
        [self.playButton setSelected:NO];
//        [self stopAVIdleCountdown];
    }
}

- (void)loopVideo {
    
    [self.avPlayer seekToTime:kCMTimeZero];
}

- (void)togglePlayControls:(UIGestureRecognizer *)sender {
    if (self.isControlsHidden) {
        [self showControls:YES];
    }else {
        [self hideControls:YES];
    }
}

- (void)showControls:(BOOL)animated {
    if (!animated) {
        self.playButton.hidden = NO;
        self.isControlsHidden = false;
        return;
    }
    [UIView animateWithDuration:0.3f animations:^{
        self.playButton.hidden = NO;
    } completion:^(BOOL finished) {
        self.isControlsHidden = false;
    }];
}

- (void)hideControls:(BOOL)animated {
    if (!animated) {
        self.playButton.hidden = YES;
        self.isControlsHidden = true;
        return;
    }
    [UIView animateWithDuration:0.3f animations:^{
        self.playButton.hidden = YES;
    } completion:^(BOOL finished) {
        self.isControlsHidden = true;
    }];
}


@end

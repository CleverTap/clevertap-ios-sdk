#import "CTInboxBaseMessageCell.h"

static UIImage *volumeOffImage;
static UIImage *volumeOnImage;
static UIImage *playImage;
static UIImage *pauseImage;
static UIImage *audioPlaceholderImage;

@implementation CTInboxBaseMessageCell

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

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.avPlayerContainerView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.avPlayerLayer.frame = self.avPlayerContainerView.bounds;
        });
    }
}

- (void)setup {
    // no-op in base
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)configureForMessage:(CleverTapInboxMessage *)message {
    if (message.backgroundColor && ![message.backgroundColor isEqual:@""]) {
        self.containerView.backgroundColor = [CTInAppUtils ct_colorWithHexString:message.backgroundColor];
    } else {
        self.containerView.backgroundColor = [UIColor whiteColor];
    }
    [self doLayoutForMessage:message];
    [self setupMessage:message];
    [self layoutIfNeeded];
    [self layoutSubviews];
}
- (void)doLayoutForMessage:(CleverTapInboxMessage *)message {
    // no-op in base
}
- (void)setupMessage:(CleverTapInboxMessage *)message {
    // no-op in base
}

#pragma mark - Player Controls

- (UIImage*)getAudioPlaceholderImage {
    if (audioPlaceholderImage == nil) {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        audioPlaceholderImage = [UIImage imageNamed:@"sound-wave-headphones.png" inBundle:bundle compatibleWithTraitCollection:nil];
    }
    return audioPlaceholderImage;
}
- (UIImage*)getPlayImage {
    if (playImage == nil) {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        playImage = [UIImage imageNamed:@"ic_play.png" inBundle:bundle compatibleWithTraitCollection:nil];
    }
    return playImage;
}

-(UIImage*)getPauseImage {
    if (pauseImage == nil) {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        pauseImage = [UIImage imageNamed:@"ic_pause.png" inBundle:bundle compatibleWithTraitCollection:nil];
    }
    return pauseImage;
}

- (UIImage*)getVolumeOnImage {
    if (volumeOnImage == nil) {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        volumeOnImage = [UIImage imageNamed:@"volume_on.png" inBundle:bundle compatibleWithTraitCollection:nil];
    }
    return volumeOnImage;
}

- (UIImage*)getVolumeOffImage {
    if (volumeOffImage == nil) {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        volumeOffImage = [UIImage imageNamed:@"volume_off.png" inBundle:bundle compatibleWithTraitCollection:nil];
    }
    return volumeOffImage;
}

- (void)setupMediaPlayer  {
    if (!self.message || !self.message.content || self.message.content.count <= 0) return;
    
    CleverTapInboxMessageContent *content = self.message.content[0];
    self.controllersTimeoutPeriod = 2;
    self.avPlayerContainerView.backgroundColor = [UIColor blackColor];
    self.avPlayerContainerView.hidden = NO;
    self.avPlayerControlsView.alpha = 1.0;
    self.cellImageView.hidden = YES;
    self.volume.hidden = NO;
    self.playButton.hidden = NO;
    if (content.mediaIsVideo) {
        self.isAVMuted = YES;
    } else if (content.mediaIsAudio) {
        self.isAVMuted = NO;
    }
    self.playButton.layer.cornerRadius = 30;
    [self.playButton setSelected:NO];
    [self.playButton setImage:[self getPlayImage] forState:UIControlStateNormal];
    [self.playButton setImage:[self getPauseImage] forState:UIControlStateSelected];
    [self.playButton addTarget:self action:@selector(togglePlay) forControlEvents:UIControlEventTouchUpInside];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    self.avPlayer = [AVPlayer playerWithURL:[NSURL URLWithString:content.mediaUrl]];
    self.avPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    self.avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    self.avPlayerLayer.frame = self.avPlayerContainerView.bounds;
    self.avPlayerLayer.needsDisplayOnBoundsChange = YES;
    for (AVPlayerLayer *layer in self.avPlayerContainerView.layer.sublayers) {
        [layer removeFromSuperlayer];
    }
    for (AVPlayerLayer *layer in self.cellImageView.layer.sublayers) {
        [layer removeFromSuperlayer];
    }
    
    [self.avPlayerContainerView.layer addSublayer:self.avPlayerLayer];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlayControls:)];
    [self.avPlayerControlsView addGestureRecognizer:tapGesture];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
    
    if (self.isAVMuted) {
        [self.avPlayer setMuted:YES];
        [self.volume setImage:[self getVolumeOffImage] forState:UIControlStateNormal];
    } else {
        [self.avPlayer setMuted:NO];
        [self.volume setImage:[self getVolumeOnImage] forState:UIControlStateNormal];
    }
    
    if (content.mediaIsAudio) {
        self.cellImageView.backgroundColor = [UIColor blackColor];
        self.cellImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.cellImageView.image = [self getAudioPlaceholderImage];
        self.cellImageView.hidden = NO;
        self.volume.hidden = YES;
    }
    [self prepareToPlay];
    [self layoutIfNeeded];
    [self layoutSubviews];
}

- (IBAction)volumeButtonTapped:(UIButton *)sender {
    if (self.avPlayer == nil) return;
    if ([self isMuted]) {
        [self.avPlayer setMuted:NO];
        self.isAVMuted = NO;
        [self.volume setImage:[self getVolumeOnImage] forState:UIControlStateNormal];
    } else {
        [self.avPlayer setMuted:YES];
        self.isAVMuted = YES;
        [self.volume setImage:[self getVolumeOffImage] forState:UIControlStateNormal];
    }
}

- (BOOL)isMuted {
    if (self.avPlayer == nil) return YES;
    return self.avPlayer.muted;
}

- (BOOL)isPlaying {
    if (self.avPlayer == nil) return NO;
    return self.avPlayer && self.avPlayer.rate > 0;
}

- (void)togglePlay {
    if (![self isPlaying]){
        [self play];
    } else {
        [self pause];
    }
}

- (void)prepareToPlay {
    if (self.avPlayer == nil) return;
    [self.avPlayer play];
    [self.avPlayer pause];
}

- (void)play {
    if (self.avPlayer != nil) {
        [self.avPlayer play];
        [self.playButton setSelected:YES];
        [self startAVIdleCountdown];
    }
}

- (void)stop {
    [self pause];
    if (self.avPlayer != nil) {
        [self.avPlayer seekToTime:kCMTimeZero];
        [self.playButton setSelected:NO];
        [self stopAVIdleCountdown];
    }
}

- (void)pause {
    if (self.avPlayer != nil) {
        [self.avPlayer pause];
        [self.playButton setSelected:NO];
        [self stopAVIdleCountdown];
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    id object = [notification object];
    if (object && [object isKindOfClass:[AVPlayerItem class]]) {
        AVPlayerItem* item = (AVPlayerItem*)[notification object];
        [item seekToTime:kCMTimeZero];
    }
    [self pause];
    [self showControls:YES];
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

- (void)setupInboxMessageActions:(CleverTapInboxMessageContent *)content {
    if (!content || !content.links || content.links.count < 0) return;
    
    self.actionView.hidden = NO;
    self.actionView.firstButton.hidden = YES;
    self.actionView.secondButton.hidden = YES;
    self.actionView.thirdButton.hidden = YES;
    
    if (content.links.count == 1) {
        [[NSLayoutConstraint constraintWithItem:self.actionView.firstButton
                                      attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                         toItem:self.containerView attribute:NSLayoutAttributeWidth
                                     multiplier:1.0 constant:0] setActive:YES];
        
        self.actionView.firstButton = [self.actionView setupViewForButton:self.actionView.firstButton forText:content.links[0] withIndex:0];
        
    } else if (content.links.count == 2) {
        [[NSLayoutConstraint constraintWithItem:self.actionView.firstButton
                                      attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                         toItem:self.containerView attribute:NSLayoutAttributeWidth
                                     multiplier:0.5 constant:0] setActive:YES];
        self.actionView.firstButton = [self.actionView setupViewForButton:self.actionView.firstButton forText:content.links[0] withIndex:0];
        self.actionView.secondButton = [self.actionView setupViewForButton:self.actionView.secondButton forText:content.links[1] withIndex:1];
        
    } else if (content.links.count > 2) {
        [[NSLayoutConstraint constraintWithItem:self.actionView.firstButton
                                      attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                         toItem:self.containerView attribute:NSLayoutAttributeWidth
                                     multiplier:0.33 constant:0] setActive:YES];
        self.actionView.firstButton = [self.actionView setupViewForButton:self.actionView.firstButton forText:content.links[0] withIndex:0];
        self.actionView.thirdButton = [self.actionView setupViewForButton:self.actionView.thirdButton forText:content.links[1] withIndex:1];
        self.actionView.secondButton = [self.actionView setupViewForButton:self.actionView.secondButton forText:content.links[2] withIndex:2];
    }
}

#pragma mark CTInboxActionViewDelegate

- (void)handleInboxNotificationAtIndex:(int)index {
    int i = index;
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:[NSNumber numberWithInt:0] forKey:@"index"];
    [userInfo setObject:[NSNumber numberWithInt:i] forKey:@"buttonIndex"];
    [[NSNotificationCenter defaultCenter] postNotificationName:CLTAP_INBOX_MESSAGE_TAPPED_NOTIFICATION object:self.message userInfo:userInfo];
}

- (void)handleOnMessageTapGesture:(UITapGestureRecognizer *)sender {
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:[NSNumber numberWithInt:0] forKey:@"index"];
    [userInfo setObject:[NSNumber numberWithInt:-1] forKey:@"buttonIndex"];
    [[NSNotificationCenter defaultCenter] postNotificationName:CLTAP_INBOX_MESSAGE_TAPPED_NOTIFICATION object:self.message userInfo:userInfo];
}

@end

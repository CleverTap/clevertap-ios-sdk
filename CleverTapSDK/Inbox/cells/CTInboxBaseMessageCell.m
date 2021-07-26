
#import "CTInboxBaseMessageCell.h"

static UIImage *volumeOffImage;
static UIImage *volumeOnImage;
static UIImage *playImage;
static UIImage *pauseImage;
static UIImage *audioPlaceholderImage;
static UIImage *videoPlaceholderImage;
static UIImage *portraitPlaceholderImage;
static UIImage *landscapePlaceholderImage;
static NSString * const kOrientationPortrait = @"p";

@implementation CTInboxBaseMessageCell

- (instancetype)init {
    if (self = [super init]) {
        [self _sharedInit];
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self _sharedInit];
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self _sharedInit];
        [self setup];
    }
    return self;
}

- (void)_sharedInit {
    self.sdWebImageOptions = (SDWebImageRetryFailed);
    self.sdWebImageContext = @{SDWebImageContextStoreCacheType : @(SDImageCacheTypeMemory)};
}

- (void)dealloc {
    if (self.thumbnailGenerator) {
        [self.thumbnailGenerator cleanup];
        self.thumbnailGenerator = nil;
    }
    if (self.avPlayer) {
        [self.avPlayer.currentItem removeObserver:self forKeyPath:@"status"];
    }
    if (self.avPlayerLayer) {
        [self.avPlayerLayer removeObserver:self forKeyPath:@"readyForDisplay"];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.cellImageView.backgroundColor = [UIColor clearColor];
    if (self.avPlayerContainerView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.avPlayerLayer.frame = self.avPlayerContainerView.bounds;
        });
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.avPlayer) {
        [self.avPlayer.currentItem removeObserver:self forKeyPath:@"status"];
        [self.avPlayer pause];
        self.avPlayer = nil;
    }
    if (self.avPlayerLayer) {
        [self.avPlayerLayer removeObserver:self forKeyPath:@"readyForDisplay"];
        self.avPlayerLayer = nil;
    }
}

- (void)setup {
    // no-op in base
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)configureForMessage:(CleverTapInboxMessage *)message {
    self.message = message;
    if (message.backgroundColor && ![message.backgroundColor isEqual:@""]) {
        self.containerView.backgroundColor = [CTUIUtils ct_colorWithHexString:message.backgroundColor];
    } else {
        self.containerView.backgroundColor = [UIColor whiteColor];
    }
    
    self.messageType = [CTInboxUtils inboxMessageTypeFromString:message.type];
    if ([self hasAudio] || [self hasVideo]) {
        Boolean isPortrait = [message.orientation.uppercaseString isEqualToString:@"P"];
        switch (self.messageType) {
            case CTInboxMessageTypeSimple:
                self.mediaPlayerCellType = isPortrait ? CTMediaPlayerCellTypeTopPortrait : CTMediaPlayerCellTypeTopLandscape;
                break;
            case CTInboxMessageTypeCarousel:
                self.mediaPlayerCellType = CTMediaPlayerCellTypeNone;
                break;
            case CTInboxMessageTypeCarouselImage:
                self.mediaPlayerCellType = CTMediaPlayerCellTypeNone;
                break;
            case CTInboxMessageTypeMessageIcon:
                if (message.content[0].actionHasLinks) {
                    self.mediaPlayerCellType = isPortrait ? CTMediaPlayerCellTypeMiddlePortrait : CTMediaPlayerCellTypeMiddleLandscape;
                } else {
                    self.mediaPlayerCellType = isPortrait ? CTMediaPlayerCellTypeBottomPortrait : CTMediaPlayerCellTypeBottomLandscape;
                }
                break;
            default:
                self.mediaPlayerCellType = CTMediaPlayerCellTypeNone;
                CleverTapLogStaticDebug(@"unknown Inbox Message Type, defaulting to CTMediaPlayerCellTypeNone");
                break;
        }
    } else {
        self.mediaPlayerCellType = CTMediaPlayerCellTypeNone;
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

- (void)configureActionView:(BOOL)hide {
    self.actionView.hidden = hide;
    self.actionViewHeightConstraint.constant = hide ? 0 : 45;
    self.actionView.delegate = hide ? nil : self;
}

- (UIImage *)getPortraitPlaceHolderImage {
    if (portraitPlaceholderImage == nil) {
        portraitPlaceholderImage = [CTUIUtils getImageForName:@"ct_default_portrait_image.png"];
    }
    return portraitPlaceholderImage;
}

- (UIImage *)getLandscapePlaceHolderImage {
    if (landscapePlaceholderImage == nil) {
        landscapePlaceholderImage = [CTUIUtils getImageForName:@"ct_default_landscape_image.png"];
    }
    return landscapePlaceholderImage;
}

- (BOOL)orientationIsPortrait {
    return [self.message.orientation.uppercaseString isEqualToString:kOrientationPortrait.uppercaseString];
}

- (BOOL)mediaIsEmpty {
    CleverTapInboxMessageContent *content = [self.message.content firstObject];
    return (content.mediaUrl == nil || [content.mediaUrl isEqual: @""]);
}

- (BOOL)deviceOrientationIsLandscape {
    return [CTUIUtils isDeviceOrientationLandscape];
}


#pragma mark - Player Controls

- (UIImage*)getAudioPlaceholderImage {
    if (audioPlaceholderImage == nil) {
        audioPlaceholderImage = [CTUIUtils getImageForName:@"ct_default_audio.png"];
    }
    return audioPlaceholderImage;
}

- (UIImage *)getVideoPlaceHolderImage {
    if (videoPlaceholderImage == nil) {
        videoPlaceholderImage = [CTUIUtils getImageForName:@"ct_default_video.png"];
    }
    return videoPlaceholderImage;
}

- (UIImage*)getPlayImage {
    if (playImage == nil) {
        playImage = [CTUIUtils getImageForName:@"ic_play.png"];
    }
    return playImage;
}

- (UIImage*)getPauseImage {
    if (pauseImage == nil) {
        pauseImage = [CTUIUtils getImageForName:@"ic_pause.png"];
    }
    return pauseImage;
}

- (UIImage*)getVolumeOnImage {
    if (volumeOnImage == nil) {
        volumeOnImage = [CTUIUtils getImageForName:@"ct_volume_on.png"];
    }
    return volumeOnImage;
}

- (UIImage*)getVolumeOffImage {
    if (volumeOffImage == nil) {
        volumeOffImage = [CTUIUtils getImageForName:@"ct_volume_off.png"];
    }
    return volumeOffImage;
}

- (void)setupMediaPlayer  {
    if (!self.message || !self.message.content || self.message.content.count <= 0) return;
    
    if (!self.volumeButton) {
        self.volumeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30.f, 30.f)];
        [self.volumeButton addTarget:self action:@selector(volumeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.avPlayerControlsView addSubview:self.volumeButton];
    }
    
    CleverTapInboxMessageContent *content = self.message.content[0];
    
    self.hasVideoPoster = NO;
    self.controllersTimeoutPeriod = 1.0;
    self.avPlayerContainerView.backgroundColor = [UIColor clearColor];
    self.avPlayerContainerView.hidden = NO;
    self.avPlayerControlsView.alpha = 1.0;
    self.activityIndicator.hidden = NO;
    self.cellImageView.hidden = YES;
    self.cellImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.volumeButton.hidden = YES;
    self.playButton.hidden = NO;
    self.isAVMuted = content.mediaIsVideo;
    
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
    for (CALayer *layer in self.avPlayerContainerView.layer.sublayers) {
        if ([layer isKindOfClass:[AVPlayerLayer class]]) {
            [layer removeFromSuperlayer];
        }
    }
    [self.avPlayerContainerView.layer addSublayer:self.avPlayerLayer];
    
    [self hideControls:NO];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlayControls:)];
    [self.avPlayerControlsView addGestureRecognizer:tapGesture];
    
    [self.avPlayer.currentItem addObserver:self forKeyPath:@"status" options:0 context:NULL];
    [self.avPlayerLayer addObserver:self forKeyPath:@"readyForDisplay" options:0 context:NULL];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
    
    if (self.isAVMuted) {
        [self.avPlayer setMuted:YES];
        [self.volumeButton setImage:[self getVolumeOffImage] forState:UIControlStateNormal];
    } else {
        [self.avPlayer setMuted:NO];
        [self.volumeButton setImage:[self getVolumeOnImage] forState:UIControlStateNormal];
    }
    
    if (content.mediaIsAudio) {
        self.cellImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.cellImageView.image = [self getAudioPlaceholderImage];
        self.cellImageView.hidden = NO;
        self.cellImageView.alpha = 1.0;
        self.volumeButton.hidden = YES;
        [self.activityIndicator startAnimating];
    }
    
    if (content.mediaIsVideo) {
        self.cellImageView.hidden = NO;
        self.cellImageView.alpha = 1.0;
        self.hasVideoPoster = YES;
        if (content.videoPosterUrl != nil && content.videoPosterUrl.length > 0) {
            [self.cellImageView sd_setImageWithURL:[NSURL URLWithString:content.videoPosterUrl]
                                  placeholderImage: [self getVideoPlaceHolderImage]
                                           options:self.sdWebImageOptions context:self.sdWebImageContext];
        } else {
            self.cellImageView.image = [self getVideoPlaceHolderImage];
            if (!self.thumbnailGenerator) {
                self.thumbnailGenerator = [[CTVideoThumbnailGenerator alloc] init];
            }
            [self.thumbnailGenerator generateImageFromUrl:content.mediaUrl withCompletionBlock:^(UIImage *image, NSString *sourceUrl) {
                dispatch_async(dispatch_get_main_queue(), ^ {
                    CleverTapInboxMessageContent *content = self.message.content[0];
                    if (image && [sourceUrl isEqualToString:content.mediaUrl]) {
                        self.cellImageView.image = image;
                    }
                });
            }];
        }
    }
    [self layoutIfNeeded];
    [self layoutSubviews];
}

- (BOOL)hasAudio {
    if (!self.message.content || self.message.content.count < 0) {
        return false;
    }
    return self.message.content[0].mediaIsAudio;
}

- (BOOL)hasVideo {
    if (!self.message.content || self.message.content.count < 0) {
        return false;
    }
    return self.message.content[0].mediaIsVideo;
}

- (CGRect)videoRect {
    return (self.avPlayerLayer && [self hasVideo]) ? self.avPlayerLayer.videoRect : CGRectZero;
}

- (IBAction)volumeButtonTapped:(UIButton *)sender {
    if (self.avPlayer == nil) return;
    if ([self isMuted]) {
        [self.avPlayer setMuted:NO];
        self.isAVMuted = NO;
        [self.volumeButton setImage:[self getVolumeOnImage] forState:UIControlStateNormal];
    } else {
        [self.avPlayer setMuted:YES];
        self.isAVMuted = YES;
        [self.volumeButton setImage:[self getVolumeOffImage] forState:UIControlStateNormal];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CLTAP_INBOX_MESSAGE_MEDIA_MUTED_NOTIFICATION object:self userInfo:@{@"muted":@(self.isAVMuted)}];
}

- (void)mute:(BOOL)mute {
    if (self.avPlayer == nil) return;
    [self.avPlayer setMuted:mute];
    self.isAVMuted = mute;
    UIImage *image = mute ? [self getVolumeOffImage] : [self getVolumeOnImage];
    [self.volumeButton setImage: image forState:UIControlStateNormal];
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

- (void)play {
    if (self.avPlayer != nil) {
        [self.activityIndicator startAnimating];
        [self.avPlayer play];
        [self hideControls:NO];
        [self.playButton setSelected:YES];
        [self startAVIdleCountdown];
        [[NSNotificationCenter defaultCenter] postNotificationName:CLTAP_INBOX_MESSAGE_MEDIA_PLAYING_NOTIFICATION object:self userInfo:nil];
    }
}

- (void)stop {
    [self pause];
    if (self.avPlayer != nil) {
        [self.avPlayer seekToTime:kCMTimeZero];
    }
}

- (void)pause {
    if (self.avPlayer != nil) {
        [self.avPlayer pause];
        [self.playButton setSelected:NO];
        [self showControls:YES];
        [self stopAVIdleCountdown];
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    id object = [notification object];
    if (object && [object isKindOfClass:[AVPlayerItem class]]) {
        AVPlayerItem *item = (AVPlayerItem*)[notification object];
        [item seekToTime:kCMTimeZero completionHandler:nil];
    }
    [self pause];
    [self showControls:YES];
}

- (void)togglePlayControls:(UIGestureRecognizer *)sender {
    if (self.isControlsHidden) {
        [self showControls:YES];
        if ([self isPlaying]) {
            [self startAVIdleCountdown];
        }
    }else {
        [self hideControls:YES];
    }
}

- (void)showControls:(BOOL)animated {
    if (!animated) {
        self.playButton.hidden = NO;
        self.isControlsHidden = NO;
        return;
    }
    [UIView animateWithDuration:0.3f animations:^{
        self.playButton.hidden = NO;
    } completion:^(BOOL finished) {
        self.isControlsHidden = NO;
    }];
}

- (void)hideControls:(BOOL)animated {
    if (!animated) {
        self.playButton.hidden = YES;
        self.isControlsHidden = YES;
        return;
    }
    [UIView animateWithDuration:0.3f animations:^{
        self.playButton.hidden = YES;
    } completion:^(BOOL finished) {
        self.isControlsHidden = YES;
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"readyForDisplay"]) {
        if ([self hasVideo] && !self.cellImageView.isHidden) {
            [UIView animateWithDuration:0.5f animations:^{
                self ->_cellImageView.alpha = 0.0;
            } completion:^(BOOL finished) {
                self->_cellImageView.hidden = YES;
                self->_cellImageView.alpha = 1.0;
            }];
        }
    }
    
    if (self.avPlayer.currentItem.status == AVPlayerStatusReadyToPlay) {
        if (![self isPlaying]) {
            [self showControls:YES];
        }
        if (!self.activityIndicator.isHidden) {
            [self.activityIndicator stopAnimating];
            [self.activityIndicator setHidden:YES];
        }
        if (self.volumeButton.isHidden && [self hasVideo]) {
            CGRect videoRect = [self videoRect];
            self.volumeButton.frame = CGRectMake(videoRect.origin.x+30.f,(videoRect.origin.y+videoRect.size.height)-60.f, 30.f, 30.f);
            self.volumeButton.hidden = NO;
        }
    }
}

- (void)setupInboxMessageActions:(CleverTapInboxMessageContent *)content {
    if (!content || !content.actionHasLinks || !content.links || content.links.count < 0) return;
    
    self.actionView.hidden = NO;
    self.actionView.firstButton.hidden = YES;
    self.actionView.secondButton.hidden = YES;
    self.actionView.thirdButton.hidden = YES;
    self.actionView.secondButtonWidthConstraint.priority = 750;
    self.actionView.thirdButtonWidthConstraint.priority = 750;
    
    if (content.links.count == 1) {
        self.actionView.firstButton = [self.actionView setupViewForButton:self.actionView.firstButton forText:content.links[0] withIndex:0];
        self.actionView.secondButtonWidthConstraint.priority = 999;
        self.actionView.thirdButtonWidthConstraint.priority = 999;
    } else if (content.links.count == 2) {
        self.actionView.firstButton = [self.actionView setupViewForButton:self.actionView.firstButton forText:content.links[0] withIndex:0];
        self.actionView.secondButton = [self.actionView setupViewForButton:self.actionView.secondButton forText:content.links[1] withIndex:1];
        self.actionView.thirdButtonWidthConstraint.priority = 999;
    } else if (content.links.count > 2) {
        self.actionView.firstButton = [self.actionView setupViewForButton:self.actionView.firstButton forText:content.links[0] withIndex:0];
        self.actionView.secondButton = [self.actionView setupViewForButton:self.actionView.secondButton forText:content.links[1] withIndex:1];
        self.actionView.thirdButton = [self.actionView setupViewForButton:self.actionView.thirdButton forText:content.links[2] withIndex:2];
    }
}


#pragma mark - CTInboxActionViewDelegate

- (void)handleInboxMessageTappedAtIndex:(int)index {
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

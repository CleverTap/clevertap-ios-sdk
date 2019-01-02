#import "CTInboxSimpleMessageCell.h"
#import <SDWebImage/FLAnimatedImageView+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "CTConstants.h"
#import "CTInAppUtils.h"

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
    dispatch_async(dispatch_get_main_queue(), ^{
        self.playerLayer.frame = self.avPlayerContainerView.bounds;
    });
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;

//    self.containerView.layer.cornerRadius = kCornerRadius;
    self.containerView.layer.masksToBounds = YES;
//    self.containerView.layer.borderColor = [UIColor colorWithWhite:0.5f alpha:1.0].CGColor;
//    self.containerView.layer.borderWidth = kBorderWidth;
    
    self.readView.layer.cornerRadius = 5;
    self.readView.layer.masksToBounds = YES;
}

- (void)layoutNotification:(CleverTapInboxMessage *)message {
    
    CleverTapInboxMessageContent *content = message.content[0];
    
    self.cellImageView.hidden = YES;
    self.avPlayerControlsView.alpha = 0.0;
    self.avPlayerContainerView.hidden = YES;

    if (content.mediaUrl == nil || [content.mediaUrl isEqual: @""]) {
        self.imageViewHeightContraint.priority = 999;
        self.imageViewLRatioContraint.priority = 750;
        self.imageViewPRatioContraint.priority = 750;
    } else if ([message.orientation.uppercaseString isEqualToString:@"P"] || message.orientation == nil ) {
        self.imageViewPRatioContraint.priority = 999;
        self.imageViewLRatioContraint.priority = 750;
        self.imageViewHeightContraint.priority = 750;
    } else {
        self.imageViewHeightContraint.priority = 750;
        self.imageViewPRatioContraint.priority = 750;
        self.imageViewLRatioContraint.priority = 999;
    }
    
    if (content.links.count == 0) {
        _actionViewHeightContraint.constant = 0.1;
    } else {
        _actionViewHeightContraint.constant = 44;
    }
    
    self.playButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    self.playButton.layer.borderWidth = 2.0;
    self.actionView.hidden = YES;
    
    self.titleLabel.textColor = [CTInAppUtils ct_colorWithHexString:content.titleColor];
    self.bodyLabel.textColor = [CTInAppUtils ct_colorWithHexString:content.messageColor];
    
    [self layoutSubviews];
    [self layoutIfNeeded];
}

- (void)setupSimpleMessage:(CleverTapInboxMessage *)message {
    
    self.message = message;
    CleverTapInboxMessageContent *content = message.content[0];
    
    self.cellImageView.image = nil;
    self.cellImageView.animatedImage = nil;
    self.cellImageView.clipsToBounds = YES;
    
    self.titleLabel.text = content.title;
    self.bodyLabel.text = content.message;
    self.dateLabel.text = message.relativeDate;;

    if  (content.links.count > 0) {
        [self setupInboxMessageActions:content];
    }
    
    // mark read/unread
    if (message.isRead) {
        self.readView.hidden = YES;
    } else {
        self.readView.hidden = NO;
    }
    
    // set content mode for media
    if (content.mediaIsGif) {
        self.cellImageView.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        self.cellImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    
    if (content.mediaUrl && !content.mediaIsVideo) {
        self.cellImageView.hidden = NO;
        [self.cellImageView sd_setImageWithURL:[NSURL URLWithString:content.mediaUrl]
                              placeholderImage:nil
                                       options:(SDWebImageQueryDataWhenInMemory | SDWebImageQueryDiskSync)];
    } else if (content.mediaIsVideo) {
        [self setupVideoPlayer:message];
    }
}

- (void)setupVideoPlayer: (CleverTapInboxMessage *)message  {
    
    CleverTapInboxMessageContent *content = message.content[0];
    self.controllersTimeoutPeriod = 2;
    
    self.avPlayerContainerView.backgroundColor = [UIColor blackColor];
    self.avPlayerContainerView.hidden = NO;
    self.avPlayerControlsView.alpha = 1.0;
    self.cellImageView.hidden = YES;
    self.volume.hidden = NO;
    self.playButton.hidden = NO;
    
    self.playButton.layer.cornerRadius = 30;
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    UIImage *imagePlay = [UIImage imageNamed:@"ic_play.png" inBundle:bundle compatibleWithTraitCollection:nil];
    UIImage *imagePause = [UIImage imageNamed:@"ic_pause.png" inBundle:bundle compatibleWithTraitCollection:nil];
    [self.playButton setSelected:NO];
    [self.playButton setImage:imagePlay forState:UIControlStateNormal];
    [self.playButton setImage:imagePause forState:UIControlStateSelected];
    [self.playButton addTarget:self action:@selector(togglePlay) forControlEvents:UIControlEventTouchUpInside];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
//  self.avPlayer = [AVPlayer playerWithURL:[NSURL URLWithString:message.media[@"url"]]];
    self.avPlayer = [[AVPlayer alloc] initWithURL: [NSURL URLWithString:content.mediaUrl]];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    self.playerLayer.frame = self.avPlayerContainerView.bounds;
    self.playerLayer.needsDisplayOnBoundsChange = YES;
    for (AVPlayerLayer *layer in self.avPlayerContainerView.layer.sublayers) {
        [layer removeFromSuperlayer];
    }
    for (AVPlayerLayer *layer in self.cellImageView.layer.sublayers) {
        [layer removeFromSuperlayer];
    }
    
    [self.avPlayerContainerView.layer addSublayer:self.playerLayer];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePlayControls:)];
    [self.avPlayerControlsView addGestureRecognizer:tapGesture];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loopVideo) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
    
    if (self.isVideoMuted) {
        [_avPlayer setMuted:YES];
        [self.volume setTitle:@"🔇" forState:UIControlStateNormal];
    } else {
        [_avPlayer setMuted:NO];
        [self.volume setTitle:@"🔈" forState:UIControlStateNormal];
    }
    
    [self layoutSubviews];
    [self layoutIfNeeded];
}

- (void)setupInboxMessageActions: (CleverTapInboxMessageContent *)content {
    
    _actionView.hidden = NO;
    if (content.links && content.links.count > 0) {
        _actionView.firstButton.hidden = YES;
        _actionView.secondButton.hidden = YES;
        _actionView.thirdButton.hidden = YES;
        
        if (content.links.count == 1) {
            
            [[NSLayoutConstraint constraintWithItem:self.actionView.firstButton
                                          attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                             toItem:self attribute:NSLayoutAttributeWidth
                                         multiplier:1.0 constant:0] setActive:YES];
            
            _actionView.firstButton = [_actionView setupViewForButton:_actionView.firstButton forText:content.links[0] withIndex:0];

        } else if (content.links.count == 2) {
            
            [[NSLayoutConstraint constraintWithItem:self.actionView.firstButton
                                          attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                             toItem:self attribute:NSLayoutAttributeWidth
                                         multiplier:0.5 constant:0] setActive:YES];
            _actionView.firstButton = [_actionView setupViewForButton:_actionView.firstButton forText:content.links[0] withIndex:0];
            _actionView.secondButton = [_actionView setupViewForButton:_actionView.secondButton forText:content.links[1] withIndex:1];
            
        } else if (content.links.count > 2) {
          
            [[NSLayoutConstraint constraintWithItem:self.actionView.firstButton
                                          attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                             toItem:self attribute:NSLayoutAttributeWidth
                                         multiplier:0.33 constant:0] setActive:YES];
            _actionView.firstButton = [_actionView setupViewForButton:_actionView.firstButton forText:content.links[0] withIndex:0];
            _actionView.thirdButton = [_actionView setupViewForButton:_actionView.thirdButton forText:content.links[1] withIndex:1];
            _actionView.secondButton = [_actionView setupViewForButton:_actionView.secondButton forText:content.links[2] withIndex:2];
        }
    }
}

#pragma mark - Player Controls

- (IBAction)volumeButtonTapped:(UIButton *)sender {
    if ([self isMuted]) {
        [self.avPlayer setMuted:NO];
        self.isVideoMuted = NO;
        [sender setTitle:@"🔈" forState:UIControlStateNormal];
    } else {
        [self.avPlayer setMuted:YES];
        self.isVideoMuted = YES;
        [sender setTitle:@"🔇" forState:UIControlStateNormal];
    }
}

- (BOOL)isMuted{
    return self.avPlayer.muted;
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

#pragma mark Delegate

- (void)handleInboxNotificationFromIndex:(UIButton *)sender {
    
    NSInteger index = sender.tag;
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:[NSNumber numberWithInt:(int)index] forKey:@"index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:CLTAP_INBOX_MESSAGE_TAPPED_NOTIFICATION object:self.message userInfo:userInfo];
}


@end

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
    [self.cellImageView sd_cancelCurrentAnimationImagesLoad];
}

- (void)setupSimpleMessage:(CTInboxNotificationContentItem *)message {
    
    self.actionView.hidden = YES;
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

    self.cellImageView.hidden = YES;
    self.avPlayerContainerView.hidden = NO;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    self.avPlayer = [AVPlayer playerWithURL:[NSURL URLWithString:message.media[@"url"]]];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    _playerLayer.contentsGravity = AVLayerVideoGravityResizeAspect;
    self.avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    _playerLayer.frame = self.avPlayerContainerView.bounds;
    _playerLayer.needsDisplayOnBoundsChange = YES;
    for (AVPlayerLayer *layer in self.avPlayerContainerView.layer.sublayers) {
        [layer removeFromSuperlayer];
    }
    [self.avPlayerContainerView.layer addSublayer:_playerLayer];
}

@end

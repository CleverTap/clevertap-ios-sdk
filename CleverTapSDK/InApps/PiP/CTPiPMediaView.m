#import "CTPiPMediaView.h"
#import <AVFoundation/AVFoundation.h>
#import <SDWebImage/SDAnimatedImageView.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDAnimatedImage.h>

@interface CTPiPMediaView ()
@property (nonatomic, strong) CTPiPMediaModel *media;

// Image / GIF
@property (nonatomic, strong) SDAnimatedImageView *imageView;

// Video
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UIImageView *posterImageView;
@property (nonatomic, strong) id playerEndObserver;

@property (nonatomic, readwrite) BOOL isMuted;
@end

@implementation CTPiPMediaView

- (instancetype)initWithMedia:(CTPiPMediaModel *)media {
    self = [super init];
    if (self) {
        _media = media;
        _isMuted = YES;
        self.clipsToBounds = YES;
        self.backgroundColor = UIColor.blackColor;
    }
    return self;
}

- (void)loadMedia {
    switch (self.media.contentType) {
        case CTPiPContentTypeImage:
            [self setupImageView];
            [self loadImage];
            break;
        case CTPiPContentTypeGif:
            [self setupImageView];
            [self loadGIF];
            break;
        case CTPiPContentTypeVideo:
            [self setupVideoPlayer];
            break;
        default:
            [self setupImageView];
            [self loadFallbackImage];
            break;
    }
}

// MARK: - Image / GIF

- (void)setupImageView {
    SDAnimatedImageView *iv = [[SDAnimatedImageView alloc] init];
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.clipsToBounds = YES;
    iv.translatesAutoresizingMaskIntoConstraints = NO;
    iv.accessibilityLabel = self.media.altText;
    [self addSubview:iv];
    [NSLayoutConstraint activateConstraints:@[
        [iv.topAnchor constraintEqualToAnchor:self.topAnchor],
        [iv.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [iv.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [iv.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    ]];
    self.imageView = iv;
}

- (void)loadImage {
    if (self.preloadedImage) {
        self.imageView.image = self.preloadedImage;
        return;
    }
    if (self.preloadedImageData) {
        self.imageView.image = [UIImage imageWithData:self.preloadedImageData];
        return;
    }
    // Load via SDWebImage
    [self.imageView sd_setImageWithURL:self.media.url
                      placeholderImage:nil
                               options:SDWebImageRetryFailed
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (error) {
            [self loadFallbackImage];
        }
    }];
}

- (void)loadGIF {
    if (self.preloadedImageData) {
        SDAnimatedImage *gif = [SDAnimatedImage imageWithData:self.preloadedImageData];
        if (gif) {
            self.imageView.image = gif;
            return;
        }
        // GIF decode failed — show first frame
        UIImage *fallback = [UIImage imageWithData:self.preloadedImageData];
        self.imageView.image = fallback;
        return;
    }
    // Load via SDWebImage
    [self.imageView sd_setImageWithURL:self.media.url
                      placeholderImage:nil
                               options:SDWebImageRetryFailed
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (error) {
            [self loadFallbackImage];
        }
    }];
}

- (void)loadFallbackImage {
    if (!self.media.fallbackURL) return;
    if (self.imageView) {
        [self.imageView sd_setImageWithURL:self.media.fallbackURL];
    }
}

// MARK: - Video

- (void)setupVideoPlayer {
    // Poster image (shown while video loads)
    UIImageView *poster = [[UIImageView alloc] init];
    poster.contentMode = UIViewContentModeScaleAspectFit;
    poster.clipsToBounds = YES;
    poster.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:poster];
    [NSLayoutConstraint activateConstraints:@[
        [poster.topAnchor constraintEqualToAnchor:self.topAnchor],
        [poster.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [poster.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [poster.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
    ]];
    self.posterImageView = poster;

    if (self.media.posterURL) {
        [poster sd_setImageWithURL:self.media.posterURL];
    }

    // Configure audio session to avoid interrupting host app
    NSError *audioError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&audioError];

    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:self.media.url];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
    player.muted = YES;
    self.isMuted = YES;
    self.player = player;

    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:player];
    layer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.layer insertSublayer:layer above:poster.layer];
    self.playerLayer = layer;

    // Loop video
    __weak typeof(self) weakSelf = self;
    self.playerEndObserver = [[NSNotificationCenter defaultCenter]
        addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                    object:item
                     queue:NSOperationQueue.mainQueue
                usingBlock:^(NSNotification *note) {
        [weakSelf.player seekToTime:kCMTimeZero];
        [weakSelf.player play];
    }];

    [player play];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
}

// MARK: - Controls

- (void)play {
    [self.player play];
}

- (void)pause {
    [self.player pause];
}

- (void)toggleMute {
    self.isMuted = !self.isMuted;
    self.player.muted = self.isMuted;
}

// MARK: - Content fit mode

- (void)setContentFitMode:(BOOL)fit {
    UIViewContentMode mode = fit ? UIViewContentModeScaleAspectFit : UIViewContentModeScaleAspectFill;
    if (self.imageView) {
        self.imageView.contentMode = mode;
    }
    if (self.playerLayer) {
        self.playerLayer.videoGravity = fit ? AVLayerVideoGravityResizeAspect : AVLayerVideoGravityResizeAspectFill;
    }
    if (self.posterImageView) {
        self.posterImageView.contentMode = mode;
    }
}

// MARK: - Release

- (void)releaseMedia {
    [self.player pause];
    if (self.playerEndObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.playerEndObserver];
        self.playerEndObserver = nil;
    }
    self.player = nil;
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
}

- (void)dealloc {
    [self releaseMedia];
}

@end

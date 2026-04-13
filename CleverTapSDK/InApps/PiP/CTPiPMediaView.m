#import "CTPiPMediaView.h"
#import "CTConstants.h"
#import <AVFoundation/AVFoundation.h>
#import <SDWebImage/SDAnimatedImageView.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDAnimatedImage.h>

@interface CTPiPMediaView ()
@property (nonatomic, strong) CTPiPMediaModel *media;
@property (nonatomic, readwrite) CTPiPContentType contentType;

// Image / GIF
@property (nonatomic, strong) SDAnimatedImageView *imageView;

// Video
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) UIImageView *posterImageView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) id playerEndObserver;
@property (nonatomic, strong) id playerFailObserver;
@property (nonatomic, assign) BOOL playerItemStatusObserved;
@property (nonatomic, assign) BOOL hasSignaledReady;

@property (nonatomic, readwrite) BOOL isMuted;
@end

@implementation CTPiPMediaView

- (instancetype)initWithMedia:(CTPiPMediaModel *)media {
    self = [super init];
    if (self) {
        _media = media;
        _contentType = media.contentType;
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
            // Image loads in background — signal ready immediately so PiP animates in.
            [self notifyReadyToShow];
            break;
        case CTPiPContentTypeGif:
            [self setupImageView];
            [self loadGIF];
            [self notifyReadyToShow];
            break;
        case CTPiPContentTypeVideo:
            // Video: do NOT signal ready yet. Wait for AVPlayerItemStatusReadyToPlay
            // (or failure) so the window stays hidden until we know the video works.
            [self setupVideoPlayer];
            break;
        default:
            [self setupImageView];
            [self loadFallbackImage];
            [self notifyReadyToShow];
            break;
    }
}

- (void)notifyReadyToShow {
    if (self.hasSignaledReady) return;
    self.hasSignaledReady = YES;
    if ([self.delegate respondsToSelector:@selector(pipMediaIsReadyToShow)]) {
        [self.delegate pipMediaIsReadyToShow];
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

    // Spinner shown during initial load and while the buffer is empty.
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                                        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    spinner.hidesWhenStopped = YES;
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:spinner];
    [NSLayoutConstraint activateConstraints:@[
        [spinner.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [spinner.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
    ]];
    [spinner startAnimating];
    self.spinner = spinner;

    NSError *audioError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&audioError];

    AVPlayer *player = [AVPlayer new];
    player.muted = YES;
    self.isMuted = YES;
    self.player = player;

    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:player];
    layer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.layer insertSublayer:layer above:poster.layer];
    self.playerLayer = layer;

    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:self.media.url];
    self.playerItem = item;

    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:NULL];
    self.playerItemStatusObserved = YES;

    __weak typeof(self) weakSelf = self;

    // Loop video on successful completion
    self.playerEndObserver = [[NSNotificationCenter defaultCenter]
        addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                    object:item
                     queue:NSOperationQueue.mainQueue
                usingBlock:^(NSNotification *note) {
        [weakSelf.player seekToTime:kCMTimeZero];
        [weakSelf.player play];
    }];

    // Mid-stream failure (e.g. internet drops while playing) — show spinner.
    self.playerFailObserver = [[NSNotificationCenter defaultCenter]
        addObserverForName:AVPlayerItemFailedToPlayToEndTimeNotification
                    object:item
                     queue:NSOperationQueue.mainQueue
                usingBlock:^(NSNotification *note) {
        NSError *err = note.userInfo[AVPlayerItemFailedToPlayToEndTimeErrorKey];
        CleverTapLogStaticDebug(@"%@: PiP AVPlayerItem mid-stream failure — %@ %ld",
                                self, err.domain, (long)err.code);
        [weakSelf.spinner startAnimating];
    }];

    [player replaceCurrentItemWithPlayerItem:item];
    [player play];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if (object != self.playerItem) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }

    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = (AVPlayerItemStatus)[change[NSKeyValueChangeNewKey] integerValue];
        if (status == AVPlayerItemStatusReadyToPlay) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.spinner stopAnimating];
                [self notifyReadyToShow];
                [self.player play];
            });
        } else if (status == AVPlayerItemStatusFailed) {
            NSError *error = self.playerItem.error;
            CleverTapLogStaticDebug(@"%@: PiP AVPlayerItem failed — %@ %ld: %@",
                                    self, error.domain, (long)error.code, error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.spinner stopAnimating];
                [self showVideoFallback];
            });
        }
    }
}

- (void)showVideoFallback {
    if (!self.media.fallbackURL) {
        // No fallback available — nothing to show, dismiss PiP.
        if ([self.delegate respondsToSelector:@selector(pipMediaDidFailToLoad)]) {
            [self.delegate pipMediaDidFailToLoad];
        }
        return;
    }
    self.playerLayer.hidden = YES;
    __weak typeof(self) weakSelf = self;
    [self.posterImageView sd_setImageWithURL:self.media.fallbackURL
                            placeholderImage:nil
                                     options:SDWebImageRetryFailed
                                   completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *url) {
        if (error || !image) {
            // Fallback image also failed — dismiss PiP.
            if ([weakSelf.delegate respondsToSelector:@selector(pipMediaDidFailToLoad)]) {
                [weakSelf.delegate pipMediaDidFailToLoad];
            }
            return;
        }
        if ([weakSelf.delegate respondsToSelector:@selector(pipMediaDidShowVideoFallback)]) {
            [weakSelf.delegate pipMediaDidShowVideoFallback];
        }
        [weakSelf notifyReadyToShow];
    }];
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
    if (self.playerItemStatusObserved) {
        [self.playerItem removeObserver:self forKeyPath:@"status"];
        self.playerItemStatusObserved = NO;
    }
    if (self.playerEndObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.playerEndObserver];
        self.playerEndObserver = nil;
    }
    if (self.playerFailObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.playerFailObserver];
        self.playerFailObserver = nil;
    }
    self.playerItem = nil;
    self.player = nil;
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
}

- (void)dealloc {
    [self releaseMedia];
}

@end

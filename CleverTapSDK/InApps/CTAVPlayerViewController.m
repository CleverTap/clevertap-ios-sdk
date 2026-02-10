
#import "CTAVPlayerViewController.h"
#import "CTInAppNotification.h"
#import "CTUIUtils.h"

@interface CTAVPlayerViewController () 

@property (nonatomic, strong) CTInAppNotification *notification;
@property (nonatomic, strong) UIImageView *imageView;


@end

@implementation CTAVPlayerViewController

- (instancetype)initWithNotification:(CTInAppNotification *)notification {
    return [self initWithNotification:notification muted:NO autoplay:NO];
}

- (instancetype)initWithNotification:(CTInAppNotification *)notification muted:(BOOL)muted autoplay:(BOOL)autoplay {
    self = [super init];
    if (self) {
        _notification = notification;
        _muted = muted;
        _autoplay = autoplay;
        _loopVideo = YES; // Default to looping
        AVPlayerItem *avPlayerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.notification.mediaUrl]];
        self.player = [AVPlayer playerWithPlayerItem:avPlayerItem];
        self.player.muted = muted;

        // Setup looping notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:avPlayerItem];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Configure audio session to mix with other audio when muted
    if (self.muted) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                         withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                               error:nil];
    } else {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }

    // Hide playback controls for autoplay videos
    self.showsPlaybackControls = !self.autoplay;
    self.view.backgroundColor = [UIColor clearColor];
    self.view.translatesAutoresizingMaskIntoConstraints = NO;

    if (self.notification.mediaIsAudio) {
        UIImage *image = [CTUIUtils getImageForName:@"ct_default_audio.png"];
        self.imageView = [[UIImageView alloc] initWithFrame: self.view.bounds];
        self.imageView.backgroundColor = [UIColor blackColor];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.image = image;
        [self.contentOverlayView addSubview:self.imageView];
    }

    // Autoplay if configured
    if (self.autoplay) {
        [self.player play];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self adjustAudioDefaultImage];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
        [self adjustAudioDefaultImage];
    } completion:nil];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)adjustAudioDefaultImage {
    if (self.notification.mediaIsAudio) {
        if (!CGRectIsEmpty(self.contentOverlayView.frame)) {
            self.imageView.frame = self.contentOverlayView.bounds;
        } else {
            self.imageView.frame = self.view.bounds;
        }
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    if (self.loopVideo) {
        AVPlayerItem *playerItem = [notification object];
        [playerItem seekToTime:kCMTimeZero completionHandler:nil];
        if (self.autoplay) {
            [self.player play];
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end


#import "CTAVPlayerViewController.h"
#import "CTInAppNotification.h"
#import "CTUIUtils.h"

@interface CTAVPlayerViewController () 

@property (nonatomic, strong) CTInAppNotification *notification;
@property (nonatomic, strong) UIImageView *imageView;


@end

@implementation CTAVPlayerViewController

- (instancetype)initWithNotification:(CTInAppNotification *)notification {
    self = [super init];
    if (self) {
        _notification = notification;
        AVPlayerItem *avPlayerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.notification.mediaUrl]];
        self.player = [AVPlayer playerWithPlayerItem:avPlayerItem];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    self.showsPlaybackControls = YES;
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


@end

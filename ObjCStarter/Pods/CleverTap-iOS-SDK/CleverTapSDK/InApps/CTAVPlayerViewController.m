#import "CTAVPlayerViewController.h"
#import "CTInAppNotification.h"
#import "CTInAppResources.h"

@interface CTAVPlayerViewController () <CTAVPlayerControlsDelegate>

@property (nonatomic, strong) CTAVPlayerControlsViewController *controlsViewVC;
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

- (void)dealloc {
    [self.controlsViewVC removeFromParentViewController];
    self.controlsViewVC = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    self.showsPlaybackControls = NO;
    self.view.backgroundColor = [UIColor clearColor];
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.controlsViewVC = [[CTAVPlayerControlsViewController alloc] initWithPlayer:self.player andConfig:@{@"fullscreen":@(!self.notification.mediaIsAudio)}];
    [self addChildViewController:self.controlsViewVC];
    [self.view addSubview:self.controlsViewVC.view];
    [self.controlsViewVC didMoveToParentViewController:self];
    self.controlsViewVC.delegate = self;
    self.controlsViewVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    [[NSLayoutConstraint constraintWithItem:self.controlsViewVC.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual
                                     toItem:self.view attribute:NSLayoutAttributeWidth
                                 multiplier:1 constant:0] setActive:YES];
    
    [[NSLayoutConstraint constraintWithItem:self.controlsViewVC.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual
                                     toItem:self.view attribute:NSLayoutAttributeHeight
                                 multiplier:1 constant:0] setActive:YES];
    
    [[NSLayoutConstraint constraintWithItem:self.controlsViewVC.view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual
                                     toItem:self.view attribute:NSLayoutAttributeLeading
                                 multiplier:1 constant:0] setActive:YES];
    
    [[NSLayoutConstraint constraintWithItem:self.controlsViewVC.view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual
                                     toItem:self.view attribute:NSLayoutAttributeTrailing
                                 multiplier:1 constant:0] setActive:YES];
    
    [[NSLayoutConstraint constraintWithItem:self.controlsViewVC.view attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
                                     toItem:self.view attribute:NSLayoutAttributeCenterY
                                 multiplier:1 constant:0] setActive:YES];

    if (self.notification.mediaIsAudio) {

        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        UIImage *image = [UIImage imageNamed:@"sound-wave-headphones.png" inBundle:bundle compatibleWithTraitCollection:nil];
        self.imageView = [[UIImageView alloc] initWithFrame: self.controlsViewVC.view.frame];
        self.imageView.backgroundColor = [UIColor blackColor];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.image = image;
        [self.contentOverlayView addSubview:self.imageView];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.controlsViewVC.view.frame = self.view.bounds;
    self.imageView.frame = self.controlsViewVC.view.bounds;
    [self.view bringSubviewToFront:self.controlsViewVC.view];
}

#pragma mark - Delegates

- (void)toggleFullscreen {
    if (self.playerDelegate && [self.playerDelegate respondsToSelector:@selector(toggleFullscreen)]) {
        [self.playerDelegate toggleFullscreen];
    }
}

@end

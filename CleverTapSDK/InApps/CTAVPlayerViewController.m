
#import "CTAVPlayerViewController.h"
#import "CTInAppNotification.h"
#import "CTInAppResources.h"

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
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        UIImage *image = [UIImage imageNamed:@"sound-wave-headphones.png" inBundle:bundle compatibleWithTraitCollection:nil];
        self.imageView = [[UIImageView alloc] initWithFrame: self.view.bounds];
        self.imageView.backgroundColor = [UIColor blackColor];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.image = image;
        [self.contentOverlayView addSubview:self.imageView];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

@end

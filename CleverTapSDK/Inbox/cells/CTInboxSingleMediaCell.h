#import <UIKit/UIKit.h>
#import "CTAVPlayerViewController.h"
#import "FLAnimatedImage.h"

NS_ASSUME_NONNULL_BEGIN

@class FLAnimatedImageView;

@interface CTInboxSingleMediaCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutlet FLAnimatedImageView *cellImageView;
@property (nonatomic, strong) IBOutlet UIView *avPlayerContainerView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *bodyLabel;

@property (strong, nonatomic) AVPlayer *avPlayer;



@property (nonatomic, assign) CGRect cachedAVPlayerFrame;
@property (nonatomic, assign) UIInterfaceOrientation originalOrientation;
@property (nonatomic, strong) UIWindow *avPlayerWindow;
@property (nonatomic, weak) UIWindow *mainWindow;
@property (nonatomic, assign) BOOL avPlayerIsFullScreen;

@end

NS_ASSUME_NONNULL_END

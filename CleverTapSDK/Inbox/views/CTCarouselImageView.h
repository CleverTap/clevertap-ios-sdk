
#import <UIKit/UIKit.h>

@interface CTCarouselImageView : UIView

@property(nonatomic, strong, nullable, readonly) NSString *actionUrl;
@property (strong, nonatomic) IBOutlet UIImageView * _Nullable cellImageView;
@property (strong, nonatomic) IBOutlet UILabel * _Nullable titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *_Nullable bodyLabel;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint * _Nullable imageViewLandRatioConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint * _Nullable imageViewPortRatioConstraint;

+ (CGFloat)captionHeight;

- (instancetype _Nonnull)initWithFrame:(CGRect)frame
                               caption:(NSString * _Nullable)caption
                            subcaption:(NSString * _Nullable)subcaption
                          captionColor:(NSString * _Nullable)captionColor
                       subcaptionColor:(NSString * _Nullable)subcaptionColor
                              imageUrl:(NSString * _Nonnull)imageUrl
                             actionUrl:(NSString * _Nullable)actionUrl
                   orientationPortrait:(BOOL)orientationPortrait;

- (instancetype _Nonnull)initWithFrame:(CGRect)frame
                              imageUrl:(NSString * _Nonnull)imageUrl
                             actionUrl:(NSString * _Nullable)actionUrl
                   orientationPortrait:(BOOL)orientationPortrait;

@end

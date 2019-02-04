
#import <UIKit/UIKit.h>

@interface CTCarouselImageView : UIView

@property(nonatomic, strong, nullable, readonly) NSString *actionUrl;

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

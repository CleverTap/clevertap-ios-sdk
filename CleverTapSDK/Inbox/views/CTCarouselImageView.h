
#import <UIKit/UIKit.h>

@interface CTCarouselImageView : UIView

@property(nonatomic, strong, nullable, readonly) NSString *actionUrl;

+ (CGFloat)captionHeight;

- (instancetype _Nonnull)initWithFrame:(CGRect)frame
                               caption:(NSString * _Nullable)caption
                            subcaption:(NSString * _Nullable)subcaption
                              imageUrl:(NSString * _Nonnull)imageUrl
                             actionUrl:(NSString * _Nullable)actionUrl;

- (instancetype _Nonnull)initWithFrame:(CGRect)frame
                              imageUrl:(NSString * _Nonnull)imageUrl
                             actionUrl:(NSString * _Nullable)actionUrl;

@end

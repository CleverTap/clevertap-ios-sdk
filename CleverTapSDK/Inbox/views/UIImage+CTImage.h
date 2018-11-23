
#import <UIKit/UIKit.h>

@interface UIImage (CTImage)

+ (instancetype _Nonnull)ct_imageWithString:(NSString * _Nonnull)str
                                      color:(UIColor * _Nullable)color
                                       size:(CGSize)size; // if color is nil creates a random color


@end

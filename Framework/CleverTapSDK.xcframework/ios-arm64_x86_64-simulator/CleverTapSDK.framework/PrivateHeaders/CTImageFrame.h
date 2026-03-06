/*
 * CTImageFrame
 * Ported from SDWebImage's SDImageFrame.
 * Represents a single frame of an animated image.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTImageFrame : NSObject

@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, readonly) NSTimeInterval duration;

- (instancetype)initWithImage:(UIImage *)image duration:(NSTimeInterval)duration;
+ (instancetype)frameWithImage:(UIImage *)image duration:(NSTimeInterval)duration;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

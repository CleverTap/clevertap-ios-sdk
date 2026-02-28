/*
 * CTAnimatedImage
 * Ported from SDWebImage's SDAnimatedImage.
 * A UIImage subclass that supports animated GIF rendering via CTAnimatedImageView.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Protocol for objects that provide animated image frame access.
/// Equivalent to SDAnimatedImageProvider.
@protocol CTAnimatedImageProviding <NSObject>
@property (nonatomic, readonly) NSUInteger animatedImageFrameCount;
@property (nonatomic, readonly) NSUInteger animatedImageLoopCount;
- (nullable UIImage *)animatedImageFrameAtIndex:(NSUInteger)index;
- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index;
@end

/**
 * Drop-in replacement for SDAnimatedImage.
 * Decodes GIF data using CTGIFDecoder (ImageIO).
 * Returns nil from +imageWithData: if the data is not a valid animated GIF.
 */
NS_SWIFT_NONISOLATED
@interface CTAnimatedImage : UIImage <CTAnimatedImageProviding>

+ (nullable instancetype)imageWithData:(nonnull NSData *)data;
- (nullable instancetype)initWithData:(nonnull NSData *)data;

@property (nonatomic, readonly) NSUInteger animatedImageFrameCount;
@property (nonatomic, readonly) NSUInteger animatedImageLoopCount;
- (nullable UIImage *)animatedImageFrameAtIndex:(NSUInteger)index;
- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END

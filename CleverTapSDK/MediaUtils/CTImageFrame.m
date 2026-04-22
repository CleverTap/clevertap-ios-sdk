/*
 * CTImageFrame
 * Ported from SDWebImage's SDImageFrame.
 */

#import "CTImageFrame.h"

@interface CTImageFrame ()

@property (nonatomic, strong, readwrite) UIImage *image;
@property (nonatomic, readwrite) NSTimeInterval duration;

@end

@implementation CTImageFrame

- (instancetype)initWithImage:(UIImage *)image duration:(NSTimeInterval)duration {
    self = [super init];
    if (self) {
        _image = image;
        _duration = duration;
    }
    return self;
}

+ (instancetype)frameWithImage:(UIImage *)image duration:(NSTimeInterval)duration {
    return [[CTImageFrame alloc] initWithImage:image duration:duration];
}

@end

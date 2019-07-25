#import "CTSlider.h"

static const float kSliderHeight = 6.0;

@implementation CTSlider

- (CGRect)trackRectForBounds:(CGRect)bounds {
    CGRect rect = CGRectMake(bounds.origin.x, bounds.size.height/2 - 3, bounds.size.width, kSliderHeight);
    return rect;
}

@end

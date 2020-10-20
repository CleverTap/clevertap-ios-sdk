#import "CTValueTransformers.h"

@implementation CTNSStringFromUIColorValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if ([value isKindOfClass:[UIColor class]]) {
        UIColor *color = (UIColor *)value;
        CGColorSpaceModel spaceModel = CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor));
        if (spaceModel == kCGColorSpaceModelMonochrome || spaceModel == kCGColorSpaceModelRGB) {
            size_t numberOfComponents = CGColorGetNumberOfComponents(color.CGColor);
            const CGFloat *components = CGColorGetComponents(color.CGColor);
            if (spaceModel == kCGColorSpaceModelMonochrome && numberOfComponents >= 1) {
                CGFloat w = (255 * components[0]);
                CGFloat a = (numberOfComponents > 1 ? components[1] : 1.0f);
                return [NSString stringWithFormat:@"rgba(%.0f, %.0f, %.0f, %.2f)", w, w, w, a];
            } else if (spaceModel == kCGColorSpaceModelRGB && numberOfComponents >= 3) {
                CGFloat r = (255 * components[0]);
                CGFloat g = (255 * components[1]);
                CGFloat b = (255 * components[2]);
                CGFloat a = (numberOfComponents > 3 ? components[3] : 1.0f);
                return [NSString stringWithFormat:@"rgba(%.0f, %.0f, %.0f, %.2f)", r, g, b, a];
            }
        }
    }
    return nil;
}

- (id)reverseTransformedValue:(id)value {
    if ([value isKindOfClass:[NSString class]]) {
        NSString *colorAsString = (NSString *)value;
        NSScanner *scanner = [NSScanner scannerWithString:colorAsString];
        [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"rgba(), "]];
        [scanner setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        int r = 0, g = 0, b = 0;
        float a = 1.0f;
        if ([scanner scanInt:&r] &&
            [scanner scanInt:&g] &&
            [scanner scanInt:&b] &&
            [scanner scanFloat:&a])
        {
            UIColor *color = [[UIColor alloc] initWithRed:(r/255.0f) green:(g/255.0f) blue:(b/255.0f) alpha:a];
            return color;
        }
    }
    return nil;
}

@end

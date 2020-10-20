#import "CTValueTransformers.h"

@implementation CTNSStringFromCGColorRefValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

- (id)transformedValue:(id)value {
    if (value && CFGetTypeID((__bridge CFTypeRef)value) == CGColorGetTypeID()) {
        NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:@"CTNSStringFromUIColorValueTransformer"];
        return [transformer transformedValue:[[UIColor alloc] initWithCGColor:(__bridge CGColorRef)value]];
    }
    return nil;
}

- (id)reverseTransformedValue:(id)value {
    NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:@"CTNSStringFromUIColorValueTransformer"];
    UIColor *color =  [transformer reverseTransformedValue:value];
    return CFBridgingRelease(CGColorCreateCopy([color CGColor]));
}

@end


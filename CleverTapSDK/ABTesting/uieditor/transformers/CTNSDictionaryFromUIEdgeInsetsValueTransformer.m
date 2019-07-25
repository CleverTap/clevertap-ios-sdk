#import "CTValueTransformers.h"

@implementation CTNSDictionaryFromUIEdgeInsetsValueTransformer

+ (Class)transformedValueClass {
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value{
    if ([value respondsToSelector:@selector(UIEdgeInsetsValue)]) {
        UIEdgeInsets edgeInsets = [value UIEdgeInsetsValue];
        return @{
                 @"top"    : @(edgeInsets.top),
                 @"bottom" : @(edgeInsets.bottom),
                 @"left"   : @(edgeInsets.left),
                 @"right"  : @(edgeInsets.right)
                 };
    }
    return nil;
}

- (id)reverseTransformedValue:(id)value {
    if ([value isKindOfClass:[NSDictionary class]]) {
        id top = value[@"top"];
        id bottom = value[@"bottom"];
        id left = value[@"left"];
        id right = value[@"right"];
        if (top && bottom && left && right) {
            UIEdgeInsets edgeInsets = UIEdgeInsetsMake([top floatValue], [left floatValue], [bottom floatValue], [right floatValue]);
            return [NSValue valueWithUIEdgeInsets:edgeInsets];
        }
    }
    return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsZero];
}

@end


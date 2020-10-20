#import <UIKit/UIKit.h>

@interface CTPassThroughValueTransformer : NSValueTransformer

@end

@interface CTNSStringFromCGColorRefValueTransformer : NSValueTransformer

@end

@interface CTNSStringFromUIColorValueTransformer : NSValueTransformer

@end

@interface CTNSDictionaryFromCATransform3DValueTransformer : NSValueTransformer

@end

@interface CTNSDictionaryFromCGAffineTransformValueTransformer : NSValueTransformer

@end

@interface CTNSDictionaryFromCGPointValueTransformer : NSValueTransformer

@end

@interface CTNSDictionaryFromCGRectValueTransformer : NSValueTransformer

@end

@interface CTNSDictionaryFromCGSizeValueTransformer : NSValueTransformer

@end

@interface CTNSDictionaryFromNSAttributedStringValueTransformer : NSValueTransformer

@end

@interface CTNSDictionaryFromUIEdgeInsetsValueTransformer : NSValueTransformer

@end

@interface CTNSDictionaryFromUIFontValueTransformer : NSValueTransformer

@end

@interface CTNSDictionaryFromUIImageValueTransformer : NSValueTransformer

+ (UIImage *)imageFromDictionary: (NSDictionary *)imagesDictionary;

@end

@interface CTCGFloatFromNSNumberValueTransformer : NSValueTransformer

@end

@interface CTNSNumberFromBOOLValueTransformer : NSValueTransformer

@end

__unused static id transformValue(id inputValue, NSString *toTypeName){
    
    if (!inputValue) return nil;
    
    if ([inputValue isKindOfClass:[NSClassFromString(toTypeName) class]]) {
        return [[NSValueTransformer valueTransformerForName:@"CTPassThroughValueTransformer"] transformedValue:inputValue];
    }
    
    NSString *fromTypeName = nil;
    NSArray *validClasses = @[[NSString class], [NSNumber class], [NSDictionary class], [NSArray class], [NSNull class]];
    for (Class c in validClasses) {
        if ([inputValue isKindOfClass:c]) {
            fromTypeName = NSStringFromClass(c);
            break;
        }
    }
    
    if (!fromTypeName) return nil;
    
    NSValueTransformer *transformer = nil;
    NSString *forwardTransformer = [NSString stringWithFormat:@"CT%@From%@ValueTransformer", toTypeName, fromTypeName];
    transformer = [NSValueTransformer valueTransformerForName:forwardTransformer];
    if (transformer) {
        return [transformer transformedValue:inputValue];
    }
    
    NSString *reverseTransformer = [NSString stringWithFormat:@"CT%@From%@ValueTransformer", fromTypeName, toTypeName];
    transformer = [NSValueTransformer valueTransformerForName:reverseTransformer];
    if (transformer && [[transformer class] allowsReverseTransformation]) {
        return [transformer reverseTransformedValue:inputValue];
    }
    
    return [[NSValueTransformer valueTransformerForName:@"CTPassThroughValueTransformer"] transformedValue:inputValue];
}



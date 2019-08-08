#import "CTValueTransformers.h"

@implementation CTNSDictionaryFromUIFontValueTransformer

+ (Class)transformedValueClass {
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if ([value isKindOfClass:[UIFont class]]) {
        UIFont *font = value;
        return @{
                 @"familyName": font.familyName,
                 @"fontName": font.fontName,
                 @"pointSize": @(font.pointSize),
                 };
    }
    return nil;
}

- (id)reverseTransformedValue:(id)value {
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSNumber *pointSize;
        if (![value[@"pointSize"] isKindOfClass:[NSNull class]]) {
            pointSize = value[@"pointSize"];
        } else {
            pointSize = [NSNumber numberWithInteger:1];
        }
        NSString *fontName = value[@"fontName"];
        float fontSize = [pointSize floatValue];
        
        if (fontSize > 0.0f && fontName) {
            UIFont *systemFont = [UIFont systemFontOfSize:fontSize];
            UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:fontSize];
            UIFont *italicSystemFont = [UIFont italicSystemFontOfSize:fontSize];
            if ([systemFont.fontName isEqualToString:fontName]) {
                return systemFont;
            } else if ([boldSystemFont.fontName isEqualToString:fontName]) {
                return boldSystemFont;
            } else if ([italicSystemFont.fontName isEqualToString:fontName]) {
                return italicSystemFont;
            } else {
                return [UIFont fontWithName:fontName size:fontSize];
            }
        }
    }
    return nil;
}

@end

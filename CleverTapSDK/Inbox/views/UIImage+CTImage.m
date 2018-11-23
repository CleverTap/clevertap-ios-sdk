
#import "UIImage+CTImage.h"

static const CGFloat kFontResizeFactor = 0.42f;

@implementation UIImage (CTImage)

+ (instancetype _Nonnull)ct_imageWithString:(NSString * _Nonnull)str color:(UIColor * _Nullable)color size:(CGSize)size {
    return (str != nil) ? [self _imageWithString:str color:color size:size] : [self _imageWithColor:color];
}

#pragma mark Private

+ (instancetype)_imageWithColor:(UIColor * _Nullable)color {
    UIColor *_color = color ? color : [self _randomColor];
    CGSize size = CGSizeMake(1,1);
    
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc]
                                         initWithSize:size
                                         format:[UIGraphicsImageRendererFormat defaultFormat]];
    
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        CGContextRef context = ctx.CGContext;
        CGRect rect = CGRectMake(0, 0, size.width, size.height);
        CGContextSetFillColorWithColor(context, _color.CGColor);
        CGContextFillRect(context, rect);
    }];
    
    return image;
}

+ (instancetype)_imageWithString:(NSString *)str color:(UIColor * _Nullable)color size:(CGSize)size {
    UIColor *_color = color ? color : [self _randomColor];
    
    CGFloat fontSize = size.width * kFontResizeFactor;
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    NSDictionary *textAttributes = @{
                                     NSFontAttributeName: font,
                                     NSForegroundColorAttributeName: [UIColor whiteColor]
                                     };
    
    NSString *displayText = [self _generateDisplayText:str];
    
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc]
                                         initWithSize:size
                                         format:[UIGraphicsImageRendererFormat defaultFormat]];
    
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        CGContextRef context = ctx.CGContext;
        CGRect rect = CGRectMake(0, 0, size.width, size.height);
        CGContextSetFillColorWithColor(context, _color.CGColor);
        CGContextFillRect(context, rect);
        
        CGSize textSize = [displayText sizeWithAttributes:textAttributes];
        
        [displayText drawInRect:CGRectMake(size.width/2 - textSize.width/2,
                                           size.height/2 - textSize.height/2,
                                           textSize.width,
                                           textSize.height)
                 withAttributes:textAttributes];
        
    }];
    
    return image;
    
}

+ (UIColor *)_randomColor {
    srand48(arc4random());
    
    float red = 0.0;
    while (red < 0.1 || red > 0.84) {
        red = drand48();
    }
    
    float green = 0.0;
    while (green < 0.1 || green > 0.84) {
        green = drand48();
    }
    
    float blue = 0.0;
    while (blue < 0.1 || blue > 0.84) {
        blue = drand48();
    }
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
}

+ (NSString *)_generateDisplayText:(NSString *)input {
    NSMutableString *output = [NSMutableString stringWithString:@""];
    NSMutableArray *components = [[input componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] mutableCopy];
    
    if ([components count]) {
        NSString *first = [components firstObject];
        if ([first length]) {
            NSRange firstLetterRange = [first rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, 1)];
            [output appendString:[first substringWithRange:firstLetterRange]];
        }
        
        if ([components count] >= 2) {
            NSString *last = [components lastObject];
            
            while ([last length] == 0 && [components count] >= 2) {
                [components removeLastObject];
                last = [components lastObject];
            }
            
            if ([components count] > 1) {
                NSRange lastLetterRange = [last rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, 1)];
                [output appendString:[last substringWithRange:lastLetterRange]];
            }
        }
    }
    
    return [output uppercaseString];
}

@end

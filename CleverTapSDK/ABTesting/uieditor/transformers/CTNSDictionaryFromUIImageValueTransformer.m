#import <ImageIO/ImageIO.h>
#import "CTValueTransformers.h"
#import "CTEditorImageCache.h"

@implementation CTNSDictionaryFromUIImageValueTransformer

+ (Class)transformedValueClass {
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

+ (UIImage *)imageFromDictionary:(NSDictionary *)imagesDictionary {
    NSArray *imagesArray = imagesDictionary[@"images"];
    if (!imagesArray || ![imagesArray isKindOfClass:[NSArray class]] || [imagesArray count] <= 0) {
        return nil;
    }
    
    UIImage *image = nil;
    
    // only static images for now
    NSDictionary *imageDictionary = imagesArray[0];
    
    NSNumber *scale = imageDictionary[@"scale"];
    if (scale <= 0) {
        scale = @(1);
    }
    if (imageDictionary[@"url"]) {
        CGSize size = CGSizeZero;
        NSString *url = imageDictionary[@"url"];
        NSDictionary *dimensions = imageDictionary[@"dimensions"];
        if (dimensions) {
            size = CGSizeMake([dimensions[@"Width"] floatValue], [dimensions[@"Height"] floatValue]);
        }
        image = [CTEditorImageCache getImage:url withScale:scale.floatValue andSize:size];
        if (!image) {
            return nil;
        }
    } else if (imageDictionary[@"data"] && imageDictionary[@"data"] != [NSNull null]) {
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:imageDictionary[@"data"]
                                                                options:NSDataBase64DecodingIgnoreUnknownCharacters];
        image = [UIImage imageWithData:imageData scale:fminf(1.0, scale.floatValue)];
    }
    
    if (image && imagesDictionary[@"capInsets"]) {
        NSValueTransformer *insetsTransformer = [NSValueTransformer valueTransformerForName:NSStringFromClass([CTNSDictionaryFromUIEdgeInsetsValueTransformer class])];
        UIEdgeInsets capInsets = [[insetsTransformer reverseTransformedValue:imagesDictionary[@"capInsets"]] UIEdgeInsetsValue];
        if (UIEdgeInsetsEqualToEdgeInsets(capInsets, UIEdgeInsetsZero) == NO) {
            if (imagesDictionary[@"resizingMode"]) {
                UIImageResizingMode resizingMode = (UIImageResizingMode)[imagesDictionary[@"resizingMode"] integerValue];
                image = [image resizableImageWithCapInsets:capInsets resizingMode:resizingMode];
            } else {
                image = [image resizableImageWithCapInsets:capInsets];
            }
        }
    }
    return image;
}

- (id)transformedValue:(id)value {
    NSDictionary *transformedValue = nil;
    
    if ([value isKindOfClass:[UIImage class]]) {
        UIImage *image = value;
        
        NSValueTransformer *sizeTransformer = [NSValueTransformer valueTransformerForName:NSStringFromClass([CTNSDictionaryFromCGSizeValueTransformer class])];
        NSValueTransformer *insetsTransformer = [NSValueTransformer valueTransformerForName:NSStringFromClass([CTNSDictionaryFromUIEdgeInsetsValueTransformer class])];
        
        NSValue *size = [NSValue valueWithCGSize:image.size];
        NSValue *capInsets = [NSValue valueWithUIEdgeInsets:image.capInsets];
        NSValue *alignmentRectInsets = [NSValue valueWithUIEdgeInsets:image.alignmentRectInsets];
        
        NSArray *images = image.images ?: @[ image ];
        
        NSMutableArray *imageDictionaries = [NSMutableArray array];
        for (UIImage *frame in images) {
            NSData *imageData = UIImagePNGRepresentation(frame);
            NSString *imageDataString = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            NSDictionary *imageDictionary = @{ @"scale": @(image.scale),
                                               @"mime_type": @"image/png",
                                               @"data": (imageData != nil ? imageDataString : [NSNull null]) };
            
            [imageDictionaries addObject:imageDictionary];
        }
        
        transformedValue = @{
                             @"imageOrientation": @(image.imageOrientation),
                             @"size": [sizeTransformer transformedValue:size],
                             @"renderingMode": @(image.renderingMode),
                             @"resizingMode": @(image.resizingMode),
                             @"duration": @(image.duration),
                             @"capInsets": [insetsTransformer transformedValue:capInsets],
                             @"alignmentRectInsets": [insetsTransformer transformedValue:alignmentRectInsets],
                             @"images": [imageDictionaries copy],
                             };
    }
    
    return transformedValue;
}

- (id)reverseTransformedValue:(id)value {
     if (![value isKindOfClass:[NSDictionary class]]) {
          return nil;
     }
    NSDictionary *dictionary = value;
    return [[self class] imageFromDictionary:dictionary];
}
@end


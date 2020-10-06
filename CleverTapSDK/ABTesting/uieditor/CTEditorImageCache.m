#import "CTEditorImageCache.h"
#import "CTABTestUtils.h"
#import <SDWebImage/SDImageCache.h>

@implementation CTEditorImageCache

NSString *const kABExpImageCacheName = @"CTABExpImageCache";
static SDImageCache *cache;

+ (void)initialize {
    if (!cache) {
        cache = [[SDImageCache alloc] initWithNamespace:kABExpImageCacheName];
    }
}

+ (UIImage *)getImage:(NSString *)imageUrl withSize:(CGSize)size {
    return [self getImage:imageUrl withScale: 1.0 andSize: size];
}

+ (UIImage *)getImage:(NSString *)imageUrl {
    return [self getImage:imageUrl withScale:1.0 andSize: CGSizeZero];
}

+ (UIImage *)getImage:(NSString *)imageUrl withScale:(CGFloat)scale andSize:(CGSize)size {
    UIImage *image = [cache imageFromCacheForKey:imageUrl];
    if (!image) {
        NSURLResponse *response;
        NSError *error;
        NSMutableURLRequest *request = [NSMutableURLRequest
                                        requestWithURL:[NSURL URLWithString:imageUrl] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20];
        NSData *imageData = [NSURLConnection
                             sendSynchronousRequest:request
                             returningResponse:&response error:&error];
        if (imageData) {
            image = [UIImage imageWithData:imageData scale:fminf(1.0, scale)];
            if (image) {
                [cache storeImage:image forKey:imageUrl toDisk:YES completion:nil];
            }
        }
    }
    if (image && size.height > 0 && size.width > 0) {
        UIGraphicsBeginImageContext(size);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return image;
}

+ (void)removeImage:(NSString *)imageUrl {
    [cache removeImageForKey:imageUrl fromDisk:YES withCompletion:nil];
}

@end

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CTEditorImageCache : NSObject

+ (UIImage *)getImage:(NSString *)imageUrl;
+ (UIImage *)getImage:(NSString *)imageUrl withScale:(CGFloat)scale andSize:(CGSize)size;
+ (void)removeImage:(NSString *)imageUrl;

@end

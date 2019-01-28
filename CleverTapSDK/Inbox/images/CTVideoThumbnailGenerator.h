#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CTVideoThumbnailGenerator : NSObject

- (void)generateImageFromUrl:(NSString *)videoURL withCompletionBlock:(void (^)(UIImage *image))completion;
- (void)cleanup;

@end

#import <Foundation/Foundation.h>
#import "CleverTapInstanceConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTFileDownloader : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config;
- (void)downloadFiles:(NSArray<NSString *> *)fileURLs withCompletionBlock:(void (^ _Nullable)(NSDictionary<NSString *, NSNumber *> *status))completion;
- (BOOL)isFileAlreadyPresent:(NSString *)url;
- (void)clearFileAssets:(BOOL)expiredOnly;
- (nullable NSString *)getFileDownloadPath:(NSString *)url;
- (nullable UIImage *)loadImageFromDisk:(NSString *)imageURL;

@end

NS_ASSUME_NONNULL_END

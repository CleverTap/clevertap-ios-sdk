#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>

@class CleverTapInstanceConfig;

NS_ASSUME_NONNULL_BEGIN

@interface CTFileDownloader : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config;
- (void)downloadFiles:(NSArray<NSString *> *)fileURLs withCompletionBlock:(void (^ _Nullable)(NSDictionary<NSString *, NSNumber *> *status))completion;
- (BOOL)isFileAlreadyPresent:(NSString *)url andUpdateExpiryTime:(BOOL)updateExpiryTime;
- (void)clearFileAssets:(BOOL)expiredOnly;
- (nullable NSString *)fileDownloadPath:(NSString *)url;
- (nullable UIImage *)loadImageFromDisk:(NSString *)imageURL;

/// Reads raw CS in-app image data from the SDWebImage-compatible disk cache.
/// Path: Library/Caches/com.hackemist.SDImageCache/default/MD5(url).[ext]
/// Returns nil if not cached. Caller decodes with content-type awareness (GIF → CTAnimatedImage).
- (nullable NSData *)loadInAppImageDataFromDisk:(NSURL *)imageURL;

/// Writes raw CS in-app image data to the SDWebImage-compatible disk cache.
/// Creates the directory if needed. Downgrade-safe: old SDK's SDWebImage reads this path.
- (void)storeInAppImageData:(NSData *)data forURL:(NSURL *)url;

/// Pre-fetches CS in-app images to the SDWebImage-compatible disk cache (async, background).
/// Skips URLs already present on disk. Called from downloadMediaURLs: on CS in-app receipt.
- (void)prefetchInAppImages:(NSArray<NSString *> *)imageURLs;

@end

NS_ASSUME_NONNULL_END

#import <Foundation/Foundation.h>
#import "CleverTapInstanceConfig.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int, CTFileDownloadType) {
    CTInAppClientSide = 0,
    CTInAppCustomTemplate = 1,
    CTFileVariables = 2,
};

@interface CTFileDownloader : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config;
- (void)downloadFiles:(NSArray<NSString *> *)fileURLs
               ofType:(CTFileDownloadType)type
  withCompletionBlock:(void (^ _Nullable)(NSDictionary<NSString *,id> *status))completion;
- (BOOL)isFileAlreadyPresent:(NSString *)url;
- (void)clearFileAssets:(BOOL)expiredOnly;
- (NSString *)getFileDownloadPath:(NSString *)url;
- (void)setFileAssetsInactiveOfType:(CTFileDownloadType)type;
- (nullable UIImage *)loadImageFromDisk:(NSString *)imageURL;

@end

NS_ASSUME_NONNULL_END

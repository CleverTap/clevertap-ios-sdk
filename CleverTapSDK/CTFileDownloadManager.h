#import <Foundation/Foundation.h>

@class CleverTapInstanceConfig;

NS_ASSUME_NONNULL_BEGIN

typedef void(^CTFilesDownloadCompletedBlock)(NSDictionary<NSString *, NSNumber *> *status);
typedef void(^CTFilesDeleteCompletedBlock)(NSDictionary<NSString *, NSNumber *> *status);
typedef void (^DownloadCompletionHandler)(NSURL *url, BOOL success);

@interface CTFileDownloadManager : NSObject

+ (instancetype)sharedInstanceWithConfig:(CleverTapInstanceConfig *)config;
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method
 
 @discussion
 This method accepts file urls as NSArray of NSURLs and download each file to NSDocumentDirectory directory.
 
 @param completion the completion block to be executed when all files are donwloaded. `status` dictionary will
                    contain file download status of each file as {url,success}
 */
- (void)downloadFiles:(NSArray<NSURL *> *)urls withCompletionBlock:(CTFilesDownloadCompletedBlock)completion;

/*!
 @method
 
 @discussion
 This method check if file is already present in NSDocumentDirectory directory or not.
 */
- (BOOL)isFileAlreadyPresent:(NSURL *)url;

/*!
 @method
 
 @discussion
 This method delete the files from NSDocumentDirectory directory if present.
 
 @param completion the completion block to be executed when all files are deleted. `status` dictionary will
                    contain file delete status of each file as {url,success}
 */
- (void)deleteFiles:(NSArray<NSString *> *)urls withCompletionBlock:(CTFilesDeleteCompletedBlock)completion;

@end

NS_ASSUME_NONNULL_END

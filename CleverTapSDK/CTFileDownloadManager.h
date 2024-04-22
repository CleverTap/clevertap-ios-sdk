#import <Foundation/Foundation.h>
#import "CleverTapInstanceConfig.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^CTFilesDownloadCompletedBlock)(NSDictionary<NSString *,id> *status);

@interface CTFileDownloadManager : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config;

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
 This method delete the file from NSDocumentDirectory directory if present.
 */
- (void)deleteFile:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END

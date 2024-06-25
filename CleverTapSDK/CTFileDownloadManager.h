#import <Foundation/Foundation.h>

@class CleverTapInstanceConfig;

NS_ASSUME_NONNULL_BEGIN

typedef void(^CTFilesDownloadCompletedBlock)(NSDictionary<NSString *, NSNumber *> *status);
typedef void(^CTFilesDeleteCompletedBlock)(NSDictionary<NSString *, NSNumber *> *status);
typedef void(^CTFilesRemoveCompletedBlock)(NSDictionary<NSString *, NSNumber *> *status);
typedef void (^DownloadCompletionHandler)(NSURL *url, BOOL success);

@interface CTFileDownloadManager : NSObject

+ (instancetype)sharedInstanceWithConfig:(CleverTapInstanceConfig *)config;
- (instancetype)init NS_UNAVAILABLE;

/*!
 @method
 
 @discussion
 This method accepts file urls as NSArray of NSURLs and downloads each file to directory inside NSDocumentDirectory directory.
 
 @param completion the completion block to be executed when all files are downloaded. `status` dictionary will
                    contain file download status of each file as {url,success}. The completion block is executed on background queue.
 */
- (void)downloadFiles:(NSArray<NSURL *> *)urls withCompletionBlock:(CTFilesDownloadCompletedBlock)completion;

/*!
 @method
 
 @discussion
 This method checks if file is already present in the directory or not.
 */
- (BOOL)isFileAlreadyPresent:(NSURL *)url;

/*!
 @method
 
 @discussion
 This method returns the file path to the file. This method does *not* check if the file exists.
 */
- (NSString *)filePath:(NSURL *)url;

/*!
 @method
 
 @discussion
 This method deletes the files from the directory if present.
 
 @param completion the completion block to be executed when all files are deleted. `status` dictionary will
                    contain file delete status of each file as {url,success}. The completion block is executed on background queue.
 */
- (void)deleteFiles:(NSArray<NSString *> *)urls withCompletionBlock:(CTFilesDeleteCompletedBlock)completion;

/*!
 @method
 
 @discussion
 This method deletes all files from the directory.
 
 @param completion the completion block to be executed when all files are deleted. `status` dictionary will
                    contain file download status of each file as {file path,success}. The completion block is executed on background queue.
 */
- (void)removeAllFilesWithCompletionBlock:(CTFilesRemoveCompletedBlock)completion;

@end

NS_ASSUME_NONNULL_END

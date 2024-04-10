#import <Foundation/Foundation.h>
#import "CleverTapInstanceConfig.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CTFileDownloadDelegate <NSObject>
@optional
/*!
 @discussion
 When a file is requested to download, this callback method is called with success or not.
 
 @param success The boolean describing whether file is downloaded or not.
 @param url The file url.
 */
- (void)singleFileDownloaded:(BOOL)success forURL:(NSString *)url;

/*!
 @discussion
 When `downloadFiles:`  is called , this callback method is with detailed status of each files.
 
 @param status This dictionary contains file download status of each file as {url,success}.
 */
- (void)allFilesDownloaded:(NSDictionary<NSString *,id> *)status;
@end

@interface CTFileDownloadManager : NSObject

@property (nonatomic, weak) id<CTFileDownloadDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config;

/*!
 @method
 
 @discussion
 This method accepts file urls as NSArray of NSURLs and download each file to NSDocumentDirectory directory.
 */
- (void)downloadFiles:(NSArray *)urls;

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

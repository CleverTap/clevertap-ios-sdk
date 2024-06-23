#import "CTFileDownloadManager.h"
#import "CTConstants.h"
#import "CleverTapInstanceConfig.h"

@interface CTFileDownloadManager()

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) NSString *documentsDirectory;
@property (nonatomic, strong) NSMutableSet<NSURL *> *downloadInProgressUrls;
@property (nonatomic, strong) NSMutableDictionary<NSURL *, NSMutableArray<DownloadCompletionHandler> *> *downloadInProgressHandlers;
@property (nonatomic, strong) NSURLSession *session;

@end

@implementation CTFileDownloadManager

+ (instancetype)sharedInstanceWithConfig:(CleverTapInstanceConfig *)config {
    static CTFileDownloadManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithConfig:config];
    });
    return sharedInstance;
}

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config {
    self = [super init];
    if (self) {
        self.config = config;
        self.documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        _downloadInProgressUrls = [NSMutableSet new];
        _downloadInProgressHandlers = [NSMutableDictionary new];
        
        NSURLSessionConfiguration *sc = [NSURLSessionConfiguration defaultSessionConfiguration];
        sc.timeoutIntervalForRequest = CLTAP_REQUEST_TIME_OUT_INTERVAL;
        sc.timeoutIntervalForResource = CLTAP_FILE_RESOURCE_TIME_OUT_INTERVAL;
        
        self.session = [NSURLSession sessionWithConfiguration:sc];
    }
    
    return self;
}

#pragma mark - Public methods
- (void)downloadFiles:(nonnull NSArray<NSURL *> *)urls
  withCompletionBlock:(nonnull CTFilesDownloadCompletedBlock)completion {
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    NSMutableDictionary<NSString *,id> *filesDownloadStatus = [NSMutableDictionary new];
    for (NSURL *url in urls) {
        dispatch_group_enter(group);
        @synchronized (self) {
            BOOL isAlreadyDownloading = [_downloadInProgressUrls containsObject:url];
            if (isAlreadyDownloading) {
                // If the url download is already in Progress, add the completion handler to
                // fileDownloadProgressHandlers dictionary which is called when file is downloaded.
                if (!_downloadInProgressHandlers[url]) {
                    _downloadInProgressHandlers[url] = [NSMutableArray array];
                }
                [_downloadInProgressHandlers[url] addObject:^(NSURL *completedURL, BOOL success) {
                    [filesDownloadStatus setObject:[NSNumber numberWithBool:success] forKey:[completedURL absoluteString]];
                    dispatch_group_leave(group);
                }];
                continue;
            }
        }
        
        // Download file only when it is not already present.
        if (![self isFileAlreadyPresent:url]) {
            @synchronized (self) {
                [_downloadInProgressUrls addObject:url];
            }
            dispatch_async(concurrentQueue, ^{
                [self downloadSingleFile:url completed:^(BOOL success) {
                    [filesDownloadStatus setObject:[NSNumber numberWithBool:success] forKey:[url absoluteString]];

                    // Call the other completion handlers for this file url if present
                    NSArray<DownloadCompletionHandler> *handlers;
                    @synchronized (self) {
                        handlers = [self->_downloadInProgressHandlers[url] copy];
                        [self->_downloadInProgressHandlers removeObjectForKey:url];
                        [self->_downloadInProgressUrls removeObject:url];
                    }
                    for (DownloadCompletionHandler handler in handlers) {
                        handler(url, success);
                    }
                    dispatch_group_leave(group);
                }];
            });
        } else {
            // Add the file url to callback as success true as it is already present
            [filesDownloadStatus setObject:@1 forKey:[url absoluteString]];
            dispatch_group_leave(group);
        }
    }
    dispatch_group_notify(group, concurrentQueue, ^{
        // Callback when all files are downloaded with their success status
        completion(filesDownloadStatus);
    });
}

- (BOOL)isFileAlreadyPresent:(NSURL *)url {
    NSString* filePath = [self.documentsDirectory stringByAppendingPathComponent:[url lastPathComponent]];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    return fileExists;
}

- (void)deleteFiles:(NSArray<NSString *> *)urls withCompletionBlock:(CTFilesDeleteCompletedBlock)completion {
    NSMutableDictionary<NSString *,id> *filesDeleteStatus = [NSMutableDictionary new];
    
    if (urls.count == 0) {
        completion(filesDeleteStatus);
        return;
    }

    dispatch_group_t deleteGroup = dispatch_group_create();
    dispatch_queue_t deleteConcurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    for (NSString *urlString in urls) {
        NSURL *url = [NSURL URLWithString:urlString];
        // Delete file only when it is present.
        if ([self isFileAlreadyPresent:url]) {
            dispatch_group_enter(deleteGroup);
            dispatch_async(deleteConcurrentQueue, ^{
                [self deleteSingleFile:url completed:^(BOOL success) {
                    [filesDeleteStatus setObject:[NSNumber numberWithBool:success] forKey:urlString];
                    dispatch_group_leave(deleteGroup);
                }];
            });
        } else {
            // Add the file url to callback as success true as it is already not present
            [filesDeleteStatus setObject:@1 forKey:[url absoluteString]];
        }
    } 
    dispatch_group_notify(deleteGroup, deleteConcurrentQueue, ^{
        // Callback when all files are deleted with their success status
        completion(filesDeleteStatus);
    });
}

#pragma mark - Private methods

- (void)downloadSingleFile:(NSURL *)url
                 completed:(void(^)(BOOL success))completedBlock {
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithURL:url
                                                             completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error) {
            CleverTapLogInternal(self.config.logLevel, @"%@ Error downloading file: %@ - %@", self, url, error);
            completedBlock(NO);
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            CleverTapLogInternal(self.config.logLevel, @"HTTP Error: %ld for file: %@", (long)httpResponse.statusCode, url);
            completedBlock(NO);
            return;
        }
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // Create the destination path by appending the suggested filename to the documents directory path
        NSString *destinationPath = [self.documentsDirectory stringByAppendingPathComponent:[response suggestedFilename]];
        NSURL *destinationURL = [NSURL fileURLWithPath:destinationPath];
        // Move the file from the temporary location to the documents directory
        NSError *fileError;
        [fileManager moveItemAtURL:location toURL:destinationURL error:&fileError];
        if (fileError) {
            CleverTapLogInternal(self.config.logLevel, @"File Error: %@ for file: %@", fileError.localizedDescription, url);
            completedBlock(NO);
            return;
        }
        completedBlock(YES);
    }];
    [downloadTask resume];
}

- (void)deleteSingleFile:(NSURL *)url
               completed:(void(^)(BOOL success))completedBlock {
    if (![url lastPathComponent] || [[url lastPathComponent] isEqualToString:@""]) {
        completedBlock(NO);
        return;
    }

    NSString *filePath = [self.documentsDirectory stringByAppendingPathComponent:[url lastPathComponent]];
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    if (!success) {
        CleverTapLogInternal(self.config.logLevel, @"%@ Failed to remove file %@ - %@", self, url, error);
    }
    completedBlock(success);
}

@end

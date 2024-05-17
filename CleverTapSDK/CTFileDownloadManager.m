#import "CTFileDownloadManager.h"
#import "CTConstants.h"

@interface CTFileDownloadManager()
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) NSString *documentsDirectory;
@end

@implementation CTFileDownloadManager

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config {
    self = [super init];
    if (self) {
        self.config = config;
        self.documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
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
        // Download file only when it is not already present.
        if (![self isFileAlreadyPresent:url]) {
            dispatch_group_enter(group);
            dispatch_async(concurrentQueue, ^{
                [self downloadSingleFile:url completed:^(BOOL success) {
                    [filesDownloadStatus setObject:[NSNumber numberWithBool:success] forKey:[url absoluteString]];
                    dispatch_group_leave(group);
                }];
            });
        } else {
            // Add the file url to callback as success true as it is already present
            [filesDownloadStatus setObject:@1 forKey:[url absoluteString]];
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

-(void)downloadSingleFile:(NSURL *)url
                completed:(void(^)(BOOL success))completedBlock {
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithURL:url
                                                        completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error) {
            CleverTapLogInternal(self.config.logLevel, @"%@ Error downloading file %@ - %@", self, url, error);
            completedBlock(NO);
            return;
        }
        NSData *fileData = [NSData dataWithContentsOfURL:location];

        // Save the file to a desired location
        NSString *filePath = [self.documentsDirectory stringByAppendingPathComponent:[response suggestedFilename]];
        [fileData writeToFile:filePath atomically:YES];
        completedBlock(YES);
    }];
    [downloadTask resume];
}

- (void)deleteSingleFile:(NSURL *)url
               completed:(void(^)(BOOL success))completedBlock {
    NSString *filePath = [self.documentsDirectory stringByAppendingPathComponent:[url lastPathComponent]];
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    if (!success) {
        CleverTapLogInternal(self.config.logLevel, @"%@ Failed to remove file %@ - %@", self, url, error);
    }
    completedBlock(success);
}

@end

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

- (void)downloadFiles:(nonnull NSArray *)urls {
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    NSMutableDictionary<NSString *,id> *filesDownloadStatus = [NSMutableDictionary new];
    for (NSURL *url in urls) {
        dispatch_group_enter(group);
        dispatch_async(concurrentQueue, ^{
            [self downloadSingleFile:url completed:^(BOOL success) {
                // Callback for each file download
                if (self.delegate && [self.delegate respondsToSelector:@selector(singleFileDownloaded:forURL:)]) {
                    [self.delegate singleFileDownloaded:success forURL:[url absoluteString]];
                }

                [filesDownloadStatus setObject:[NSNumber numberWithBool:success] forKey:[url absoluteString]];
                dispatch_group_leave(group);
            }];
        });
    }
    dispatch_group_notify(group, concurrentQueue, ^{
        // Callback when all files are downloaded with their success status
        if (self.delegate && [self.delegate respondsToSelector:@selector(allFilesDownloaded:)]) {
            [self.delegate allFilesDownloaded:filesDownloadStatus];
        }
    });
}

- (BOOL)isFileAlreadyPresent:(NSURL *)url {
    NSString* filePath = [self.documentsDirectory stringByAppendingPathComponent:[url lastPathComponent]];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    return fileExists;
}

- (void)deleteFile:(NSURL *)url {
    if ([self isFileAlreadyPresent:url]) {
        NSString *filePath = [self.documentsDirectory stringByAppendingPathComponent:[url lastPathComponent]];
        NSError *error;
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (!success) {
            CleverTapLogInternal(self.config.logLevel, @"%@ Failed to remove file %@ - %@", self, url, error);
        }
    }
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

@end

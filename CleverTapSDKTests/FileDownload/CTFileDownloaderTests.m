#import <XCTest/XCTest.h>
#import <OHHTTPStubs/HTTPStubs.h>
#import "CTPreferences.h"
#import "CTConstants.h"
#import "CTFileDownloadManager.h"
#import "CTFileDownloadTestHelper.h"
#import "CTFileDownloader+Tests.h"
#import "CTFileDownloaderMock.h"
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/SDWebImageManager.h>

@interface CTFileDownloaderTests : XCTestCase

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTFileDownloaderMock *fileDownloader;
@property (nonatomic, strong) NSArray *fileURLs;
@property (nonatomic, strong) CTFileDownloadTestHelper *helper;

@end

@implementation CTFileDownloaderTests

- (void)setUp {
    [super setUp];
    
    self.helper = [CTFileDownloadTestHelper new];
    [self.helper addHTTPStub];
    
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccountId" accountToken:@"testAccountToken"];
    self.fileDownloader = [[CTFileDownloaderMock alloc] initWithConfig:self.config];
}

- (void)tearDown {
    [super tearDown];
    
    [self.helper removeStub];
    
    [CTPreferences removeObjectForKey:[self.fileDownloader storageKeyWithSuffix:CLTAP_FILE_URLS_EXPIRY_DICT]];
    [CTPreferences removeObjectForKey:[self.fileDownloader storageKeyWithSuffix:CLTAP_FILE_ASSETS_LAST_DELETED_TS]];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for cleanup"];
    self.fileDownloader.removeAllAssetsCompletion = ^(NSDictionary<NSString *,id> * _Nonnull status) {
        [expectation fulfill];
    };
    // Clear all files
    [self.fileDownloader clearFileAssets:NO];
    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testRemoveLegacyAssets {
    // Setup
    NSArray *urls = @[
        [NSString stringWithFormat:@"https://clevertap.com/%@_0.png", self.helper.fileURL],
        [NSString stringWithFormat:@"https://clevertap.com/%@_1.jpg", self.helper.fileURL],
        [NSString stringWithFormat:@"https://clevertap.com/%@_2.jpeg", self.helper.fileURL],
        [NSString stringWithFormat:@"https://clevertap.com/%@_3.png", self.helper.fileURL]
    ];
    NSArray<NSString *> *activeAssetsArray = @[urls[0], urls[1]];
    NSArray<NSString *> *inactiveAssetsArray = @[urls[2], urls[3]];
    [CTPreferences putObject:activeAssetsArray forKey:[self.fileDownloader storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_ACTIVE_ASSETS]];
    [CTPreferences putObject:inactiveAssetsArray forKey:[self.fileDownloader storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_INACTIVE_ASSETS]];
    
    long ts = (long)[[NSDate date] timeIntervalSince1970];
    self.fileDownloader.mockCurrentTimeInterval = ts;
    [CTPreferences putInt:ts forKey:[self.fileDownloader storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_ASSETS_LAST_DELETED_TS]];
    
    SDWebImageManager *sdWebImageManager = [SDWebImageManager sharedManager];
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDWebImage loadImageWithURL"];
    dispatch_group_t downloads = dispatch_group_create();
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    for (NSString *url in urls) {
        dispatch_group_enter(downloads);
        dispatch_async(concurrentQueue, ^{
            [sdWebImageManager loadImageWithURL:[NSURL URLWithString:url]
                                        options:SDWebImageRetryFailed
                                        context:@{SDWebImageContextStoreCacheType : @(SDImageCacheTypeDisk)}
                                       progress:nil
                                      completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                dispatch_group_leave(downloads);
            }];
        });
    }
    dispatch_group_notify(downloads, concurrentQueue, ^{
        [expectation fulfill];
    });
    
    [self waitForExpectations:@[expectation] timeout:2.0];
    SDImageCache *sdImageCache = [SDImageCache sharedImageCache];
    for (NSString *url in urls) {
        XCTAssertNotNil([sdImageCache imageFromDiskCacheForKey:url]);
    }
    
    // Remove legacy assets
    XCTestExpectation *expectationRemoveLegacyAssets = [self expectationWithDescription:@"RemoveLegacyAssets"];
    [self.fileDownloader removeLegacyAssets:^{
        XCTAssertNil([CTPreferences getObjectForKey:[self.fileDownloader storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_ACTIVE_ASSETS]]);
        XCTAssertNil([CTPreferences getObjectForKey:[self.fileDownloader storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_INACTIVE_ASSETS]]);
        XCTAssertNil([CTPreferences getObjectForKey:[self.fileDownloader storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_ASSETS_LAST_DELETED_TS]]);
        for (NSString *url in urls) {
            XCTAssertNil([sdImageCache imageFromDiskCacheForKey:url]);
        }
        [expectationRemoveLegacyAssets fulfill];
    }];
    
    [self waitForExpectations:@[expectationRemoveLegacyAssets] timeout:2.0];
}

- (void)testSetup {
    // Test setup initializes the FileDownloader with the urlsExpiry from cache
    NSDictionary *urlsExpiry= @{
        @"url0": @(1),
        @"url1": @(1)
    };
    [CTPreferences putObject:urlsExpiry forKey:[self.fileDownloader storageKeyWithSuffix:CLTAP_FILE_URLS_EXPIRY_DICT]];
    
    self.fileDownloader = [[CTFileDownloaderMock alloc] initWithConfig:self.config];
    XCTAssertTrue([urlsExpiry isEqualToDictionary:self.fileDownloader.urlsExpiry]);
    XCTAssertTrue([self.fileDownloader.urlsExpiry isKindOfClass:[NSMutableDictionary class]]);
    
    // Test setup initializes the FileDownloader with empty dictionary if no cached value
    [CTPreferences removeObjectForKey:[self.fileDownloader storageKeyWithSuffix:CLTAP_FILE_URLS_EXPIRY_DICT]];
    self.fileDownloader = [[CTFileDownloaderMock alloc] initWithConfig:self.config];
    XCTAssertNotNil(self.fileDownloader.urlsExpiry);
    XCTAssertEqual(0, self.fileDownloader.urlsExpiry.count);
    XCTAssertTrue([self.fileDownloader.urlsExpiry isKindOfClass:[NSMutableDictionary class]]);
}

- (void)testDefaultExpiryTime {
    XCTAssertEqual(self.fileDownloader.fileExpiryTime, CLTAP_FILE_EXPIRY_OFFSET);
}

- (void)testFileAlreadyPresent {
    NSArray *urls = [self.helper generateFileURLStrings:2];
    XCTAssertFalse([self.fileDownloader isFileAlreadyPresent:urls[0] andUpdateExpiryTime:NO]);
    XCTAssertFalse([self.fileDownloader isFileAlreadyPresent:urls[1] andUpdateExpiryTime:NO]);
    
    [self downloadFiles:@[urls[0]]];
    
    XCTAssertTrue([self.fileDownloader isFileAlreadyPresent:urls[0] andUpdateExpiryTime:NO]);
    XCTAssertFalse([self.fileDownloader isFileAlreadyPresent:urls[1] andUpdateExpiryTime:NO]);
}

- (void)testImageLoadedFromDisk {
    // Download files
    NSArray *urls = [self.helper generateFileURLStrings:3];
    // Download files, urls[2] is of type txt
    [self downloadFiles:@[urls[2]]];
    
    // Check image is present in disk cache
    UIImage *image = [self.fileDownloader loadImageFromDisk:urls[2]];
    XCTAssertNotNil(image);
}

- (void)testImageNotLoadedFromDisk {
    NSArray *urls = [self.helper generateFileURLStrings:3];
    // Download files, urls[0] is of type txt
    [self downloadFiles:@[urls[0]]];
    
    // Check image is present in disk cache
    UIImage *image = [self.fileDownloader loadImageFromDisk:urls[0]];
    XCTAssertNil(image);
}

- (void)testFileDownloadPath {
    NSArray *urls = [self.helper generateFileURLStrings:1];
    [self downloadFiles:urls];
    NSString *filePath = [self.fileDownloader fileDownloadPath:urls[0]];

    NSURL *URL = [NSURL URLWithString:urls[0]];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *pathComponent = [URL lastPathComponent];
    long hash = [urls[0] hash];
    NSString *fileName = [NSString stringWithFormat:@"%@/%ld_%@", CLTAP_FILES_DIRECTORY_NAME, hash, pathComponent];
    NSString *expectedFilePath = [documentsPath stringByAppendingPathComponent:fileName];
    XCTAssertNotNil(filePath);
    XCTAssertEqualObjects(filePath, expectedFilePath);
}

- (void)testFileDownloadPathNotFound {
    NSArray *urls = [self.helper generateFileURLStrings:1];
    NSString *filePath = [self.fileDownloader fileDownloadPath:urls[0]];
    XCTAssertNil(filePath);
}

- (void)testDownloadEmptyUrls {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download files"];
    [self.fileDownloader downloadFiles:@[] withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
        XCTAssertNotNil(status);
        XCTAssertTrue(status.count == 0);
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testDownloadUpdatesFileExpiryTs {
    // Mock currentTimeInterval
    long ts = (long)[[NSDate date] timeIntervalSince1970];
    self.fileDownloader.mockCurrentTimeInterval = ts;
    
    NSString *url = [self.helper generateFileURLStrings:1][0];
    // Ensure not yet present
    XCTAssertNil(self.fileDownloader.urlsExpiry[url]);
    
    [self downloadFiles:@[url]];
    long expiryDate = ts + self.fileDownloader.fileExpiryTime;
    // Ensure url has correct expiry set
    XCTAssertEqualObjects(@(expiryDate), self.fileDownloader.urlsExpiry[url]);
    
    self.fileDownloader.mockCurrentTimeInterval = ts + 100;
    [self downloadFiles:@[url]];
    // Ensure url expiry is updated
    XCTAssertEqualObjects(@(expiryDate + 100), self.fileDownloader.urlsExpiry[url]);
}

- (void)testDownloadUpdatesFileExpiryCache {
    NSArray *urls = [self.helper generateFileURLStrings:2];
    XCTAssertEqual(0, self.fileDownloader.urlsExpiry.count);
    
    long ts = (long)[[NSDate date] timeIntervalSince1970];
    self.fileDownloader.mockCurrentTimeInterval = ts;
    [self downloadFiles:urls];
    NSDictionary *urlsExpiry = [NSDictionary dictionaryWithDictionary:self.fileDownloader.urlsExpiry];
    XCTAssertEqual(2, self.fileDownloader.urlsExpiry.count);
    XCTAssertEqualObjects(self.fileDownloader.urlsExpiry, [CTPreferences getObjectForKey:[self.fileDownloader storageKeyWithSuffix:CLTAP_FILE_URLS_EXPIRY_DICT]]);
    
    self.fileDownloader.mockCurrentTimeInterval = ts + 100;
    [self downloadFiles:urls];
    XCTAssertNotEqualObjects(urlsExpiry, self.fileDownloader.urlsExpiry);
    XCTAssertEqualObjects(self.fileDownloader.urlsExpiry, [CTPreferences getObjectForKey:[self.fileDownloader storageKeyWithSuffix:CLTAP_FILE_URLS_EXPIRY_DICT]]);
}

- (void)testDownloadTriggersRemoveExpired {
    NSArray *urls = [self.helper generateFileURLStrings:2];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download triggers remove expired files"];
    long lastDeletedTs = [self.fileDownloader lastDeletedTimestamp];
    // Download files should trigger removeInactiveExpiredAssets with the lastDeletedTimestamp
    self.fileDownloader.removeInactiveExpiredAssetsBlock = ^(long lastDeleted) {
        XCTAssertEqual(lastDeletedTs, lastDeleted);
        [expectation fulfill];
    };
    [self downloadFiles:urls];
    [self waitForExpectations:@[expectation] timeout:1.0];
}

- (void)testRemoveExpiredAssetsNoDeletedFiles {
    // This block is synchronous
    self.fileDownloader.deleteFilesInvokedBlock = ^(NSArray<NSString *> *urls) {
        // Delete files should not be invoked if the last deleted time is within the expiry time
        XCTFail();
    };
    
    long ts = (long)[[NSDate date] timeIntervalSince1970];
    long lastDeleted = ts - 1;
    self.fileDownloader.mockCurrentTimeInterval = ts;
    self.fileDownloader.urlsExpiry = [@{
        @"url0": @(4)
    } mutableCopy];
    [self.fileDownloader removeInactiveExpiredAssets:lastDeleted];
    self.fileDownloader.deleteFilesInvokedBlock = nil;
}

- (void)testRemoveExpiredAssets {
    // Mock the current time
    long ts = (long)[[NSDate date] timeIntervalSince1970];
    self.fileDownloader.mockCurrentTimeInterval = ts;

    NSString *expiredUrl1 = @"url0-expired";
    NSString *expiredUrl2 = @"url2-expired";

    self.fileDownloader.deleteFilesInvokedBlock = ^(NSArray<NSString *> *urls) {
        // Delete files is invoked with the expired urls only
        NSSet *urlsSet = [NSSet setWithArray:urls];
        NSSet *expected = [NSSet setWithArray:@[expiredUrl1, expiredUrl2]];
        XCTAssertEqualObjects(expected, urlsSet);
    };
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for delete completion"];
    __weak CTFileDownloaderTests *weakSelf = self;
    // Expired files are deleted
    self.fileDownloader.deleteCompletion = ^(NSDictionary<NSString *, id> * _Nonnull status) {
        XCTAssertNotNil([status objectForKey:expiredUrl1]);
        XCTAssertNotNil([status objectForKey:expiredUrl2]);
        
        NSDictionary *urlsExpiry = [@{
            @"url1": @(ts),
            @"url3": @(ts + 1)
        } mutableCopy];
        
        XCTAssertTrue([weakSelf.fileDownloader.urlsExpiry isEqualToDictionary:urlsExpiry]);
        [expectation fulfill];
    };
    
    // Calculate last deleted to force remove assets
    long lastDeleted = ts - self.fileDownloader.fileExpiryTime - 1;
    
    // Set the urls expiry to have both expired and valid assets
    self.fileDownloader.urlsExpiry = [@{
        expiredUrl1: @(ts - 1),
        @"url1": @(ts),
        expiredUrl2: @(ts - 60),
        @"url3": @(ts + 1),
    } mutableCopy];
    
    [self.fileDownloader removeInactiveExpiredAssets:lastDeleted];
    [self waitForExpectations:@[expectation] timeout:2.0];
    self.fileDownloader.deleteFilesInvokedBlock = nil;
}

- (void)testUpdateFilesExpiry {
    long ts = (long)[[NSDate date] timeIntervalSince1970];
    self.fileDownloader.mockCurrentTimeInterval = ts;
    long expiry = ts + self.fileDownloader.fileExpiryTime;

    // url0 and url3 are successful
    NSDictionary *status = @{
        @"url0": @(1),
        @"url1": @(0),
        @"url2": @(0),
        @"url3": @(1)
    };
    
    long previousExpiry = (ts - 100) + self.fileDownloader.fileExpiryTime;
    // url3 is not in the expiry dictionary
    self.fileDownloader.urlsExpiry = [@{
        @"url0": @(previousExpiry),
        @"url2": @(previousExpiry),
        @"url4": @(previousExpiry)
    } mutableCopy];
    
    [self.fileDownloader updateFilesExpiry:status];
    
    // Expect url0 to be updated and url3 to be added
    NSMutableDictionary *expected = [@{
        @"url0": @(expiry),
        @"url2": @(previousExpiry),
        @"url3": @(expiry),
        @"url4": @(previousExpiry)
    } mutableCopy];
    
    XCTAssertEqualObjects(expected, self.fileDownloader.urlsExpiry);
}

- (void)testDeleteFiles {
    long ts = (long)[[NSDate date] timeIntervalSince1970];
    self.fileDownloader.mockCurrentTimeInterval = ts;
    
    // Set 3 files in urlsExpiry
    NSArray<NSString *> *urls = [self.helper generateFileURLStrings:3];
    for (NSString *url in urls) {
        self.fileDownloader.urlsExpiry[url] = @(ts);
    }
    
    // Assert lastDeletedTimestamp returns current timestamp
    XCTAssertEqual(ts, [self.fileDownloader lastDeletedTimestamp]);
    // Change the current timestamp
    self.fileDownloader.mockCurrentTimeInterval = ts + 100;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delete files."];
    // Delete 1st and 2nd file (3rd file is not deleted)
    [self.fileDownloader deleteFiles:@[urls[0], urls[1]] withCompletionBlock:^(NSDictionary<NSString *,id> * _Nonnull status) {
        // Assert files are deleted
        XCTAssertEqualObjects(status[urls[0]], @1);
        XCTAssertEqualObjects(status[urls[1]], @1);
        
        // Assert 1st and 2nd files are removed from urlsExpiry
        // Assert 3rd file is still in the urlsExpiry
        NSDictionary *expectedExpiry = [@{
            urls[2]: @(ts)
        } mutableCopy];
        XCTAssertTrue([expectedExpiry isEqualToDictionary:self.fileDownloader.urlsExpiry]);
        
        // Assert expiry is updated in preferences
        XCTAssertEqualObjects(self.fileDownloader.urlsExpiry, [CTPreferences getObjectForKey:[self.fileDownloader storageKeyWithSuffix:CLTAP_FILE_URLS_EXPIRY_DICT]]);

        // Assert last deleted timestamp is updated
        XCTAssertEqual(ts + 100, [self.fileDownloader lastDeletedTimestamp]);
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testClearExpiredFiles {
    long ts = (long)[[NSDate date] timeIntervalSince1970];
    self.fileDownloader.mockCurrentTimeInterval = ts;
    NSArray<NSString *> *urlsExpiry = [self.helper generateFileURLStrings:3];
    for (int i = 1; i < urlsExpiry.count; i++) {
        // Set to expired
        self.fileDownloader.urlsExpiry[urlsExpiry[i]] = @(ts - 1);
    }
    // Set non expired
    self.fileDownloader.urlsExpiry[urlsExpiry[0]] = @(ts);
    XCTestExpectation *expectation = [self expectationWithDescription:@"ClearAllFiles expired only triggers remove expired files"];
    self.fileDownloader.removeInactiveExpiredAssetsBlock = ^(long lastDeleted) {
        long expectedForceLastDeleted = (ts - self.fileDownloader.fileExpiryTime) - 1;
        XCTAssertEqual(expectedForceLastDeleted, lastDeleted);
        XCTAssertTrue(ts - expectedForceLastDeleted > self.fileDownloader.fileExpiryTime);
        [expectation fulfill];
    };
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"ClearAllFiles trigger delete files"];
    self.fileDownloader.deleteFilesInvokedBlock = ^(NSArray<NSString *> *urls) {
        NSSet *urlsSet = [NSSet setWithArray:urls];
        // Expired URLs are to be deleted
        NSSet *expected = [NSSet setWithObjects:urlsExpiry[1], urlsExpiry[2], nil];
        XCTAssertEqualObjects(expected, urlsSet);
        [expectation2 fulfill];
    };
    [self.fileDownloader clearFileAssets:YES];
    [self waitForExpectations:@[expectation, expectation2] timeout:2.0];
    self.fileDownloader.deleteFilesInvokedBlock = nil;
}

- (void)testDownloadAndClearAllFileAssets {
    // Mock the current timestamp
    long ts = (long)[[NSDate date] timeIntervalSince1970];
    self.fileDownloader.mockCurrentTimeInterval = ts;
    
    // Download files
    NSArray *urls = [self.helper generateFileURLStrings:3];
    [self downloadFiles:urls];
    // Assert expiry is updated
    XCTAssertEqual(3, self.fileDownloader.urlsExpiry.count);

    NSMutableArray *paths = [NSMutableArray array];
    for (NSString *url in urls) {
        // Assert the files are downloaded
        XCTAssertTrue([self.fileDownloader isFileAlreadyPresent:url andUpdateExpiryTime:NO]);
        [paths addObject:[self.fileDownloader fileDownloadPath:url]];
    }

    long lastDeleted = self.fileDownloader.lastDeletedTimestamp;
    self.fileDownloader.mockCurrentTimeInterval = lastDeleted + 100;

    // Clear all file assets
    XCTestExpectation *expectation = [self expectationWithDescription:@"Clear all assets"];
    __weak CTFileDownloaderTests *weakSelf = self;
    self.fileDownloader.removeAllAssetsCompletion = ^(NSDictionary<NSString *,NSNumber *> * _Nonnull status) {
        // Assert all files status is success
        for (NSString *path in paths) {
            XCTAssertTrue(status[path]);
        }
        // Assert the files no longer exist
        for (NSString *url in urls) {
            XCTAssertFalse([weakSelf.fileDownloader isFileAlreadyPresent:url andUpdateExpiryTime:NO]);
        }
        // Assert urlsExpiry is cleared
        XCTAssertEqual(0, weakSelf.fileDownloader.urlsExpiry.count);
        // Assert the last deleted ts is updated
        XCTAssertEqual(lastDeleted + 100, weakSelf.fileDownloader.lastDeletedTimestamp);
        [expectation fulfill];
    };
    
    [self.fileDownloader clearFileAssets:NO];
    [self waitForExpectations:@[expectation] timeout:2.0];
    self.fileDownloader.removeAllAssetsCompletion = nil;
}

- (void)testFileDownloadCallbacksWhenFileIsAlreadyDownloading {
    // This test checks the file download callbacks when same url is already downloading.
    // Verified from adding logs that same url is not downloaded twice if download is in
    // progress for that url. Also callbacks are triggered when download is completed.
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Wait for first download callbacks"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Wait for second download callbacks"];
    
    NSArray *urls = [self.helper generateFileURLStrings:3];
    [self.fileDownloader downloadFiles:@[urls[0], urls[1], urls[2]] withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
        XCTAssertTrue([self.fileDownloader isFileAlreadyPresent:urls[0] andUpdateExpiryTime:NO]);
        XCTAssertTrue([self.fileDownloader isFileAlreadyPresent:urls[1] andUpdateExpiryTime:NO]);
        XCTAssertTrue([self.fileDownloader isFileAlreadyPresent:urls[2] andUpdateExpiryTime:NO]);
        [expectation1 fulfill];
    }];
    [self.fileDownloader downloadFiles:@[urls[0], urls[1]] withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
        XCTAssertTrue([self.fileDownloader isFileAlreadyPresent:urls[0] andUpdateExpiryTime:NO]);
        XCTAssertTrue([self.fileDownloader isFileAlreadyPresent:urls[1] andUpdateExpiryTime:NO]);
        [expectation2 fulfill];
    }];
    [self waitForExpectations:@[expectation2, expectation1] timeout:2.0 enforceOrder:YES];
}

- (void)testFileAlreadyPresentUpdatesFileExpiryTime {
    // This test checks that file expiry time is updated when file is already present
    // and `isFileAlreadyPresent:` method is called with andUpdateExpiryTime YES.
    
    // Mock currentTimeInterval
    long ts = (long)[[NSDate date] timeIntervalSince1970];
    self.fileDownloader.mockCurrentTimeInterval = ts;
    
    NSString *url = [self.helper generateFileURLStrings:1][0];
    [self downloadFiles:@[url]];
    long expiryDate = ts + self.fileDownloader.fileExpiryTime;
    // Ensure url has correct expiry set
    XCTAssertEqualObjects(@(expiryDate), self.fileDownloader.urlsExpiry[url]);
    
    self.fileDownloader.mockCurrentTimeInterval = ts + 100;
    [self.fileDownloader isFileAlreadyPresent:url andUpdateExpiryTime:YES];
    // Ensure url expiry is updated
    XCTAssertEqualObjects(@(expiryDate + 100), self.fileDownloader.urlsExpiry[url]);
}

- (void)testFileAlreadyPresentDoesNotUpdatesFileExpiryTime {
    // This test checks that file expiry time is not updated when file is already present
    // and `isFileAlreadyPresent:` method is called with andUpdateExpiryTime NO.
    
    // Mock currentTimeInterval
    long ts = (long)[[NSDate date] timeIntervalSince1970];
    self.fileDownloader.mockCurrentTimeInterval = ts;
    
    NSString *url = [self.helper generateFileURLStrings:1][0];
    [self downloadFiles:@[url]];
    long expiryDate = ts + self.fileDownloader.fileExpiryTime;
    // Ensure url has correct expiry set
    XCTAssertEqualObjects(@(expiryDate), self.fileDownloader.urlsExpiry[url]);
    
    self.fileDownloader.mockCurrentTimeInterval = ts + 100;
    [self.fileDownloader isFileAlreadyPresent:url andUpdateExpiryTime:NO];
    // Ensure url expiry is not updated
    XCTAssertEqualObjects(@(expiryDate), self.fileDownloader.urlsExpiry[url]);
}

#pragma mark Private methods

- (void)downloadFiles:(NSArray *)urls  {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download files"];
    [self.fileDownloader downloadFiles:urls withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:2.0];
}

@end

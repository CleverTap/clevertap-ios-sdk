#import <XCTest/XCTest.h>
#import <OHHTTPStubs/HTTPStubs.h>
#import "CleverTapInstanceConfig.h"
#import "CTFileDownloadManager+Tests.h"
#import "CTConstants.h"
#import "CTFileDownloadTestHelper.h"
#import "NSFileManagerMock.h"
#import "NSURLSessionMock.h"

@interface CTFileDownloadManagerTests : XCTestCase

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTFileDownloadManager *fileDownloadManager;
@property (nonatomic, strong) NSArray<NSURL *> *fileURLs;
@property (nonatomic, strong) CTFileDownloadTestHelper *helper;

@end

@implementation CTFileDownloadManagerTests

- (void)setUp {
    [super setUp];

    self.helper = [CTFileDownloadTestHelper new];
    [self.helper addHTTPStub];
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccountId" accountToken:@"testAccountToken"];
    self.fileDownloadManager = [[CTFileDownloadManager alloc] initWithConfig:self.config];
}

- (void)tearDown {
    [super tearDown];
    
    [self.helper removeStub];
    [self deleteFiles:self.fileURLs];
}

- (void)testFilesExist {
    [self downloadFiles];
    
    for (NSURL *url in self.fileURLs) {
        NSString *filePath = [NSString stringWithFormat:@"%lu_%@", [url.absoluteString hash], [url lastPathComponent]];
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *ctFiles = [documentsDirectory stringByAppendingPathComponent:CLTAP_FILES_DIRECTORY_NAME];
        NSString *path = [ctFiles stringByAppendingPathComponent:filePath];
        
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:path]);
    }
}

- (void)testFilePath {
    NSURL *url = [NSURL URLWithString:@"https://clevertap.com/ct_test_url_0.png"];
    NSString *filePath = [self.fileDownloadManager filePath:url];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    documentsPath = [documentsPath stringByAppendingPathComponent:CLTAP_FILES_DIRECTORY_NAME];
    XCTAssertEqualObjects(filePath, [documentsPath stringByAppendingPathComponent:@"1176188917138815486_ct_test_url_0.png"]);
}

- (void)testIsFileAlreadyPresent {
    [self downloadFiles];

    for(int i = 0; i < [self.fileURLs count]; i++) {
        XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[i]]);
    }
}

- (void)testDeleteFiles {
    [self downloadFiles];

    NSArray *urls = [self.helper generateFileURLs:2];
    [self deleteFiles:urls];

    // Deleted 1st and 2nd file url.
    XCTAssertFalse([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[0]]);
    XCTAssertFalse([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[1]]);
    XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[2]]);
}

- (void)testDeleteFilesStatus {
    [self downloadFiles];
    
    NSMutableArray<NSString *> *deleteFileURLs = [NSMutableArray new];
    for(int i = 0; i < self.fileURLs.count; i++) {
        // Ensure files are downloaded and saved to disk
        XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[i]]);
        NSString *fileURL = [self.fileURLs[i] absoluteString];
        [deleteFileURLs addObject:fileURL];
    }
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delete files"];
    [self.fileDownloadManager deleteFiles:deleteFileURLs withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
        for (NSString *url in deleteFileURLs) {
            // Assert delete status is success and file is removed from disk
            XCTAssertEqual(YES, [status[url] boolValue]);
            XCTAssertFalse([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[0]]);
        }
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testNotExistDeleteFiles {
    NSArray *urls = [self.helper generateFileURLStrings:2];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delete files"];
    [self.fileDownloadManager deleteFiles:urls withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
        for (NSString *url in urls) {
            XCTAssertEqual(YES, [status[url] boolValue]);
        }
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testDeleteSingleFile {
    [self downloadFiles:1];
    XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[0]]);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delete single file"];
    [self.fileDownloadManager deleteSingleFile:self.fileURLs[0] completed:^(BOOL success) {
        XCTAssertEqual(YES, success);
        XCTAssertFalse([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[0]]);
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testDeleteSingleFileIncorrectURL {
    XCTestExpectation *expectationNil = [self expectationWithDescription:@"Delete single file nil url"];
    NSURL *urlNil = nil;
    [self.fileDownloadManager deleteSingleFile:urlNil completed:^(BOOL success) {
        XCTAssertEqual(NO, success);
        [expectationNil fulfill];
    }];
    
    XCTestExpectation *expectationEmpty = [self expectationWithDescription:@"Delete single file nil url"];
    NSURL *urlEmpty = [NSURL URLWithString:@""];
    [self.fileDownloadManager deleteSingleFile:urlEmpty completed:^(BOOL success) {
        XCTAssertEqual(NO, success);
        [expectationEmpty fulfill];
    }];
    
    XCTestExpectation *expectationNoLastComponent = [self expectationWithDescription:@"Delete single file nil url"];
    NSURL *urlNoLastComponent = [NSURL URLWithString:@"https://no-url-component.png"];
    [self.fileDownloadManager deleteSingleFile:urlNoLastComponent completed:^(BOOL success) {
        XCTAssertEqual(NO, success);
        [expectationNoLastComponent fulfill];
    }];
    
    [self waitForExpectations:@[expectationNil, expectationEmpty, expectationNoLastComponent] timeout:2.0];
}

#pragma mark CTFileDownload callback test

- (void)testAllFilesDownloadedCallback {
    self.fileURLs = [self.helper generateFileURLs:2];

    NSMutableDictionary *expectedStatus = [NSMutableDictionary new];
    NSString *urlString1 = [self.fileURLs[0] absoluteString];
    NSString *urlString2 = [self.fileURLs[1] absoluteString];
    expectedStatus[urlString1] = @1;
    expectedStatus[urlString2] = @1;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download files callback"];
    
    // Assert
    void (^completionBlock)(NSDictionary<NSString *,id> * _Nullable) = ^(NSDictionary<NSString *,id> * _Nullable status) {
        XCTAssertEqualObjects(status, expectedStatus);
        [expectation fulfill];
    };
    
    // Download files
    [self.fileDownloadManager downloadFiles:self.fileURLs withCompletionBlock:completionBlock];
    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testFileAlreadyDownloaded {
    self.fileURLs = [self.helper generateFileURLs:5];
    NSArray<NSURL *> *urls = @[self.fileURLs[0], self.fileURLs[1]];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Download files callback"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Download already present files callback"];

    // Download 5 files
    [self.fileDownloadManager downloadFiles:self.fileURLs withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {

        // Assert files are already downloaded
        XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:urls[0]]);
        XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:urls[1]]);
        // Call download for 1st and 2nd files again
        [self.fileDownloadManager downloadFiles:urls withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
            [expectation2 fulfill];
        }];
        
        [expectation1 fulfill];
    }];
    
    // Enforce the order
    [self waitForExpectations:@[expectation1, expectation2] timeout:2.0 enforceOrder:YES];
    // Ensure total files downloaded are only 5 (one request for each unique file)
    XCTAssertEqual(5, self.helper.filesDownloaded.count);
    // Ensure 1st and 2nd files are downloaded only once
    XCTAssertTrue([self.helper fileDownloadedCount:urls[0]] == 1);
    XCTAssertTrue([self.helper fileDownloadedCount:urls[1]] == 1);
}

- (void)testDownloadsPending {
    // Generate 5 file URLs
    self.fileURLs = [self.helper generateFileURLs:5];
    NSArray<NSURL *> *urls = @[self.fileURLs[0], self.fileURLs[1]];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Download 1st and 2nd files callback"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Download all files callback"];

    // Download all 5 files
    [self.fileDownloadManager downloadFiles:self.fileURLs withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
        [expectation2 fulfill];
    }];
    
    // Ensure files are not present yet since download is not yet completed
    XCTAssertFalse([self.fileDownloadManager isFileAlreadyPresent:urls[0]]);
    XCTAssertFalse([self.fileDownloadManager isFileAlreadyPresent:urls[1]]);
    // Download the 1st and 2nd files
    [self.fileDownloadManager downloadFiles:urls withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
        [expectation1 fulfill];
    }];
    
    // Ensure the expecation for Download 1st and 2nd files is fulfilled first
    [self waitForExpectations:@[expectation1, expectation2] timeout:2.0 enforceOrder:YES];
    // Ensure total files downloaded are only 5 (one request for each unique file)
    XCTAssertEqual(5, self.helper.filesDownloaded.count);
    // Ensure 1st and 2nd files are downloaded only once
    XCTAssertTrue([self.helper fileDownloadedCount:urls[0]] == 1);
    XCTAssertTrue([self.helper fileDownloadedCount:urls[1]] == 1);
}

- (void)testRequestFailure {
    id<HTTPStubsDescriptor> stub = [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:@"non-existent"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        return [HTTPStubsResponse responseWithData:[NSData data]
                                        statusCode:404
                                           headers:@{@"Content-Type":@"text/plain"}];
    }];

    NSArray *fileURLs = [self.helper generateFileURLs:2];
    NSMutableArray *urls = [fileURLs mutableCopy];
    NSString *nonexistentURLString = @"https://non-existent.com/non-existent.png";
    NSURL *nonexistentURL = [NSURL URLWithString:nonexistentURLString];
    [urls insertObject:nonexistentURL atIndex:0];
    self.fileURLs = urls;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download files callback"];
    [self.fileDownloadManager downloadFiles:self.fileURLs withCompletionBlock:^(NSDictionary<NSString *,id> * _Nonnull status) {
        // Assert the file that returns 404 has error status
        XCTAssertEqualObjects(@0, status[nonexistentURLString]);
        // Assert the files that return 200 has success status
        XCTAssertEqualObjects(@1, status[[urls[1] absoluteString]]);
        XCTAssertEqualObjects(@1, status[[urls[2] absoluteString]]);
        
        // Assert error file not written to disk
        XCTAssertFalse([self.fileDownloadManager isFileAlreadyPresent:nonexistentURL]);
        // Assert files written to disk
        XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:urls[1]]);
        XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:urls[2]]);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:2.0];
    [HTTPStubs removeStub:stub];
}

- (void)testDownloadFilesOneUrlTimeOut {
    // Stub the network request for timeout file to simulate a Timed Out Error
    id<HTTPStubsDescriptor> stub = [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:@"timeout"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        // Return Timed Out Error and delay the response time with 0.1s
        return [[HTTPStubsResponse responseWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                                         code:NSURLErrorTimedOut
                                                                     userInfo:nil]]
                responseTime:0.1];
    }];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Download files callback"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Download files with 1 file timed out callback"];

    NSArray *fileURLs = [self.helper generateFileURLs:2];
    NSMutableArray *fileURLsWithTimedOutURL = [fileURLs mutableCopy];
    [fileURLsWithTimedOutURL insertObject:[NSURL URLWithString:@"https://timeout.com/timeout.png"] atIndex:0];
    self.fileURLs = fileURLsWithTimedOutURL;
    
    // Download files where 1st file will time out
    [self.fileDownloadManager downloadFiles:fileURLsWithTimedOutURL withCompletionBlock:^(NSDictionary<NSString *,id> * _Nonnull status) {
        XCTAssertEqualObjects(@0, status[[fileURLsWithTimedOutURL[0] absoluteString]]);
        XCTAssertEqualObjects(@1, status[[fileURLsWithTimedOutURL[1] absoluteString]]);
        XCTAssertEqualObjects(@1, status[[fileURLsWithTimedOutURL[2] absoluteString]]);
        [expectation2 fulfill];
    }];
    
    // Download files
    // Ensure the downloadFiles does not wait for the first call to complete
    [self.fileDownloadManager downloadFiles:fileURLs withCompletionBlock:^(NSDictionary<NSString *,id> * _Nonnull status) {
        XCTAssertEqualObjects(@1, status[[fileURLs[0] absoluteString]]);
        XCTAssertEqualObjects(@1, status[[fileURLs[1] absoluteString]]);
        [expectation1 fulfill];
    }];
    
    // Ensure 2nd downloadFiles callback does not wait on the 1st
    // Ensure the expecation for successful download is called first
    [self waitForExpectations:@[expectation1, expectation2] timeout:2.0 enforceOrder:YES];
    [HTTPStubs removeStub:stub];
}

- (void)testSemaphoreTimeout {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Semaphore Timeout Test"];
    // Generate URLs more than the max concurrency count CLTAP_FILE_MAX_CONCURRENCY_COUNT
    self.fileURLs = [self.helper generateFileURLs:15];

    // Set mock session
    NSURLSessionMock *mockSession = [[NSURLSessionMock alloc] init];
    mockSession.delayInterval = 0.3; // Simulate a delay longer than semaphore timeout
    self.fileDownloadManager.semaphoreTimeout = 0.1;
    self.fileDownloadManager.session = mockSession;
    
    [self.fileDownloadManager downloadFiles:self.fileURLs withCompletionBlock:^(NSDictionary<NSString *,NSNumber *> * _Nonnull fileDownloadStatus) {
        for (NSURL *url in self.fileURLs) {
            NSNumber *status = fileDownloadStatus[url.absoluteString];
            XCTAssertNotNil(status, @"File download status should not be nil.");
            XCTAssertEqual([status integerValue], 0, @"File download should fail due to semaphore timeout.");
        }
        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testDownloadSingle {
    self.fileURLs = [self.helper generateFileURLs:1];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Download files callback 1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Download files callback 2"];

    // downloadSingleFile directly downloads the file
    [self.fileDownloadManager downloadSingleFile:self.fileURLs[0] completed:^(BOOL success) {
        XCTAssertTrue(success);
        [expectation1 fulfill];
    }];
    [self.fileDownloadManager downloadSingleFile:self.fileURLs[0] completed:^(BOOL success) {
        XCTAssertTrue(success);
        [expectation2 fulfill];
    }];
    
    [self waitForExpectations:@[expectation1, expectation2] timeout:2.0];
    // Expected file requests to equal the calls to downloadSingleFile
    XCTAssertTrue([self.helper fileDownloadedCount:self.fileURLs[0]] == 2);
}

- (void)testDownloadSingleSameURLComponentDifferentHost {
    NSURL *url1 = [NSURL URLWithString:[NSString stringWithFormat:@"https://clevertap.com/%@.png", self.helper.fileURL]];
    NSURL *url2 = [NSURL URLWithString:[NSString stringWithFormat:@"https://clevertap-1.com/%@.png", self.helper.fileURL]];
    self.fileURLs = @[url1, url2];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Download files callback 1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Download files callback 2"];

    // Expect to download and save two different files
    [self.fileDownloadManager downloadSingleFile:url1 completed:^(BOOL success) {
        XCTAssertTrue(success);
        XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:url1]);
        [expectation1 fulfill];
    }];
    [self.fileDownloadManager downloadSingleFile:url2 completed:^(BOOL success) {
        XCTAssertTrue(success);
        XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:url2]);
        [expectation2 fulfill];
    }];
    
    [self waitForExpectations:@[expectation1, expectation2] timeout:2.0];
    // Expected file requests to equal the calls to downloadSingleFile
    XCTAssertEqual(2, self.helper.filesDownloaded.count);
    XCTAssertNotEqualObjects([self.fileDownloadManager filePath:url1], [self.fileDownloadManager filePath:url2]);
}

- (void)testDownloadSingleOverwriteFile {
    NSURL *url = [self.helper generateFileURL];
    self.fileURLs = @[url];
    
    __block NSDate *firstFileCreationDate;
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Download file callback"];
    // Download file
    [self.fileDownloadManager downloadSingleFile:url completed:^(BOOL success) {
        XCTAssertTrue(success);
        XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:url]);
        
        // Set the 1st file creation date
        NSDictionary* fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[self.fileDownloadManager filePath:url] error:nil];
        firstFileCreationDate = [fileAttributes objectForKey:NSFileCreationDate];
        [expectation1 fulfill];
    }];

    __block NSDate *secondFileCreationDate;
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Download file again callback"];
    // Download the file again. Since the file exists, it should be deleted and then saved.
    [self.fileDownloadManager downloadSingleFile:url completed:^(BOOL success) {
        XCTAssertTrue(success);
        XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:url]);
        
        // Set the 2nd file creation date
        NSDictionary* fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[self.fileDownloadManager filePath:url] error:nil];
        secondFileCreationDate = [fileAttributes objectForKey:NSFileCreationDate];
        [expectation2 fulfill];
    }];
    
    [self waitForExpectations:@[expectation1, expectation2] timeout:2.0];
    // Ensure the file is overwritten by comparing the created dates
    XCTAssertNotEqualObjects(firstFileCreationDate, secondFileCreationDate);
}

- (void)testDownloadSingleFileWithCreateDirectoryError {
    NSFileManager *originalFileManager = self.fileDownloadManager.fileManager;
    NSFileManagerMock *fileManagerMock = [[NSFileManagerMock alloc] init];
    self.fileDownloadManager.fileManager = fileManagerMock;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion block called"];

    NSURL *URL = [self.helper generateFileURL];
    fileManagerMock.createDirectoryError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteNoPermissionError userInfo:nil];

    [self.fileDownloadManager downloadSingleFile:URL completed:^(BOOL success) {
        XCTAssertFalse(success);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    self.fileDownloadManager.fileManager = originalFileManager;
}

- (void)testDownloadSingleFileWithFileRemoveError {
    NSFileManager *originalFileManager = self.fileDownloadManager.fileManager;
    NSFileManagerMock *fileManagerMock = [[NSFileManagerMock alloc] init];
    self.fileDownloadManager.fileManager = fileManagerMock;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion block called"];

    NSURL *URL = [self.helper generateFileURL];
    fileManagerMock.fileExists = YES;
    fileManagerMock.removeItemError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteNoPermissionError userInfo:nil];

    [self.fileDownloadManager downloadSingleFile:URL completed:^(BOOL success) {
        XCTAssertFalse(success);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    self.fileDownloadManager.fileManager = originalFileManager;
}

- (void)testDownloadSingleFileWithFileMoveError {
    NSFileManager *originalFileManager = self.fileDownloadManager.fileManager;
    NSFileManagerMock *fileManagerMock = [[NSFileManagerMock alloc] init];
    self.fileDownloadManager.fileManager = fileManagerMock;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion block called"];

    NSURL *URL = [self.helper generateFileURL];
    fileManagerMock.moveItemError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteNoPermissionError userInfo:nil];

    [self.fileDownloadManager downloadSingleFile:URL completed:^(BOOL success) {
        XCTAssertFalse(success);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    self.fileDownloadManager.fileManager = originalFileManager;
}

- (void)testTimeoutConfiguration {
    NSURLSessionConfiguration *configuration = self.fileDownloadManager.session.configuration;
    XCTAssertEqual(configuration.timeoutIntervalForRequest, CLTAP_REQUEST_TIME_OUT_INTERVAL);
    XCTAssertEqual(configuration.timeoutIntervalForResource, CLTAP_FILE_RESOURCE_TIME_OUT_INTERVAL);
}

- (void)testDownloadSingle404 {
    // Stub the network request to simulate a 404 Not Found error
    id<HTTPStubsDescriptor> stub = [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:self.helper.fileURL];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
            return [HTTPStubsResponse responseWithData:[NSData data]
                                            statusCode:404
                                               headers:@{@"Content-Type":@"text/plain"}];
    }];
    
    NSURL *url = [self.helper generateFileURL];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download files callback"];
    [self.fileDownloadManager downloadSingleFile:url completed:^(BOOL success) {
        XCTAssertFalse(success);
        XCTAssertFalse([self.fileDownloadManager isFileAlreadyPresent:url]);
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:2.0];
    [HTTPStubs removeStub:stub];
}

- (void)testDownloadSingleHostNotFound {
    id<HTTPStubsDescriptor> stub = [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:self.helper.fileURL];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        return [HTTPStubsResponse responseWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotFindHost userInfo:nil]];
    }];
    
    NSURL *url = [self.helper generateFileURL];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download files callback"];
    [self.fileDownloadManager downloadSingleFile:url completed:^(BOOL success) {
        XCTAssertFalse(success);
        XCTAssertFalse([self.fileDownloadManager isFileAlreadyPresent:url]);
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:2.0];
    [HTTPStubs removeStub:stub];
}

- (void)testRemoveAllFiles {
    [self downloadFiles:3];
    NSMutableArray *paths = [NSMutableArray array];
    for (int i = 0; i < 3; i++) {
        XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[i]]);
        [paths addObject:[self.fileDownloadManager filePath:self.fileURLs[i]]];
    }
    XCTestExpectation *expectation = [self expectationWithDescription:@"Remove all files callback"];
    [self.fileDownloadManager removeAllFilesWithCompletionBlock:^(NSDictionary<NSString *,NSNumber *> * _Nonnull status) {
        for (int i = 0; i < 3; i++) {
            XCTAssertTrue(status[paths[i]]);
            XCTAssertFalse([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[i]]);
        }
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testRemoveAllFilesContentsOfDirectoryError {
    NSFileManager *originalFileManager = self.fileDownloadManager.fileManager;
    NSFileManagerMock *fileManagerMock = [[NSFileManagerMock alloc] init];
    self.fileDownloadManager.fileManager = fileManagerMock;
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion block called"];
    
    fileManagerMock.contentsOfDirectoryError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteNoPermissionError userInfo:nil];
    [self.fileDownloadManager removeAllFilesWithCompletionBlock:^(NSDictionary<NSString *,NSNumber *> * _Nonnull status) {
        XCTAssertTrue(status.count == 0);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    self.fileDownloadManager.fileManager = originalFileManager;
}

- (void)testRemoveAllFilesRemoveFileError {
    [self downloadFiles:3];
    NSMutableArray *paths = [NSMutableArray array];
    for (int i = 0; i < 3; i++) {
        XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[i]]);
        [paths addObject:[self.fileDownloadManager filePath:self.fileURLs[i]]];
    }
    
    NSFileManager *originalFileManager = self.fileDownloadManager.fileManager;
    NSFileManagerMock *fileManagerMock = [[NSFileManagerMock alloc] init];
    self.fileDownloadManager.fileManager = fileManagerMock;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Remove all files callback"];
    fileManagerMock.removeItemError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteNoPermissionError userInfo:nil];
    [self.fileDownloadManager removeAllFilesWithCompletionBlock:^(NSDictionary<NSString *,NSNumber *> * _Nonnull status) {
        self.fileDownloadManager.fileManager = originalFileManager;
        for (int i = 0; i < 3; i++) {
            XCTAssertEqualObjects(@0, status[paths[i]]);
            XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[i]]);
        }
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:2.0];
}

#pragma mark Private methods

- (void)downloadFiles {
    [self downloadFiles:3];
}

- (void)downloadFiles:(int)count {
    self.fileURLs = [self.helper generateFileURLs:count];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download files"];
    
    [self.fileDownloadManager downloadFiles:self.fileURLs withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)deleteFiles:(NSArray<NSURL *> *)urls {
    NSMutableArray<NSString *> *deleteFileURLs = [NSMutableArray new];
    for(int i = 0; i < urls.count; i++) {
        NSString *fileURL = [urls[i] absoluteString];
        [deleteFileURLs addObject:fileURL];
    }
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delete files"];
    [self.fileDownloadManager deleteFiles:deleteFileURLs withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:2.0];
}

@end

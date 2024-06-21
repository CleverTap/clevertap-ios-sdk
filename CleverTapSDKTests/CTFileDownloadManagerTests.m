#import <XCTest/XCTest.h>
#import <OHHTTPStubs/HTTPStubs.h>
#import "CleverTapInstanceConfig.h"
#import "CTFileDownloadManager.h"
#import "CTConstants.h"

NSString *const fileURLMatch = @"ct_test_url";
NSString *const fileURLTypes[] = {@"txt", @"pdf", @"png"};

@interface CTFileDownloadManager(Tests)

- (void)downloadSingleFile:(NSURL *)url
completed:(void(^)(BOOL success))completedBlock;

- (void)deleteSingleFile:(NSURL *)url
               completed:(void(^)(BOOL success))completedBlock;

@end

@interface CTFileDownloadManagerTests : XCTestCase

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTFileDownloadManager *fileDownloadManager;
@property (nonatomic, strong) NSString *documentsDirectory;
@property (nonatomic, strong) NSArray<NSURL *> *fileURLs;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *filesDownloaded;

@end

@implementation CTFileDownloadManagerTests

- (void)setUp {
    [super setUp];
    self.filesDownloaded = [NSMutableDictionary new];
    [self addAllStubs];
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccountId" accountToken:@"testAccountToken"];
    self.fileDownloadManager = [CTFileDownloadManager sharedInstanceWithConfig:self.config];
    self.documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

- (void)tearDown {
    [super tearDown];
    
    [HTTPStubs removeAllStubs];
    [self deleteFiles:self.fileURLs];
}

- (void)testFilesExist {
    [self downloadFiles];
    
    for(int i = 0; i < [self.fileURLs count]; i++) {
        NSString* filePath = [self.documentsDirectory stringByAppendingPathComponent:[self.fileURLs[i] lastPathComponent]];
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:filePath]);
    }
}

- (void)testIsFileAlreadyPresent {
    [self downloadFiles];

    for(int i = 0; i < [self.fileURLs count]; i++) {
        XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[i]]);
    }
}

- (void)testDeleteFiles {
    [self downloadFiles];

    NSArray *urls = [self generateFileURLs:2];
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
        XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[2]]);

        NSString *fileURL = [self.fileURLs[i] absoluteString];
        [deleteFileURLs addObject:fileURL];
    }
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delete files"];
    [self.fileDownloadManager deleteFiles:deleteFileURLs withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
        for (NSString *url in deleteFileURLs) {
            XCTAssertEqual(YES, [status[url] boolValue]);
            XCTAssertFalse([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[0]]);
        }
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testNotExistDeleteFiles {
    NSArray *urls = [self generateFileURLs:2];
    NSMutableArray<NSString *> *deleteFileURLs = [NSMutableArray new];
    for(int i = 0; i < urls.count; i++) {
        NSString *fileURL = [urls[i] absoluteString];
        [deleteFileURLs addObject:fileURL];
    }
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delete files"];
    [self.fileDownloadManager deleteFiles:deleteFileURLs withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
        for (NSString *url in deleteFileURLs) {
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
    NSURL *urlNoLastComponent = [NSURL URLWithString:@"https://no-component.png"];
    [self.fileDownloadManager deleteSingleFile:urlNoLastComponent completed:^(BOOL success) {
        XCTAssertEqual(NO, success);
        [expectationNoLastComponent fulfill];
    }];
    
    [self waitForExpectations:@[expectationNil, expectationEmpty, expectationNoLastComponent] timeout:2.0];
}

#pragma mark CTFileDownload callback test

- (void)testAllFilesDownloadedCallback {
    self.fileURLs = [self generateFileURLs:2];

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
    NSArray<NSURL *> *urls = [self generateFileURLs:2];
    self.fileURLs = [self generateFileURLs:5];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Download files callback 1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Download files callback 2"];

    [self.fileDownloadManager downloadFiles:self.fileURLs withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
        [expectation1 fulfill];
        XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:urls[0]]);
        XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:urls[1]]);
        [self.fileDownloadManager downloadFiles:urls withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
            [expectation2 fulfill];
        }];
    }];
    
    [self waitForExpectations:@[expectation1, expectation2] timeout:2.0 enforceOrder:YES];
    XCTAssertEqual(5, self.filesDownloaded.count);
    XCTAssertTrue([self.filesDownloaded[urls[0].absoluteString] intValue] == 1);
    XCTAssertTrue([self.filesDownloaded[urls[1].absoluteString] intValue] == 1);
}

- (void)testDownloadsPending {
    NSArray<NSURL *> *urls = [self generateFileURLs:2];
    self.fileURLs = [self generateFileURLs:5];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Download files callback 1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Download files callback 2"];

    [self.fileDownloadManager downloadFiles:self.fileURLs withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
        [expectation2 fulfill];
    }];
    
    XCTAssertFalse([self.fileDownloadManager isFileAlreadyPresent:urls[0]]);
    XCTAssertFalse([self.fileDownloadManager isFileAlreadyPresent:urls[1]]);
    [self.fileDownloadManager downloadFiles:urls withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
        [expectation1 fulfill];
    }];
    
    [self waitForExpectations:@[expectation1, expectation2] timeout:2.0 enforceOrder:YES];
    XCTAssertEqual(5, self.filesDownloaded.count);
    XCTAssertTrue([self.filesDownloaded[urls[0].absoluteString] intValue] == 1);
    XCTAssertTrue([self.filesDownloaded[urls[1].absoluteString] intValue] == 1);
}

- (void)testRequestFailure {
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:@"non-existent"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        return [HTTPStubsResponse responseWithData:[NSData data]
                                        statusCode:404
                                           headers:@{@"Content-Type":@"text/plain"}];
    }];

    NSArray *fileURLs = [self generateFileURLs:2];
    NSMutableArray *urls = [fileURLs mutableCopy];
    NSString *nonexistentUrl = @"https://non-existent.com/non-existent.png";
    [urls insertObject:[NSURL URLWithString:nonexistentUrl] atIndex:0];
    self.fileURLs = urls;
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download files callback"];
    [self.fileDownloadManager downloadFiles:self.fileURLs withCompletionBlock:^(NSDictionary<NSString *,id> * _Nonnull status) {
        XCTAssertEqualObjects(@0, status[nonexistentUrl]);
        XCTAssertEqualObjects(@1, status[[urls[1] absoluteString]]);
        XCTAssertEqualObjects(@1, status[[urls[2] absoluteString]]);
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testDownloadFilesOneUrlTimeOut {
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:@"timeout"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        return [[HTTPStubsResponse responseWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                                         code:NSURLErrorTimedOut
                                                                     userInfo:nil]]
                responseTime:0.1];
    }];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Download files callback 1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Download files callback 2"];

    NSArray *fileURLs = [self generateFileURLs:2];
    NSMutableArray *urls = [fileURLs mutableCopy];
    [urls insertObject:[NSURL URLWithString:@"https://timeout.com/timeout.png"] atIndex:0];
    self.fileURLs = urls;
    
    [self.fileDownloadManager downloadFiles:urls withCompletionBlock:^(NSDictionary<NSString *,id> * _Nonnull status) {
        XCTAssertEqualObjects(@0, status[[urls[0] absoluteString]]);
        XCTAssertEqualObjects(@1, status[[urls[1] absoluteString]]);
        XCTAssertEqualObjects(@1, status[[urls[2] absoluteString]]);
        [expectation2 fulfill];
    }];
    
    [self.fileDownloadManager downloadFiles:fileURLs withCompletionBlock:^(NSDictionary<NSString *,id> * _Nonnull status) {
        XCTAssertEqualObjects(@1, status[[fileURLs[0] absoluteString]]);
        XCTAssertEqualObjects(@1, status[[fileURLs[1] absoluteString]]);
        [expectation1 fulfill];
    }];
    
    [self waitForExpectations:@[expectation1, expectation2] timeout:2.0 enforceOrder:YES];
}

- (void)testDownloadSingle {
    self.fileURLs = [self generateFileURLs:1];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Download files callback 1"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Download files callback 2"];

    // downloadSingleFile directly downloads the file
    [self.fileDownloadManager downloadSingleFile:self.fileURLs[0] completed:^(BOOL success) {
        [expectation1 fulfill];
    }];
    [self.fileDownloadManager downloadSingleFile:self.fileURLs[0] completed:^(BOOL success) {
        [expectation2 fulfill];
    }];
    
    [self waitForExpectations:@[expectation1, expectation2] timeout:2.0];
    XCTAssertTrue([self.filesDownloaded[self.fileURLs[0].absoluteString] intValue] == 2);
}

- (void)testDownloadSingle404 {
    // Stub the network request to simulate a 404 Not Found error
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:fileURLMatch];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
            return [HTTPStubsResponse responseWithData:[NSData data]
                                            statusCode:404
                                               headers:@{@"Content-Type":@"text/plain"}];
    }];
    
    NSURL *url = [self generateFileURLs:1][0];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download files callback"];
    [self.fileDownloadManager downloadSingleFile:url completed:^(BOOL success) {
        XCTAssertFalse(success);
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testDownloadSingleHostNotFound {
    // Stub the network request to simulate a 404 Not Found error
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:fileURLMatch];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        return [HTTPStubsResponse responseWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotFindHost userInfo:nil]];
    }];
    
    NSURL *url = [self generateFileURLs:1][0];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download files callback"];
    [self.fileDownloadManager downloadSingleFile:url completed:^(BOOL success) {
        XCTAssertFalse(success);
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:2.0];
}

#pragma mark Private methods

- (void)addAllStubs {
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:fileURLMatch];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        NSString *fileString = [request.URL absoluteString];
        NSString *fileType = [fileString pathExtension];
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        
        NSNumber *count = self.filesDownloaded[fileString];
        if (count) {
            int value = [count intValue];
            count = [NSNumber numberWithInt:value + 1];
            self.filesDownloaded[fileString] = count;
        } else {
            self.filesDownloaded[fileString] = @1;
        }
        
        if ([fileType isEqualToString:@"txt"]) {
            return [HTTPStubsResponse responseWithFileAtPath:[bundle pathForResource:@"sampleTXTStub" ofType:@"txt"]
                                                  statusCode:200
                                                     headers:nil];
        } else if ([fileType isEqualToString:@"pdf"]) {
            return [HTTPStubsResponse responseWithFileAtPath:[bundle pathForResource:@"samplePDFStub" ofType:@"pdf"]
                                                  statusCode:200
                                                     headers:nil];
        } else {
            return [HTTPStubsResponse responseWithFileAtPath:[bundle pathForResource:@"clevertap-logo" ofType:@"png"]
                                                  statusCode:200
                                                     headers:nil];
        }
    }];
}

- (NSArray<NSURL *> *)generateFileURLs:(int)count {
    NSMutableArray *arr = [NSMutableArray new];
    for (int i = 0; i < count; i++) {
        int type = i >= 3 ? i % 3 : i;
        NSString *urlString = [[NSString alloc] initWithFormat:@"https://clevertap.com/%@_%d.%@", fileURLMatch, i, fileURLTypes[type]];
        [arr addObject:[NSURL URLWithString:urlString]];
    }
    return arr;
}

- (void)downloadFiles {
    [self downloadFiles:3];
}

- (void)downloadFiles:(int)count {
    self.fileURLs = [self generateFileURLs:count];
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

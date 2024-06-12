#import <XCTest/XCTest.h>
#import "CleverTapInstanceConfig.h"
#import "CTFileDownloadManager.h"
#import <OHHTTPStubs/HTTPStubs.h>

NSString *const fileURLMatch = @"ct_test_url";
NSString *const fileURLTypes[] = {@"txt", @"pdf", @"png"};

@interface CTFileDownloadManagerTests : XCTestCase
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTFileDownloadManager *fileDownloadManager;
@property (nonatomic, strong) NSString *documentsDirectory;
@property (nonatomic, strong) NSArray *fileURLs;
@end

@implementation CTFileDownloadManagerTests

- (void)setUp {
    [super setUp];
    [self addAllStubs];
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccountId" accountToken:@"testAccountToken"];
    self.fileDownloadManager = [CTFileDownloadManager sharedInstanceWithConfig:self.config];
    self.documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

- (void)tearDown {
    [super tearDown];
    
    [HTTPStubs removeAllStubs];
    // Remove files after every testcase
    [self deleteFiles:(int)[self.fileURLs count]];
}

- (void)testDownloadMultipleFiles {
    [self downloadFiles];

    for(int i=0; i<[self.fileURLs count]; i++) {
        NSString* filePath = [self.documentsDirectory stringByAppendingPathComponent:[self.fileURLs[i] lastPathComponent]];
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:filePath]);
    }
}

- (void)testIsFileAlreadyPresent {
    [self downloadFiles];

    for(int i=0; i<[self.fileURLs count]; i++) {
        XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[i]]);
    }
}

- (void)testDeleteFiles {
    [self downloadFiles];

    [self deleteFiles:2];

    // Deleted 1st and 2nd file url.
    XCTAssertFalse([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[0]]);
    XCTAssertFalse([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[1]]);
    XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[2]]);
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
    };
    
    // Download files
    [self.fileDownloadManager downloadFiles:self.fileURLs withCompletionBlock:completionBlock];
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        [expectation fulfill];
    });
    
    [self waitForExpectations:@[expectation] timeout:2.5];
}

#pragma mark Private methods

- (void)addAllStubs {
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:fileURLMatch];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        NSString *fileString = [request.URL absoluteString];
        NSString *fileType = [fileString pathExtension];
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
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
        NSString *urlString = [[NSString alloc] initWithFormat:@"https://clevertap.com/%@.%@",fileURLMatch, fileURLTypes[i]];
        [arr addObject:[NSURL URLWithString:urlString]];
    }
    return arr;
}

- (void)downloadFiles {
    self.fileURLs = [self generateFileURLs:3];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download files"];
    
    [self.fileDownloadManager downloadFiles:self.fileURLs withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
//        NSLog(@"All files downloaded with status: %@", status);
    }];
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        [expectation fulfill];
    });
    
    [self waitForExpectations:@[expectation] timeout:2.5];
}

- (void)deleteFiles:(int)count {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Delete files"];
    
    NSMutableArray<NSString *> *deleteFileURLs = [NSMutableArray new];
    for(int i=0;i<count;i++) {
        NSString *fileURL = [self.fileURLs[i] absoluteString];
        [deleteFileURLs addObject:fileURL];
    }
    [self.fileDownloadManager deleteFiles:deleteFileURLs withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
//        NSLog(@"All files deleted with status: %@", status);
    }];
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        [expectation fulfill];
    });
    
    [self waitForExpectations:@[expectation] timeout:2.5];
}

@end

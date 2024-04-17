#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "CleverTapInstanceConfig.h"
#import "CTFileDownloadManager.h"

NSString *const CLTAP_TEST_PDF_FILE = @"https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf";
NSString *const CLTAP_TEST_TXT_FILE = @"https://www.w3.org/TR/2003/REC-PNG-20031110/iso_8859-1.txt";
NSString *const CLTAP_TEST_JPG_FILE = @"https://file-examples.com/storage/fef545ae0b661d470abe676/2017/10/file_example_JPG_100kB.jpg";

@interface CTFileDownloadManagerTests : XCTestCase
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTFileDownloadManager *fileDownloadManager;
@property (nonatomic, strong) NSString *documentsDirectory;
@property (nonatomic, strong) NSArray *fileURLs;
@end

@implementation CTFileDownloadManagerTests

- (void)setUp {
    [super setUp];
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccountId" accountToken:@"testAccountToken"];
    self.fileDownloadManager = [[CTFileDownloadManager alloc] initWithConfig:self.config];
    self.documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    [self addSampleFilesURL];
}

- (void)tearDown {
    [super tearDown];
    
    // Remove files after every testcase
    [self removeFiles];
}

- (void)addSampleFilesURL {
    NSURL *url1 = [NSURL URLWithString:CLTAP_TEST_PDF_FILE];
    NSURL *url2 = [NSURL URLWithString:CLTAP_TEST_TXT_FILE];
    NSURL *url3 = [NSURL URLWithString:CLTAP_TEST_JPG_FILE];
    self.fileURLs = @[url1, url2, url3];
}

- (void)downloadFiles {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download files"];
    
    [self.fileDownloadManager downloadFiles:self.fileURLs];
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        [expectation fulfill];
    });
    
    [self waitForExpectations:@[expectation] timeout:2.5];
}

- (void)removeFiles {
    for(int i=0; i<[self.fileURLs count]; i++) {
        NSString *filePath = [self.documentsDirectory stringByAppendingPathComponent:[self.fileURLs[i] lastPathComponent]];
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    }
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

- (void)testDeleteFile {
    [self downloadFiles];

    [self.fileDownloadManager deleteFile:self.fileURLs[0]];
    // Deleted only 1st file url.
    XCTAssertFalse([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[0]]);
    XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[1]]);
    XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[2]]);
}

#pragma mark CTFileDownloadDelegate callback tests

- (void)testSingleFileDownloadedCallback {
    id protocolMock = OCMProtocolMock(@protocol(CTFileDownloadDelegate));
    self.fileDownloadManager.delegate = protocolMock;
    
    // Expect singleFileDownloaded is called for file url.
    OCMExpect([protocolMock singleFileDownloaded:YES forURL:CLTAP_TEST_PDF_FILE]);
    
    // Download files.
    NSURL *url1 = [NSURL URLWithString:CLTAP_TEST_PDF_FILE];
    NSArray *arr = @[url1];
    [self.fileDownloadManager downloadFiles:arr];

    // Verify protocol methods is called
    OCMVerifyAllWithDelay(protocolMock, 2.0);
}

- (void)testAllFilesDownloadedCallback {
    id protocolMock = OCMProtocolMock(@protocol(CTFileDownloadDelegate));
    self.fileDownloadManager.delegate = protocolMock;
    
    NSMutableDictionary *status = [NSMutableDictionary new];
    status[CLTAP_TEST_PDF_FILE] = @1;
    status[CLTAP_TEST_TXT_FILE] = @1;
    
    // Expect allFilesDownloaded method is called with status dictionary.
    OCMExpect([protocolMock allFilesDownloaded:status]);
    
    // Download files
    NSURL *url1 = [NSURL URLWithString:CLTAP_TEST_PDF_FILE];
    NSURL *url2 = [NSURL URLWithString:CLTAP_TEST_TXT_FILE];
    NSArray *arr = @[url1, url2];
    [self.fileDownloadManager downloadFiles:arr];

    // Verify protocol methods is called
    OCMVerifyAllWithDelay(protocolMock, 2.0);
}

@end

#import <XCTest/XCTest.h>
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
    // Download files before every testcase
    [self downloadFiles];
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
    for(int i=0; i<[self.fileURLs count]; i++) {
        NSString* filePath = [self.documentsDirectory stringByAppendingPathComponent:[self.fileURLs[i] lastPathComponent]];
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:filePath]);
    }
}

- (void)testIsFileAlreadyPresent {
    for(int i=0; i<[self.fileURLs count]; i++) {
        XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[i]]);
    }
}

- (void)testDeleteFile {
    [self.fileDownloadManager deleteFile:self.fileURLs[0]];
    // Deleted only 1st file url.
    XCTAssertFalse([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[0]]);
    XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[1]]);
    XCTAssertTrue([self.fileDownloadManager isFileAlreadyPresent:self.fileURLs[2]]);
}

@end

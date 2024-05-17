#import <XCTest/XCTest.h>
#import <OHHTTPStubs/HTTPStubs.h>
#import "CTPreferences.h"
#import "CTConstants.h"
#import "CTFileDownloader.h"

NSString *const fileURL = @"ct_test_url";
NSString *const fileTypes[] = {@"txt", @"pdf", @"png"};

@interface CTFileDownloaderTests : XCTestCase
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTFileDownloader *fileDownloader;
@property (nonatomic, strong) NSArray *fileURLs;
@end

@implementation CTFileDownloaderTests

- (void)setUp {
    [super setUp];
    [self addAllStubs];
    self.config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccountId" accountToken:@"testAccountToken"];
    self.fileDownloader = [[CTFileDownloader alloc] initWithConfig:self.config];
}

- (void)tearDown {
    [super tearDown];
    
    [HTTPStubs removeAllStubs];
    [self.fileDownloader clearFileAssets:false];
    [CTPreferences removeObjectForKey:[self storageKeyWithSuffix:CLTAP_FILE_ACTIVE_DICT]];
    [CTPreferences removeObjectForKey:[self storageKeyWithSuffix:CLTAP_FILE_INACTIVE_DICT]];
    [CTPreferences removeObjectForKey:[self storageKeyWithSuffix:CLTAP_FILE_ASSETS_LAST_DELETED_TS]];
}

- (void)testFileAlreadyPresent {
    NSArray *urls = [self generateFileURLs:2];
    XCTAssertFalse([self.fileDownloader isFileAlreadyPresent:urls[0]]);
    XCTAssertFalse([self.fileDownloader isFileAlreadyPresent:urls[1]]);

    [self downloadFiles:@[urls[0]] ofType:CTInAppClientSide];

    XCTAssertTrue([self.fileDownloader isFileAlreadyPresent:urls[0]]);
    XCTAssertFalse([self.fileDownloader isFileAlreadyPresent:urls[1]]);
}

- (void)testDownloadMultipleFiles {
    NSArray *urls = [self generateFileURLs:3];
    NSMutableDictionary *activeUrls, *inactiveUrls;

    // 1. Test Download files add to active dict.
    // All 3 urls are downloaded.
    [self downloadFiles:@[urls[1]] ofType:CTInAppClientSide];   // CTInAppClientSide = 0
    [self downloadFiles:@[urls[0], urls[1], urls[2]] ofType:CTInAppCustomTemplate];     // CTInAppCustomTemplate = 1
    [self downloadFiles:@[urls[2]] ofType:CTFileVariables];    // CTFileVariables = 2
    
    activeUrls = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_FILE_ACTIVE_DICT]];
    inactiveUrls = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_FILE_INACTIVE_DICT]];
    NSDictionary *expectedDict = @{
        urls[0] : @[@1],
        urls[1] : @[@0, @1],
        urls[2] : @[@1, @2]
    };
    XCTAssertTrue([self.fileDownloader isFileAlreadyPresent:urls[0]]);
    XCTAssertTrue([self.fileDownloader isFileAlreadyPresent:urls[1]]);
    XCTAssertTrue([self.fileDownloader isFileAlreadyPresent:urls[2]]);
    XCTAssertEqual([activeUrls count], 3);
    XCTAssertEqual([inactiveUrls count], 0);
    XCTAssertEqualObjects(activeUrls, expectedDict);
    
    // 2. Test Active dict are moved to inactive when expiration time has come
    [self setLastDeletedPastExpiry];
    [self downloadFiles:@[urls[1]] ofType:CTFileVariables];
    activeUrls = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_FILE_ACTIVE_DICT]];
    inactiveUrls = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_FILE_INACTIVE_DICT]];
    XCTAssertEqual([activeUrls count], 0);
    XCTAssertEqual([inactiveUrls count], 3);

    // 3. Test Inactive asset is removed when next expiration has come
    // Here urls[0] and urls[1] will be removed from cacahe.
    [self setLastDeletedPastExpiry];
    [self downloadFiles:@[urls[2]] ofType:CTFileVariables];
    activeUrls = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_FILE_ACTIVE_DICT]];
    inactiveUrls = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_FILE_INACTIVE_DICT]];
    XCTAssertFalse([self.fileDownloader isFileAlreadyPresent:urls[0]]);
    XCTAssertFalse([self.fileDownloader isFileAlreadyPresent:urls[1]]);
    XCTAssertTrue([self.fileDownloader isFileAlreadyPresent:urls[2]]);
    XCTAssertEqual([activeUrls count], 0);
    XCTAssertEqual([inactiveUrls count], 1);
}

- (void)testGetFileDownloadPath {
    NSArray *urls = [self generateFileURLs:1];
    [self downloadFiles:urls ofType:CTInAppClientSide];
    NSString *filePath = [self.fileDownloader getFileDownloadPath:urls[0]];

    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *expectedFilePath = [documentsPath stringByAppendingPathComponent:[urls[0] lastPathComponent]];
    XCTAssertNotNil(filePath);
    XCTAssertEqualObjects(filePath, expectedFilePath);
}

#pragma mark Private methods

- (void)addAllStubs {
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:fileURL];
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

- (void)downloadFiles:(NSArray *)urls ofType:(CTFileDownloadType)type {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download files"];
    [self.fileDownloader downloadFiles:urls ofType:type withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
//        NSLog(@"All files downloaded with status: %@", status);
    }];
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        [expectation fulfill];
    });
    
    [self waitForExpectations:@[expectation] timeout:2.5];
}

- (void)setLastDeletedPastExpiry {
    // Expiration is 2 weeks
    // Set the last deleted timestamp to 15 days ago
    long ts = (long) [[NSDate date] timeIntervalSince1970] - (60 * 60 * 24 * (2 * 7 + 1));
    [CTPreferences putInt:ts forKey:[self storageKeyWithSuffix:CLTAP_FILE_ASSETS_LAST_DELETED_TS]];
}

- (NSArray<NSString *> *)generateFileURLs:(int)count {
    NSMutableArray *arr = [NSMutableArray new];
    for (int i = 0; i < count; i++) {
        NSString *urlString = [[NSString alloc] initWithFormat:@"https://clevertap.com/%@.%@",fileURL, fileTypes[i]];
        [arr addObject:urlString];
    }
    return arr;
}

- (NSString *)storageKeyWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@", self.config.accountId, suffix];
}

@end

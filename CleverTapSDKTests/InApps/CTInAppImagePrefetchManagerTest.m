#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTInAppImagePrefetchManager.h"
#import "InAppHelper.h"
#import "CTPreferences.h"
#import "CTConstants.h"
#import <OHHTTPStubs/HTTPStubs.h>
#import "CTInAppImagePrefetchManager+Tests.h"

NSString * const imageURLMatch = @"ct_test_image";

NSString * const imageResourcePath = @"clevertap-logo";
NSString * const imageResourceType = @"png";

@interface CTInAppImagePrefetchManagerTest : XCTestCase
@property (nonatomic, strong) CTInAppImagePrefetchManager *prefetchManager;
@end

@implementation CTInAppImagePrefetchManagerTest

- (void)setUp {
    [super setUp];
    InAppHelper *helper = [InAppHelper new];
    self.prefetchManager = helper.imagePrefetchManager;
    
    // Stub the image download request
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        // Match requests with ct_test_image
        return [request.URL.absoluteString containsString:imageURLMatch];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        // Load a local image instead of making the actual request
        NSString *imagePath = [[NSBundle bundleForClass:[self class]] pathForResource:imageResourcePath ofType:imageResourceType];
        NSData *imageData = [NSData dataWithContentsOfFile:imagePath];
        
        return [HTTPStubsResponse responseWithData:imageData statusCode:200 headers:nil];
    }];
}

- (void)tearDown {
    [super tearDown];
    [HTTPStubs removeAllStubs];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for cleanup"];
    [self.prefetchManager _clearImageAssets:NO];
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        [expectation fulfill];
    });
    
    [self waitForExpectations:@[expectation] timeout:2.5];
}

- (void)preloadImagesToDisk:(NSArray *)urls {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Image Preload to Disk Cache"];
    // Preload Images
    [self.prefetchManager prefetchURLs:urls];
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        [expectation fulfill];
    });
    
    [self waitForExpectations:@[expectation] timeout:2.5];
}

- (NSArray *)generateImageURLs:(int)count {
    NSMutableArray *arr = [NSMutableArray new];
    for (int i = 0; i < count; i++) {
        [arr addObject:[[NSString alloc] initWithFormat:@"https://clevertap.com/%@%d.%@",
                        imageURLMatch, i, imageResourceType]];
    }
    return arr;
}

- (void)setLastDeletedPastExpiry {
    // Expiration is 2 weeks
    // Set the last deleted timestamp to 15 days ago
    long now = (long) [[NSDate date] timeIntervalSince1970] - (60 * 60 * 24 * (2 * 7 + 1));
    [CTPreferences putInt:now
                   forKey:[self.prefetchManager storageKeyWithSuffix:CLTAP_PREFS_CS_INAPP_ASSETS_LAST_DELETED_TS]];
}

- (void)testGetImageURLs {
    NSArray *urls = [self generateImageURLs:4];
    NSArray *csInAppNotifs = @[
        @{
            @"media": @{
                @"content_type": @"image/jpeg",
                @"url": urls[0],
            }
        },
        @{
            @"media": @{
                @"content_type": @"image/gif",
                @"url": urls[1],
            }
        },
        @{
            @"mediaLandscape": @{
                @"content_type": @"image/jpeg",
                @"url": urls[2]
            }
        },
        @{
            @"mediaLandscape": @{
                @"content_type": @"image/gif",
                @"url": urls[3]
            }
        }
    ];
    
    NSArray *imageUrls = [self.prefetchManager getImageURLs:csInAppNotifs];
    XCTAssertEqual([imageUrls count], [urls count]);
}

- (void)testImagePresentInDiskCache {
    // Check image is present in disk cache
    NSArray *urls = [self generateImageURLs:1];
    [self preloadImagesToDisk:urls];
    UIImage *image = [self.prefetchManager loadImageFromDisk:urls[0]];
    XCTAssertNotNil(image);
}

- (void)testPreloadingInAppImages {
    NSArray *urls = [self generateImageURLs:2];
    NSArray *csInAppNotifs = @[
        @{
            @"media": @{
                @"content_type": @"image/jpeg",
                @"url": urls[0],
            }
        },
        @{
            @"media": @{
                @"content_type": @"image/jpeg",
                @"url": urls[1]
            }
        }
    ];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Image Preload to Disk Cache"];
    // Preload Images
    [self.prefetchManager preloadClientSideInAppImages:csInAppNotifs];
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void) {
        XCTAssertEqual([[self.prefetchManager activeImageSet] count], 2);
        XCTAssertNotNil([self.prefetchManager loadImageFromDisk:urls[0]]);
        XCTAssertNotNil([self.prefetchManager loadImageFromDisk:urls[1]]);
        [expectation fulfill];
    });
    
    [self waitForExpectations:@[expectation] timeout:2.5];
}

- (void)testImagePresentInDiskCache3 {
    NSArray *urls = [self generateImageURLs:3];
    // Load the images to disk, new images are directly added to the active set
    [self preloadImagesToDisk:@[urls[0], urls[1]]];
    
    // Set the inactive URLs set
    NSMutableSet *urlsSet = [[NSMutableSet alloc] initWithArray:urls];
    [self.prefetchManager setInactiveImageSet:urlsSet];
    
    //XCTestExpectation *expectation = [self expectationWithDescription:@"Image Preload to Disk Cache"];
    // Load the images to disk again, so the already saved ones are removed from the inactive set
    [self preloadImagesToDisk:@[urls[0], urls[1]]];
    
    XCTAssertEqual([[self.prefetchManager activeImageSet] count], 2, @"Active images ");
    XCTAssertEqual([[self.prefetchManager inactiveImageSet] count], 1);
    
    [self setLastDeletedPastExpiry];
    [self preloadImagesToDisk:@[urls[0]]];
    XCTAssertEqual([[self.prefetchManager activeImageSet] count], 0, @"number of active images");
    XCTAssertEqual([[self.prefetchManager inactiveImageSet] count], 2);
}

- (void)testClearAllImageAssets {
    // Save the image
    NSArray *urls = [self generateImageURLs:1];
    [self preloadImagesToDisk:urls];
    UIImage *image = [self.prefetchManager loadImageFromDisk:urls[0]];
    XCTAssertNotNil(image);
    
    [self.prefetchManager _clearImageAssets:NO];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Clear Disk Cache"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {
        UIImage *image = [self.prefetchManager loadImageFromDisk:urls[0]];
        XCTAssertNil(image);
        [expectation fulfill];
    });
    
    [self waitForExpectations:@[expectation] timeout:2.5];
}

- (void)testClearInactiveImageAssets {
    // Save the image
    NSArray *urls = [self generateImageURLs:2];
    [self preloadImagesToDisk:urls];
    
    NSMutableSet *urlsSet = [[NSMutableSet alloc] initWithArray:@[urls[0]]];
    [self.prefetchManager setInactiveImageSet:urlsSet];
    
    [self setLastDeletedPastExpiry];
    [self.prefetchManager _clearImageAssets:YES];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Clear Disk Cache"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {
        UIImage *inactiveImage = [self.prefetchManager loadImageFromDisk:urls[0]];
        XCTAssertNil(inactiveImage);
        UIImage *activeImage = [self.prefetchManager loadImageFromDisk:urls[1]];
        XCTAssertNotNil(activeImage);
        [expectation fulfill];
    });
    
    [self waitForExpectations:@[expectation] timeout:2.5];
}

- (void)testSetImageAssetsInactiveAndClearExpired {
    // Save the image
    NSArray *urls = [self generateImageURLs:2];
    [self preloadImagesToDisk:urls];
    XCTAssertEqual([[self.prefetchManager inactiveImageSet] count], 0);

    [self.prefetchManager setImageAssetsInactiveAndClearExpired];
    // Last deleted date has not passed, images are moved to inactive assets only
    XCTAssertEqual([[self.prefetchManager inactiveImageSet] count], 2);
    
    [self setLastDeletedPastExpiry];
    [self.prefetchManager setImageAssetsInactiveAndClearExpired];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Clear Disk Cache"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {
        XCTAssertEqual([[self.prefetchManager inactiveImageSet] count], 0);
        XCTAssertEqual([[self.prefetchManager activeImageSet] count], 0);
        XCTAssertNil([self.prefetchManager loadImageFromDisk:urls[0]]);
        XCTAssertNil([self.prefetchManager loadImageFromDisk:urls[1]]);
        [expectation fulfill];
    });
    
    [self waitForExpectations:@[expectation] timeout:2.5];
}

@end

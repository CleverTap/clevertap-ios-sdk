#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTInAppImagePrefetchManager.h"

NSString * const imageURL = @"https://db7hsdc8829us.cloudfront.net/dist/1657700480/i/9b4478b0fcb44457b224adfc39497bc9.jpeg?v=1665140358";

@interface CTInAppImagePrefetchManagerTest : XCTestCase
@property (nonatomic, strong) CTInAppImagePrefetchManager *prefetchManager;
@end

@implementation CTInAppImagePrefetchManagerTest

- (void)setUp {
    [super setUp];
    
    CleverTapInstanceConfig *config = [[CleverTapInstanceConfig alloc] initWithAccountId:@"testAccountID" accountToken:@"testAccountToken"];
    self.prefetchManager = [[CTInAppImagePrefetchManager alloc] initWithConfig:config];
    [self preloadImagesToDisk];
}

- (void)tearDown {
    [super tearDown];

    self.prefetchManager = nil;
}

- (void)preloadImagesToDisk {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Image Preload to Disk Cache"];
    NSArray *csInAppNotifs = @[
        @{
            @"media": @{
                @"content_type": @"image/jpeg",
                @"url": @"https://db7hsdc8829us.cloudfront.net/dist/1657700480/i/9b4478b0fcb44457b224adfc39497bc9.jpeg?v=1665140358",
            }
        }
    ];
    // Preload Images.
    [self.prefetchManager preloadClientSideInAppImages:csInAppNotifs];

    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        [expectation fulfill];
    });
    
    [self waitForExpectations:@[expectation] timeout:DISPATCH_TIME_NOW + 3.0];
}

- (void)testImagePresentInDiskCache {
    // Check image is present in disk cache
    UIImage *image = [self.prefetchManager loadImageFromDisk:imageURL];
    XCTAssertNotNil(image);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Clear Disk Images"];
    // Clear Disk Images.
    [self.prefetchManager clearDiskImages];
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        [expectation fulfill];
    });
    [self waitForExpectations:@[expectation] timeout:DISPATCH_TIME_NOW + 3.0];
    
    // Check image is not present in disk cache
    UIImage *image1 = [self.prefetchManager loadImageFromDisk:imageURL];
    XCTAssertNil(image1);
}

@end

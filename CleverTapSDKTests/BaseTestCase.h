#import <XCTest/XCTest.h>

@interface BaseTestCase : XCTestCase

@property (nonatomic, retain) NSDictionary *responseJson;
@property (nonatomic, retain) NSDictionary *responseHeaders;

- (void)getLastEvent:(void (^)(NSDictionary*))handler;
- (void)getLastBatchHeader:(void (^)(NSDictionary*))handler;


@end

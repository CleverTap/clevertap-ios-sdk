#import <XCTest/XCTest.h>
#import "CleverTap.h"

@interface BaseTestCase : XCTestCase

@property (nonatomic, retain) NSDictionary *responseJson;
@property (nonatomic, retain) NSDictionary *responseHeaders;
@property (nonatomic, retain) CleverTap *cleverTapInstance;
@property (nonatomic, retain) CleverTap *additionalInstance;

- (void)getLastEvent:(void (^)(NSDictionary*))handler;
- (void)getLastBatchHeader:(void (^)(NSDictionary*))handler;
- (NSDictionary*)getLastEvent;


@end

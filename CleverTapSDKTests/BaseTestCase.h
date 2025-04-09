#import <XCTest/XCTest.h>
#import <CleverTapSDK/CleverTap.h>
#import "EventDetail.h"

@interface BaseTestCase : XCTestCase

@property (nonatomic, retain) NSString *responseFilePath;
@property (nonatomic, retain) NSDictionary *responseJson;
@property (nonatomic, retain) NSDictionary *responseHeaders;
@property (nonatomic, retain) CleverTap *cleverTapInstance;
@property (nonatomic, retain) CleverTap *additionalInstance;
@property (nonatomic, retain) NSMutableArray *eventDetails;

- (void)getLastEvent:(void (^)(NSDictionary*))handler;
- (void)getLastBatchHeader:(void (^)(NSDictionary*))handler;
- (void)stubRequestsWithName:(NSString*)name;
- (void)getLastEventWithStubName: (NSString*)stubName eventName: (NSString*)eventName eventType:(NSString*)eventType handler:(void (^)(NSDictionary *))handler;
@end

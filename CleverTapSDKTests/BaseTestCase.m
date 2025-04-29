#import "BaseTestCase.h"
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsResponse+JSON.h>
#import <OHHTTPStubs/NSURLRequest+HTTPBodyTesting.h>
#import <CleverTapSDK/CleverTap.h>
#import "CleverTap+Tests.h"

@interface BaseTestCase ()
@property (nonatomic, retain) NSDictionary *lastEvent;
@property (nonatomic, retain) NSDictionary *lastBatchHeader;

@end

@implementation BaseTestCase

+ (void)initialize {
    id mockApplication = OCMClassMock([UIApplication class]);
    OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);
}

- (void)onStubActivation:(NSURLRequest * _Nonnull)request stub:(id<HTTPStubsDescriptor> _Nonnull)stub {
    NSData *body = [request OHHTTPStubs_HTTPBody];
    if (body) {
        NSArray *data = [NSJSONSerialization JSONObjectWithData:[request OHHTTPStubs_HTTPBody] options:NSJSONReadingMutableContainers error:nil];
        if (data && data.count > 1) {
            self.lastBatchHeader = [data objectAtIndex:0];
            self.lastEvent = [data objectAtIndex:1];
            [self.eventDetails addObject:[[EventDetail alloc]initWithEvent:[data objectAtIndex:1] name:stub.name]];
            NSLog(@"LAST EVENT for %@", stub.name);
        }
    }
}

- (void)setUp {
    [CleverTap setDebugLevel:3];
    BOOL cleverTapInitialized = [[CleverTap sharedInstance] profileGetCleverTapID] != nil;
    
    if (!cleverTapInitialized) {
        [CleverTap setCredentialsWithAccountID:@"test" token:@"test" region:@"eu1"];
    }
   
    self.eventDetails = [NSMutableArray array];
    self.cleverTapInstance = [CleverTap sharedInstance];
    
    CleverTapInstanceConfig *addtionalConfig = [[CleverTapInstanceConfig alloc]initWithAccountId:@"testAddtional" accountToken:@"testAddtional" accountRegion: @"eu1"];
    addtionalConfig.identityKeys = @[@"Email"];
    self.additionalInstance = [CleverTap instanceWithConfig:addtionalConfig];
    self.responseJson = @{ @"key1": @"value1", @"key2": @[@"value2A", @"value2B"] }; // TODO
    self.responseHeaders = @{@"Content-Type":@"application/json"};
    
    __weak typeof(self) weakSelf = self;
    [HTTPStubs onStubActivation:^(NSURLRequest * _Nonnull request, id<HTTPStubsDescriptor>  _Nonnull stub, HTTPStubsResponse * _Nonnull responseStub) {
        if (weakSelf) {
            [weakSelf onStubActivation:request stub:stub];
        }
    }];
    if (!cleverTapInitialized) {
        [CleverTap notfityTestAppLaunch];
        XCTestExpectation *expectation = [self expectationWithDescription:@"Wait For App Launch"];
        dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
        dispatch_after(delay, dispatch_get_main_queue(), ^(void){
            [expectation fulfill];
        });
        [self waitForExpectationsWithTimeout:2.5 handler:^(NSError *error) {
            // no-op
        }];
    }
}

- (void)tearDown {
    [HTTPStubs removeAllStubs];
    self.lastBatchHeader = nil;
    self.lastEvent = nil;
    self.responseJson = nil;
    self.responseHeaders = nil;
    self.responseFilePath = nil;
    self.cleverTapInstance = nil;
    self.additionalInstance = nil;
    [super tearDown];
}

- (void)stubRequestsWithName:(NSString*)name {
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"eu1.clevertap-prod.com"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        if (self.responseFilePath) {
            return [HTTPStubsResponse responseWithFileAtPath:[[NSBundle bundleForClass:[self class]] pathForResource:self.responseFilePath ofType:@"json"] statusCode:200 headers:self.responseHeaders];
        } else {
            return [HTTPStubsResponse responseWithJSONObject:self.responseJson statusCode:200 headers:self.responseHeaders];
        }
       
    }].name = name;
}

- (void)getLastEvent:(void (^)(NSDictionary*))handler {
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        handler(self.lastEvent);
    });
}

- (void)getLastBatchHeader:(void (^)(NSDictionary *))handler {
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        handler(self.lastBatchHeader);
    });
}

- (void)getLastEventWithStubName: (NSString*)stubName eventName: (NSString*)eventName eventType:(NSString*)eventType handler:(void (^)(NSDictionary *))handler {
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        EventDetail *filteredEvent = [self getFilteredEventWithStubName:stubName eventName:eventName eventType:eventType];
        handler(filteredEvent.event);
    });
}

- (EventDetail*)getFilteredEventWithStubName: (NSString*)stubName eventName: (NSString*)eventName eventType:(NSString*)eventType {
    NSPredicate *pred = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        EventDetail *d = (EventDetail*)evaluatedObject;
        
        if (eventName) {
            return ([d.stubName isEqualToString:stubName]) && ([d.event[@"evtName"]isEqualToString:eventName]);
        }
        else if (eventType) {
            if ([eventType isEqualToString:@"profile"]) {
                
                NSDictionary *profileDict = (NSDictionary*)d.event[@"profile"];
                BOOL result = ([d.stubName isEqualToString:stubName]) && ([d.event[@"type"]isEqualToString:eventType]) && (profileDict.count > 0);
                return result;
            }
            return ([d.stubName isEqualToString:stubName]) && ([d.event[@"type"]isEqualToString:eventType]);
        }
        return nil;
    }];
    NSArray *filteredEvents = [self.eventDetails filteredArrayUsingPredicate: pred];
    return (filteredEvents && [filteredEvents count] > 0) ? (EventDetail*)filteredEvents[0] : nil;
}

@end

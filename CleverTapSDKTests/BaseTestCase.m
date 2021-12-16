#import "BaseTestCase.h"
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsResponse+JSON.h>
#import <OHHTTPStubs/NSURLRequest+HTTPBodyTesting.h>

@interface BaseTestCase ()
@property (nonatomic, retain) NSDictionary *lastEvent;
@property (nonatomic, retain) NSDictionary *lastBatchHeader;

@end

@implementation BaseTestCase

+ (void)initialize {
    
}

- (void)setUp {
    [CleverTap setDebugLevel:3];
    [CleverTap setCredentialsWithAccountID:@"test" token:@"test" region:@"eu1"];
    self.cleverTapInstance = [CleverTap sharedInstance];
    self.additionalInstance = [CleverTap instanceWithConfig:[[CleverTapInstanceConfig alloc]initWithAccountId:@"test" accountToken:@"test" accountRegion:@"eu1"]];
    self.responseJson = @{ @"key1": @"value1", @"key2": @[@"value2A", @"value2B"] }; // TODO
    self.responseHeaders = @{@"Content-Type":@"application/json"};
    
    
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"eu1.clevertap-prod.com"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        
        
        return [HTTPStubsResponse responseWithJSONObject:self.responseJson statusCode:200 headers:self.responseHeaders];
    }];
    
    [HTTPStubs onStubActivation:^(NSURLRequest * _Nonnull request, id<HTTPStubsDescriptor>  _Nonnull stub, HTTPStubsResponse * _Nonnull responseStub) {
        NSArray *data = [NSJSONSerialization JSONObjectWithData:[request OHHTTPStubs_HTTPBody] options:NSJSONReadingMutableContainers error:nil];

        self.lastBatchHeader = [data objectAtIndex:0];
        self.lastEvent = [data objectAtIndex:1];
    }];
}

- (void)tearDown {
    [HTTPStubs removeAllStubs];
    self.lastBatchHeader = nil;
    self.lastEvent = nil;
    self.responseJson = nil;
    self.responseHeaders = nil;
    self.cleverTapInstance = nil;
    self.additionalInstance = nil;
    [super tearDown];
}

- (void)getLastEvent:(void (^)(NSDictionary*))handler {
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        handler(self.lastEvent);
    });
}

- (NSDictionary*)getLastEvent {
    return self.lastEvent;
}

- (void)getLastBatchHeader:(void (^)(NSDictionary *))handler {
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        handler(self.lastBatchHeader);
    });
}


@end
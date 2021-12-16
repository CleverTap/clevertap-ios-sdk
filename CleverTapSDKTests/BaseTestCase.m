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

- (void)setUp {
    [CleverTap setDebugLevel:3];
    [CleverTap setCredentialsWithAccountID:@"test" token:@"test" region:@"eu1"];
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"eu1.clevertap-prod.com"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        return [HTTPStubsResponse responseWithJSONObject:self.responseJson statusCode:200 headers:self.responseHeaders];
    }];
    
    [HTTPStubs onStubActivation:^(NSURLRequest * _Nonnull request, id<HTTPStubsDescriptor>  _Nonnull stub, HTTPStubsResponse * _Nonnull responseStub) {
        NSArray *data = [NSJSONSerialization JSONObjectWithData:[request OHHTTPStubs_HTTPBody] options:NSJSONReadingMutableContainers error:nil];
        NSLog(@"Request body is: %@", data); // TODO remove
        self.lastBatchHeader = [data objectAtIndex:0];
        self.lastEvent = [data objectAtIndex:1];
    }];
    [CleverTap notfityTestAppLaunch];
}

- (void)tearDown {
    [HTTPStubs removeAllStubs];
    self.lastBatchHeader = nil;
    self.lastEvent = nil;
    self.responseJson = nil;
    self.responseHeaders = nil;
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


@end

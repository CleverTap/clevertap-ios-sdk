//
//  StubHelper.m
//  CleverTapSDKTestsApp
//
//  Created by Akash Malhotra on 30/12/21.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import "StubHelper.h"
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsResponse+JSON.h>
#import <OHHTTPStubs/NSURLRequest+HTTPBodyTesting.h>
#import "TestConstants.h"

@implementation StubHelper

+ (instancetype)sharedInstance {
    static StubHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)stubRequests {
    // NSDictionary *responseJson = @{ @"key1": @"value1", @"key2": @[@"value2A", @"value2B"] };
    NSDictionary *responseHeaders = @{@"Content-Type":@"application/json"};
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"eu1.clevertap-prod.com"];
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        
        NSArray *responseData = [NSJSONSerialization JSONObjectWithData:[request OHHTTPStubs_HTTPBody] options:NSJSONReadingMutableContainers error:nil];
        NSDictionary *event = [responseData objectAtIndex:1];
        
        if ([[event objectForKey:@"evtName"]isEqualToString: kEventAlertRequested]) {
            return [HTTPStubsResponse responseWithFileAtPath:[[NSBundle mainBundle]pathForResource:@"inapp_alert" ofType:@"json"] statusCode:200 headers:responseHeaders];
        }
        else if ([[event objectForKey:@"evtName"]isEqualToString: kEventInterstitalRequested]) {
            return [HTTPStubsResponse responseWithFileAtPath:[[NSBundle mainBundle]pathForResource:@"inapp_interstitial" ofType:@"json"] statusCode:200 headers:responseHeaders];
        }
        return [HTTPStubsResponse responseWithFileAtPath:[[NSBundle mainBundle]pathForResource:@"app_inbox" ofType:@"json"] statusCode:200 headers:responseHeaders];
    }];
}
@end

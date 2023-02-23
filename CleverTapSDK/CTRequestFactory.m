//
//  CTRequestFactory.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 09/01/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTRequestFactory.h"
#import "CTConstants.h"

@implementation CTRequestFactory

+ (CTRequest *_Nonnull)helloRequestWithConfig:(CleverTapInstanceConfig *_Nonnull)config {
    
    return
//    [CTRequestFactory createGetForParams:params];
    [[CTRequest alloc]initWithHttpMethod:@"GET" config:config params:nil url:@"https://eu1.clevertap-prod.com/hello"];
}

+ (CTRequest *_Nonnull)eventRequestWithConfig:(CleverTapInstanceConfig *_Nonnull)config params:(id _Nullable)params url:(NSString *_Nonnull)url {
    return [[CTRequest alloc]initWithHttpMethod:@"POST" config:config params: params url:url];
}

+ (CTRequest *_Nonnull)syncVarsRequestWithConfig:(CleverTapInstanceConfig *_Nonnull)config params:(id _Nullable)params url:(NSString *_Nonnull)url {
    return [[CTRequest alloc]initWithHttpMethod:@"POST" config:config params: params url:url];
}

#pragma mark Private methods

//+ (CTRequest *)createGetForParams:(NSDictionary *)params {
//    return [CTRequest getForParams:params];
//}
//
//+ (CTRequest *)createPostForApiMethod:(NSString *)apiMethod params:(NSDictionary *)params {
//    return [CTRequest postForParams:params];
//}

@end

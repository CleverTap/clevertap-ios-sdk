//
//  CTRequestFactory.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 09/01/23.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTRequestFactory.h"
#import "CTConstants.h"

@implementation CTRequestFactory

+ (CTRequest *_Nonnull)helloRequestWithConfig:(CleverTapInstanceConfig *_Nonnull)config {
    NSString *helloUrl = kHANDSHAKE_URL;
    if (config.handshakeDomain) {
        helloUrl = [NSString stringWithFormat:@"https://%@/hello",config.handshakeDomain];
    }
    CTRequest *request = [[CTRequest alloc] initWithHttpMethod:@"GET" config:config params:nil url:helloUrl];
    if (config.handshakeDomain) {
        [request.urlRequest setValue:config.handshakeDomain forHTTPHeaderField:kHANDSHAKE_DOMAIN_HEADER];
    }
    return request;
}

+ (CTRequest *_Nonnull)eventRequestWithConfig:(CleverTapInstanceConfig *_Nonnull)config params:(id _Nullable)params url:(NSString *_Nonnull)url {
    return [[CTRequest alloc] initWithHttpMethod:@"POST" config:config params: params url:url];
}

+ (CTRequest *_Nonnull)syncVarsRequestWithConfig:(CleverTapInstanceConfig *_Nonnull)config params:(id _Nullable)params domain:(NSString *_Nonnull)domain {
    NSString *url = [self urlWithDomain:domain andPath:@"defineVars"];
    return [[CTRequest alloc] initWithHttpMethod:@"POST" config:config params: params url:url];
}

+ (CTRequest *_Nonnull)syncTemplatesRequestWithConfig:(CleverTapInstanceConfig *_Nonnull)config params:(id _Nullable)params domain:(NSString *_Nonnull)domain {
    NSString *url = [self urlWithDomain:domain andPath:@"defineTemplates"];
    return [[CTRequest alloc] initWithHttpMethod:@"POST" config:config params: params url:url];
}

+ (NSString *)urlWithDomain:(NSString *)domain andPath:(NSString *)path {
    return [NSString stringWithFormat:@"https://%@/%@", domain, path];
}

@end

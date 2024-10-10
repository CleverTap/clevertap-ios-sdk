//
//  CTRequest.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 09/01/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTRequest.h"
#import "CTConstants.h"
#import "CTUtils.h"

@interface CTRequest()

@property (nonatomic, strong, nullable) id params;
@property (nonatomic, strong) NSString *httpMethod;
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) NSString *url;


@end

@implementation CTRequest

- (CTRequest *_Nonnull)initWithHttpMethod:(NSString *_Nonnull)httpMethod config:(CleverTapInstanceConfig *_Nonnull)config params:(id _Nullable)params url:(NSString *_Nonnull)url {
    self = [super init];
    if (self) {
        _httpMethod = httpMethod;
        _params = params;
        _config = config;
        _url = url;
        _urlRequest = [self createURLRequest];
    }
    return self;
}

- (NSMutableURLRequest *)createURLRequest {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:_url]];
    NSString *accountId = self.config.accountId;
    NSString *accountToken = self.config.accountToken;
    if (accountId) {
        [request setValue:accountId forHTTPHeaderField:ACCOUNT_ID_HEADER];
    }
    if (accountToken) {
        [request setValue:accountToken forHTTPHeaderField:ACCOUNT_TOKEN_HEADER];
    }
    if ([_httpMethod isEqualToString:@"POST"] && _params > 0) {
        NSString *jsonBody = [CTUtils jsonObjectToString:_params];
        request.HTTPBody = [jsonBody dataUsingEncoding:NSUTF8StringEncoding];
        request.HTTPMethod = @"POST";
    }
    return request;
}

- (void)onResponse:(CTNetworkResponseBlock _Nonnull)responseBlock {
    _responseBlock = responseBlock;
}

- (void)onError:(CTNetworkResponseErrorBlock _Nonnull)errorBlock {
    _errorBlock = errorBlock;
}

@end

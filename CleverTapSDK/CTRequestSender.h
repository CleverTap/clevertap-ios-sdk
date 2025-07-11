//
//  CTRequestSender.h
//  CleverTapSDK
//
//  Created by Akash Malhotra on 11/01/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTRequest.h"
#if CLEVERTAP_SSL_PINNING
#import "CTPinnedNSURLSessionDelegate.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CTRequestSender : NSObject
@property (nonatomic, copy, nullable) NSString *redirectDomain;
@property (nonatomic, assign, readonly) NSTimeInterval requestTimeout;
@property (nonatomic, assign, readonly) NSTimeInterval resourceTimeout;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
                redirectDomain:(NSString * _Nullable)redirectDomain;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
                redirectDomain:(NSString * _Nullable)redirectDomain
                requestTimeout:(NSTimeInterval)requestTimeout
               resourceTimeout:(NSTimeInterval)resourceTimeout;

#if CLEVERTAP_SSL_PINNING
- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
                redirectDomain:(NSString * _Nullable)redirectDomain
    pinnedNSURLSessionDelegate:(CTPinnedNSURLSessionDelegate *)pinnedNSURLSessionDelegate
                  sslCertNames:(NSArray *)sslCertNames;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config
                redirectDomain:(NSString * _Nullable)redirectDomain
    pinnedNSURLSessionDelegate:(CTPinnedNSURLSessionDelegate *)pinnedNSURLSessionDelegate
                  sslCertNames:(NSArray *)sslCertNames
                requestTimeout:(NSTimeInterval)requestTimeout
               resourceTimeout:(NSTimeInterval)resourceTimeout;
#endif

- (void)send:(CTRequest *)ctRequest;
@end

NS_ASSUME_NONNULL_END

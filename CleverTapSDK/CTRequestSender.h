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

@interface CTRequestSender : NSObject
@property (nonatomic, copy, nullable) NSString *redirectDomain;

- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig * _Nonnull)config redirectDomain:(NSString * _Nullable)redirectDomain;

#if CLEVERTAP_SSL_PINNING
- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig * _Nonnull)config redirectDomain:(NSString * _Nullable)redirectDomain pinnedNSURLSessionDelegate:(CTPinnedNSURLSessionDelegate * _Nonnull)pinnedNSURLSessionDelegate sslCertNames:(NSArray * _Nonnull)sslCertNames;
#endif

- (void)send:(CTRequest * _Nonnull)ctRequest;
@end


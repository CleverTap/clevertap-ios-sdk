//
//  CTDomainFactory.h
//  CleverTapSDK
//
//  Created by Akash Malhotra on 19/01/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CleverTapInstanceConfig.h"
#if CLEVERTAP_SSL_PINNING
#import "CTPinnedNSURLSessionDelegate.h"
#endif


@interface CTDomainFactory : NSObject
@property (nonatomic, strong, nullable) NSString *redirectDomain;
@property (nonatomic, strong, nullable) NSString *explictEndpointDomain;
@property (nonatomic, strong, nullable) NSString *redirectNotifViewedDomain;
@property (nonatomic, strong, nullable) NSString *explictNotifViewedEndpointDomain;

- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig* _Nonnull)config;
- (void)persistRedirectDomain;
- (void)persistRedirectNotifViewedDomain;
- (void)clearRedirectDomain;

#if CLEVERTAP_SSL_PINNING
- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig* _Nonnull)config pinnedNSURLSessionDelegate: (CTPinnedNSURLSessionDelegate* _Nonnull)pinnedNSURLSessionDelegate sslCertNames:(NSArray* _Nonnull)sslCertNames;
#endif
@end


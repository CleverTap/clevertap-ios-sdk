//
//  CTDomainFactory.h
//  CleverTapSDK
//
//  Created by Akash Malhotra on 19/01/23.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CleverTapInstanceConfig.h"
#import "CTRequestSender.h"
#import "CTDispatchQueueManager.h"
#if CLEVERTAP_SSL_PINNING
#import "CTPinnedNSURLSessionDelegate.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@protocol CTDomainResolverDelegate <NSObject>

- (void)onHandshakeSuccess;
- (void)onMute;

@end

@interface CTDomainFactory : NSObject

@property (nonatomic, strong, nullable) NSString *redirectDomain;
@property (nonatomic, strong, nullable) NSString *explictEndpointDomain;
@property (nonatomic, strong, nullable) NSString *redirectNotifViewedDomain;
@property (nonatomic, strong, nullable) NSString *explictNotifViewedEndpointDomain;
@property (nonatomic, strong, nullable) NSString *signedCallDomain;

@property (nonatomic, strong) CTDispatchQueueManager *dispatchQueueManager;
@property (nonatomic, weak) id <CleverTapDomainDelegate> domainDelegate;
@property (nonatomic, weak) id <CTDomainResolverDelegate> domainResolverDelegate;

- (instancetype _Nonnull)initWithConfig:(CleverTapInstanceConfig *)config;
- (void)persistRedirectDomain;
- (void)persistRedirectNotifViewedDomain;
- (void)clearRedirectDomain;

#if CLEVERTAP_SSL_PINNING
- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config pinnedNSURLSessionDelegate:(CTPinnedNSURLSessionDelegate *)pinnedNSURLSessionDelegate sslCertNames:(NSArray *)sslCertNames;
#endif

- (BOOL)isMuted;
- (BOOL)needsHandshake;
- (void)runSerialAsyncEnsureHandshake:(void(^)(BOOL success))block;
- (BOOL)updateStateFromResponseHeaders:(NSDictionary *)headers;
- (BOOL)updateStateForNotificationsFromResponseHeaders:(NSDictionary *)headers;
- (void)setRequestSender:(CTRequestSender *)requestSender;
- (NSString *)domainString;

@end

NS_ASSUME_NONNULL_END

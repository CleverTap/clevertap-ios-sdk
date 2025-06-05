//
//  CTDomainFactory.h
//  CleverTapSDK
//
//  Created by Akash Malhotra on 19/01/23.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CleverTapInstanceConfig.h"
@class CTRequestSender;
@class CTDispatchQueueManager;
#if CLEVERTAP_SSL_PINNING
#import "CTPinnedNSURLSessionDelegate.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@protocol CTDomainOperations <NSObject>

@property (nonatomic, strong, nullable, readonly) NSString *redirectDomain;
- (BOOL)needsHandshake;
- (void)runSerialAsyncEnsureHandshake:(void(^ _Nullable)(BOOL success))block;

@end

@protocol CTDomainResolverDelegate <NSObject>

- (void)onHandshakeSuccess;
- (void)onMute;

@end

@interface CTDomainFactory : NSObject <CTDomainOperations>

@property (nonatomic, strong, nullable) NSString *redirectDomain;
@property (nonatomic, strong, nullable) NSString *explicitEndpointDomain;
@property (nonatomic, strong, nullable) NSString *redirectNotifViewedDomain;
@property (nonatomic, strong, nullable) NSString *explicitNotifViewedEndpointDomain;
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
- (BOOL)updateDomainFromResponseHeaders:(NSDictionary *)headers;
- (BOOL)updateNotificationViewedDomainFromResponseHeaders:(NSDictionary *)headers;
- (void)updateMutedFromResponseHeaders:(NSDictionary *)headers;
- (void)setRequestSender:(CTRequestSender *)requestSender;
- (NSString * _Nullable)domainString;

@end

NS_ASSUME_NONNULL_END

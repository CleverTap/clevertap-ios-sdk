//
//  CTDomainOperationsMock.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 30.05.25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTDomainFactory.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTDomainOperationsMock : NSObject <CTDomainOperations>

@property (nonatomic, strong) NSString *redirectDomain;
@property (nonatomic, assign) BOOL needsHandshake;

@property (nonatomic, assign) BOOL executeEnsureHandshakeBlock;
@property (nonatomic, assign) BOOL simulateHandshakeSuccess;
@property (nonatomic, copy, nullable) void (^handshakeBlock)(BOOL success);

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRedirectDomain:(NSString *)redirectDomain;
- (instancetype)initWithRedirectDomain:(NSString *)redirectDomain
                        needsHandshake:(BOOL)needsHandshake
                      handshakeSuccess:(BOOL)handshakeSuccess;

@end

NS_ASSUME_NONNULL_END

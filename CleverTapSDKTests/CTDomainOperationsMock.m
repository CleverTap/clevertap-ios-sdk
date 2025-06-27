//
//  CTDomainOperationsMock.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 30.05.25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import "CTDomainOperationsMock.h"

@implementation CTDomainOperationsMock

- (instancetype)initWithRedirectDomain:(NSString *)redirectDomain {
    return [self initWithRedirectDomain:redirectDomain needsHandshake:NO handshakeSuccess:YES];
}

- (instancetype)initWithRedirectDomain:(NSString *)redirectDomain
                        needsHandshake:(BOOL)needsHandshake
                      handshakeSuccess:(BOOL)handshakeSuccess {
    self = [super init];
    if (self) {
        _redirectDomain = redirectDomain;
        _needsHandshake = needsHandshake;
        _simulateHandshakeSuccess = handshakeSuccess;
    }
    return self;
}

- (NSString *)redirectDomain {
    return _redirectDomain;
}

- (BOOL)needsHandshake {
    return _needsHandshake;
}

- (void)runSerialAsyncEnsureHandshake:(void(^ _Nullable)(BOOL success))block {
    BOOL success = self.simulateHandshakeSuccess;
    if (self.executeEnsureHandshakeBlock && block) {
        block(success);
    }
    if (self.handshakeBlock) {
        self.handshakeBlock(success);
    }
}

@end

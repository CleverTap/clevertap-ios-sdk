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
    self = [super init];
    if (self) {
        _redirectDomain = redirectDomain;
        _needsHandshake = NO;
    }
    return self;
}

- (NSString *)redirectDomain {
    return _redirectDomain;
}

- (BOOL)needsHandshake {
    return _needsHandshake;
}

- (void)runSerialAsyncEnsureHandshake:(void(^)(BOOL success))block {
    if (self.executeEnsureHandshakeBlock && block) {
        block(YES);
    }
    if (self.handshakeBlock) {
        self.handshakeBlock(YES);
    }
}

@end

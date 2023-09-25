//
//  CTInAppStore.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 21.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTInAppStore.h"

NSString* const kCLIENT_SIDE_MODE = @"CS";
NSString* const kSERVER_SIDE_MODE = @"SS";

@implementation CTInAppStore

@synthesize mode = _mode;

- (NSString *)mode {
    return _mode;
}

- (void)setMode:(nullable NSString *)mode {
    if ([_mode isEqualToString:mode]) return;
    _mode = mode;
    
    if ([mode isEqualToString:kCLIENT_SIDE_MODE]) {
        [self removeServerSideInApps];
    } else if ([mode isEqualToString:kSERVER_SIDE_MODE]) {
        [self removeClientSideInApps];
    } else {
        [self removeServerSideInApps];
        [self removeClientSideInApps];
    }
}

- (NSArray *)clientSideInApps {
    return @[];
}

- (NSArray *)serverSideInApps {
    return @[];
}

- (void)removeClientSideInApps {
}

- (void)removeServerSideInApps {
}

@end

//
//  CTLegacyIdentityRepo.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 05/12/21.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import "CTLegacyIdentityRepo.h"
#import "CTConstants.h"

@interface CTLegacyIdentityRepo () {}
@property (nonatomic, strong) NSArray *identities;
@end

@implementation CTLegacyIdentityRepo

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.identities = CLTAP_PROFILE_IDENTIFIER_KEYS;
    }
    return self;
}

- (NSArray *)getIdentities { 
    return self.identities;
}

- (BOOL)isIdentity:(NSString *)key {
    return [self.identities containsObject:key];
}

@end

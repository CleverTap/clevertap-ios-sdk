//
//  CTIdentityRepoFactory.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 05/12/21.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import "CTIdentityRepoFactory.h"
#import "CTLoginInfoProvider.h"
#import "CTLegacyIdentityRepo.h"
#import "CTFlexibleIdentityRepo.h"

@implementation CTIdentityRepoFactory

+ (id<CTIdentityRepo>)getRepoForConfig:(CleverTapInstanceConfig*)config deviceInfo:(CTDeviceInfo*)deviceInfo validationResultStack:(CTValidationResultStack*)validationResultStack {
    
    id<CTIdentityRepo> identityRepo;
    CTLoginInfoProvider *loginInfoProvider = [[CTLoginInfoProvider alloc]initWithDeviceInfo:deviceInfo config:config];
    if ([loginInfoProvider isLegacyProfileLoggedIn]) {
        identityRepo = [[CTLegacyIdentityRepo alloc]init];
    }
    else {
        identityRepo = [[CTFlexibleIdentityRepo alloc]initWithConfig:config deviceInfo:deviceInfo validationResultStack:validationResultStack];
    }
    return identityRepo;
}

@end

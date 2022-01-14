//
//  CTFlexibleIdentityRepo.h
//  CleverTapSDK
//
//  Created by Akash Malhotra on 05/12/21.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTIdentityRepo.h"
#import "CleverTapInstanceConfig.h"
#import "CTDeviceInfo.h"
#import "CTValidationResultStack.h"

@interface CTFlexibleIdentityRepo : NSObject<CTIdentityRepo>
- (instancetype)initWithConfig:(CleverTapInstanceConfig*)config deviceInfo:(CTDeviceInfo*)deviceInfo validationResultStack:(CTValidationResultStack*)validationResultStack;
@end

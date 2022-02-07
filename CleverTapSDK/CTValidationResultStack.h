//
//  CTValidationResultStack.h
//  CleverTapSDK
//
//  Created by Akash Malhotra on 05/12/21.
//  Copyright © 2021 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTValidationResult.h"
#import "CleverTapInstanceConfig.h"

@interface CTValidationResultStack : NSObject

- (void)pushValidationResults:(NSArray<CTValidationResult *> *)results;
- (void)pushValidationResult:(CTValidationResult *)vr;
- (CTValidationResult *)popValidationResult;
- (instancetype)initWithConfig:(CleverTapInstanceConfig*)config;
@end

//
//  CTPropertyKeyValidator.h
//  CleverTapSDK
//
//  Created by Sonal Kachare on 12/12/25.
//

#import <Foundation/Foundation.h>
#import "CTValidationConfig.h"
#import "CTValidationResult.h"
#import "CTValidatorBase.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTPropertyKeyValidator : CTValidatorBase

- (instancetype)initWithConfig:(CTValidationConfig *)config;
- (CTValidationResult *)validateKey:(nullable NSString *)key;
- (CTValidationResult *)validateMultiValueKey:(nullable NSString *)key;

@end

NS_ASSUME_NONNULL_END

//
//  CTPropertyKeyValidator.h
//  CleverTapSDK
//
//  Created by Sonal Kachare on 12/12/25.
//

#import <Foundation/Foundation.h>
#import "CTValidationConfig.h"
#import "CTValidationResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTPropertyKeyValidator : NSObject

- (instancetype)initWithConfig:(CTValidationConfig *)config;

/**
 * Validates a property key.
 * Returns CTValidationResult with cleaned key and outcome.
 */
- (CTValidationResult *)validateKey:(nullable NSString *)key;

/**
 * Validates a multi-value property key (additional restrictions).
 * Returns CTValidationResult with cleaned key and outcome.
 */
- (CTValidationResult *)validateMultiValueKey:(nullable NSString *)key;

@end

NS_ASSUME_NONNULL_END

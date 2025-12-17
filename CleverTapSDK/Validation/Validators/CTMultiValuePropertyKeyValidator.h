//
//  CTMultiValuePropertyKeyValidator.h
//  CleverTapSDK
//
//  Created by Sonal Kachare on 15/12/25.
//

#import <Foundation/Foundation.h>
#import "CTPropertyKeyValidator.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Validator for multi-value property keys.
 * Extends base property key validation with multi-value restriction checks.
 *
 * Multi-value properties have additional restrictions:
 * - System reserved fields cannot be used as multi-value properties
 * - Known profile fields (Name, Email, etc.) are restricted
 *
 * Usage:
 * @code
 * CTValidationConfig *config = [CTValidationConfig defaultConfig];
 * CTMultiValuePropertyKeyValidator *validator = [[CTMultiValuePropertyKeyValidator alloc] initWithConfig:config];
 *
 * CTValidationResult *result = [validator validateKey:@"interests"];
 * if (result.shouldDrop) {
 *     NSLog(@"Cannot use this key for multi-value: %@", result.errorDesc);
 * }
 * @endcode
 */
@interface CTMultiValuePropertyKeyValidator : CTPropertyKeyValidator

/**
 * Validates a key for multi-value property operations.
 * Performs base key validation plus multi-value restriction checks.
 *
 * @param key The property key to validate
 * @return ValidationResult with outcome (Success/Warning/Drop)
 *
 * Drop reasons:
 * - Key is null/empty (CTDropReasonEmptyKey)
 * - Key is restricted for multi-value (CTDropReasonRestrictedMultiValueKey)
 *
 * Warning reasons:
 * - Key contains invalid characters (cleaned automatically)
 * - Key exceeds max length (truncated automatically)
 */
- (CTValidationResult *)validateKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END

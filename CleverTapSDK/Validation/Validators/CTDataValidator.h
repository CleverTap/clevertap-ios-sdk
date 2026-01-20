//
//  CTDataValidator.h
//  CleverTapSDK
//
//  Created by Sonal Kachare on 12/12/25.
//

#import <Foundation/Foundation.h>
#import "CTValidationConfig.h"
#import "CTValidationResult.h"
#import "CTValidatorBase.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTDataValidator : CTValidatorBase

- (instancetype)initWithConfig:(CTValidationConfig *)config;

/**
 * Validates and normalizes event properties.
 * Returns CTValidationResult with cleaned dictionary and outcome.
 * Note: Event data validation never drops events, only warns.
 */
- (CTValidationResult *)validateEventData:(nullable NSDictionary *)eventData;
- (CTValidationResult *)cleanArray:(NSArray *)array forKey:(NSString *)key;
- (CTValidationResult *)validate:(NSString *)value forKey:(nullable NSString *)key;
@end

NS_ASSUME_NONNULL_END

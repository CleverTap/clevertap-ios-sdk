//
//  CTEventDataValidator.h
//  CleverTapSDK
//
//  Created by Sonal Kachare on 12/12/25.
//

#import <Foundation/Foundation.h>
#import "CTValidationConfig.h"
#import "CTValidationResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTEventDataValidator : NSObject

- (instancetype)initWithConfig:(CTValidationConfig *)config;

/**
 * Validates and normalizes event properties.
 * Returns CTValidationResult with cleaned dictionary and outcome.
 * Note: Event data validation never drops events, only warns.
 */
- (CTValidationResult *)validateEventData:(nullable NSDictionary *)eventData;

@end

NS_ASSUME_NONNULL_END

//
//  CTEventNameValidator.h
//  CleverTapSDK
//
//  Created by Sonal Kachare on 12/12/25.
//

#import <Foundation/Foundation.h>
#import "CTValidationConfig.h"
#import "CTValidationResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTEventNameValidator: NSObject
@property (nonatomic, strong, readonly) CTValidationConfig *config;

- (instancetype)initWithConfig:(CTValidationConfig *)config;

/**
 * Validates and normalizes an event name.
 * Returns CTValidationResult with cleaned name and outcome.
 */
- (CTValidationResult *)validateEventName:(nullable id)eventName;

@end

NS_ASSUME_NONNULL_END

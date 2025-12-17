//
//  CTMultiValuePropertyKeyValidator.m
//  CleverTapSDK
//
//  Created by Sonal Kachare on 15/12/25.
//


//
//  CTMultiValuePropertyKeyValidator.m
//  CleverTapSDK
//
//  Created by Sonal Kachare on 16/12/25.
//

#import "CTMultiValuePropertyKeyValidator.h"
#import "CTValidationResult.h"
#import "CTUtils.h"

@interface CTMultiValuePropertyKeyValidator ()
@property (nonatomic, strong) CTValidationConfig *config;
@end

@implementation CTMultiValuePropertyKeyValidator

- (instancetype)initWithConfig:(CTValidationConfig *)config {
    if (self = [super init]) {
        _config = config;
    }
    return self;
}

/**
 * Validates a key for multi-value property operations.
 * Extends base validation with multi-value restriction checks.
 *
 * Flow:
 * 1. Perform base key validation (normalization, character filtering, length check)
 * 2. If base validation drops, return immediately
 * 3. Check multi-value restrictions
 * 4. Return appropriate outcome
 */
- (CTValidationResult *)validateKey:(NSString *)key {
    // Step 1: Perform base validation
    CTValidationResult *baseResult = [super validateKey:key];
    
    // Step 2: If base validation failed with drop, return immediately
    if (baseResult.shouldDrop) {
        return baseResult;
    }
    
    // Get cleaned key from base validation
    NSString *cleanedKey = (NSString *)baseResult.cleanedData;
    
    // Step 3: Collect existing warnings from base validation
    NSMutableArray<CTValidationResult *> *allErrors = [NSMutableArray array];
    if (baseResult.outcome == CTValidationOutcomeWarning && baseResult.subResults) {
        [allErrors addObjectsFromArray:baseResult.subResults];
    }
    
    // Step 4: Check multi-value restrictions
    BOOL hasMultiValueViolation = [self checkMultiValueRestrictions:cleanedKey errors:allErrors];
    
    // Step 5: Create final outcome
    return [self createOutcomeWithErrors:allErrors 
                   hasMultiValueViolation:hasMultiValueViolation 
                               cleanedKey:cleanedKey];
}

#pragma mark - Private Methods

/**
 * Checks if the key is restricted for multi-value operations.
 * Uses case-insensitive comparison like Kotlin's Utils.areNamesNormalizedEqual.
 *
 * @param cleanedKey The normalized key to check
 * @param errors Mutable array to add error to if restricted
 * @return YES if the key is restricted, NO otherwise
 */
- (BOOL)checkMultiValueRestrictions:(NSString *)cleanedKey 
                             errors:(NSMutableArray<CTValidationResult *> *)errors {
    
    if (!self.config.restrictedMultiValueFields) {
        return NO;
    }
    
    // Check if key matches any restricted field (case-insensitive)
    for (NSString *restrictedField in self.config.restrictedMultiValueFields) {
        if ([CTUtils areEqualNormalizedName:cleanedKey andName:restrictedField]) {
            // Add drop error for restricted field
            NSString *message = [NSString stringWithFormat:
                @"'%@' is a restricted key for multi-value properties. Use profilePush: for system fields.",
                cleanedKey];
            
            CTValidationResult *error = [CTValidationResult warningWithCode:523
                                                                    message:message
                                                                       data:nil];
            [errors addObject:error];
            return YES;
        }
    }
    
    return NO;
}

/**
 * Creates the appropriate validation outcome based on errors and violations.
 * Multi-value restriction violations are treated as drops.
 *
 * @param errors Array of validation errors/warnings
 * @param hasMultiValueViolation Whether a multi-value restriction was violated
 * @param cleanedKey The cleaned/normalized key
 * @return ValidationResult with appropriate outcome
 */
- (CTValidationResult *)createOutcomeWithErrors:(NSArray<CTValidationResult *> *)errors
                          hasMultiValueViolation:(BOOL)hasMultiValueViolation
                                      cleanedKey:(NSString *)cleanedKey {
    
    // Multi-value violations are drops
    if (hasMultiValueViolation) {
        return [CTValidationResult dropWithSubResults:errors
                                               reason:CTDropReasonRestrictedMultiValueKey];
    }
    
    // No errors - success
    if (errors.count == 0) {
        return [CTValidationResult successWithData:cleanedKey];
    }
    
    // Has warnings but no drops - warning outcome
    return [CTValidationResult warningWithSubResults:errors data:cleanedKey];
}

@end

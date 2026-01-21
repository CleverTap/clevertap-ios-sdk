#import "CTProfileBuilder.h"
#import "CTValidationResult.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTKnownProfileFields.h"
#import "CTLocalDataStore.h"
#import "CTUtils.h"
#import "CTPropertyKeyValidator.h"
#import "CTDataValidator.h"
#import "CTFlattenedEventData.h"

@implementation CTProfileBuilder
static CTPropertyKeyValidator *_profileKeyValidator;
static CTDataValidator *_profileDataValidator;

+ (void)initializeWithValidationConfig:(CTValidationConfig *)validationConfig {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (self == [CTProfileBuilder class]) {
            // Initialize validators with default config
            _profileKeyValidator = [[CTPropertyKeyValidator alloc] initWithConfig:validationConfig];
            _profileDataValidator = [[CTDataValidator alloc] initWithConfig:validationConfig];
        }
    });
}

+ (void)build:(NSDictionary *)profile completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CTValidationResult*>* _Nullable errors))completion {
    NSMutableArray<CTValidationResult*> *errors = [NSMutableArray new];
    
    if (profile == nil || profile.count == 0) {
        completion(nil, nil, errors);
        return;
    }
    @try {
        CTValidationResult *dataResult = [_profileDataValidator validateEventData:profile];
        NSDictionary *cleanedProperties = dataResult.cleanedData;
        if (dataResult.outcome == CTValidationOutcomeWarning && dataResult.subResults.count > 0) {
            for (CTValidationResult *warning in dataResult.subResults) {
                CleverTapLogStaticDebug(@"%@: Property validation - %@", self, warning.errorDesc);
            }
            [errors addObjectsFromArray:dataResult.subResults];
        }
        
        if (dataResult.shouldDrop) {
            // Log error and push to stack
            CleverTapLogStaticDebug(@"%@: Push profile dropped - %@", self, dataResult.errorDesc);
            [errors addObject:dataResult];
            completion(nil, nil, errors);
            return;
        }
        
        NSMutableDictionary *customFields = [NSMutableDictionary new];
        NSMutableDictionary *systemFields = [NSMutableDictionary new];
        // if a reserved key add to systemFields else add to customFields
        NSArray *profileAllKeys = [cleanedProperties allKeys];
        for (int i = 0; i < [cleanedProperties count]; i++) {
            NSString *key = profileAllKeys[(NSUInteger) i];
            id value = cleanedProperties[key];
            
            KnownField kf = [CTKnownProfileFields getKnownFieldIfPossibleForKey:key];
            if (kf != UNKNOWN) {
                systemFields[key] = value;
            } else {
                customFields[key] = value;
            }
        }
        completion(customFields, systemFields, errors);
    } @catch (NSException *e) {
        CleverTapLogStaticInternal(@"%@: error building profile: %@", self, e.debugDescription);
        completion(nil, nil, errors);
    }
}

+ (void)buildRemoveValueForKey:(NSString *)key completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CTValidationResult*>* _Nullable errors))completion {
    NSMutableArray<CTValidationResult*> *errors = [NSMutableArray new];
        
    CTValidationResult *keyValidationResult = [_profileKeyValidator validateKey:key];
    
    if (keyValidationResult.shouldDrop) {
        // Key is restricted or invalid - add all errors and abort
        if (keyValidationResult.subResults) {
            [errors addObjectsFromArray:keyValidationResult.subResults];
        } else {
            [errors addObject:keyValidationResult];
        }
        
        // Log the drop reason
        if (keyValidationResult.dropReason == CTDropReasonRestrictedMultiValueKey) {
            CleverTapLogStaticDebug(@"%@: Property key '%@' is restricted. %@",
                                    self, key, keyValidationResult.errorDesc);
        } else {
            CleverTapLogStaticDebug(@"%@: Property key validation failed: %@",
                                    self, keyValidationResult.errorDesc);
        }
        
        completion(nil, nil, errors);
        return;
    }
    
    if (keyValidationResult.outcome == CTValidationOutcomeWarning) {
        if (keyValidationResult.subResults) {
            [errors addObjectsFromArray:keyValidationResult.subResults];
        } else if (keyValidationResult.errorCode != 0) {
            [errors addObject:keyValidationResult];
        }
        
        // Log warnings
        for (CTValidationResult *warning in keyValidationResult.subResults) {
            CleverTapLogStaticDebug(@"%@: Property key warning [%d]: %@. Cleaned",
                                    self, warning.errorCode, warning.errorDesc);
        }
    }
    
    NSString *cleanedKey = (NSString *)keyValidationResult.cleanedData;
    if (!cleanedKey || [cleanedKey isEqualToString:@""]) {
        [errors addObject:[self _generateEmptyMultiValueErrorForKey:key]];
        completion(nil, nil, errors);
        return;
    }
    completion(@{cleanedKey : @{kCLTAP_COMMAND_DELETE : @(YES)}}, nil, errors);
}


# pragma mark - Multi-Value Handling

# pragma mark Start Multi-Value Handling

+ (void)buildSetMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key localDataStore:(CTLocalDataStore*)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion {
    [self _handleMultiValues:values forKey:key withCommand:CTProfileOperationSet localDataStore:dataStore completionHandler:completion];
}

+ (void)buildAddMultiValue:(NSString *)value forKey:(NSString *)key localDataStore:(CTLocalDataStore*)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion {
    if (value == nil || [value isEqualToString:@""]) {
        NSMutableArray<CTValidationResult*> *errors = [NSMutableArray new];
        [errors addObject:[self _generateEmptyMultiValueErrorForKey:key]];
        completion(nil, nil, errors);
        return;
    }
    [self buildAddMultiValues:@[value] forKey:key localDataStore:dataStore completionHandler:completion];
}

+ (void)buildAddMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key localDataStore:(CTLocalDataStore*)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion {
    [self _handleMultiValues:values forKey:key withCommand:CTProfileOperationAdd localDataStore:dataStore completionHandler:completion];
}

+ (void)buildRemoveMultiValue:(NSString *)value forKey:(NSString *)key localDataStore:(CTLocalDataStore*)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion {
    if (value == nil || [value isEqualToString:@""]) {
        NSMutableArray<CTValidationResult*> *errors = [NSMutableArray new];
        [errors addObject:[self _generateEmptyMultiValueErrorForKey:key]];
        completion(nil, nil, errors);
        return;
    }
    [self buildRemoveMultiValues:@[value] forKey:key localDataStore:dataStore completionHandler:completion];
}

+ (void)buildRemoveMultiValues:(NSArray *)values forKey:(NSString *)key localDataStore:(CTLocalDataStore*)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion {
    [self _handleMultiValues:values forKey:key withCommand:CTProfileOperationArrayRemove localDataStore:dataStore completionHandler:completion];
}

+ (CTValidationResult*)_generateEmptyMultiValueErrorForKey:(NSString *)key {
    return [self _generateInvalidMultiValueError:[NSString stringWithFormat:@"Empty multi-value property value for key %@", key]];
}

+ (CTValidationResult*)_generateInvalidMultiValueKeyErrorForKey:(NSString *)key {
    return [self _generateInvalidMultiValueError:[NSString stringWithFormat:@"Invalid multi-value property key %@", key]];
}

+ (CTValidationResult*) _generateInvalidMultiValueError:(NSString *)message {
    CleverTapLogStaticDebug(@"%@: %@", self, message);
    return [CTValidationResult resultWithErrorCode:512 andMessage:message];
}

+ (void)_handleMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key withCommand:(CTProfileOperation)command localDataStore:(CTLocalDataStore*)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion  {
    NSMutableArray<CTValidationResult*> *errors = [NSMutableArray new];
    if (key == nil) {
        completion(nil, nil, errors);
        return;
    }
    if (values == nil || [values count] <= 0) {
        [errors addObject:[self _generateEmptyMultiValueErrorForKey:key]];
        completion(nil, nil, errors);
        return;
    }
    // make sure the values really are all strings
    NSMutableArray *_allStrings = [NSMutableArray new];
    for (id value in values) {
        @try {
            [_allStrings addObject:[NSString stringWithFormat:@"%@", value]];
        }
        @catch (NSException *e) {
            // no-op
        }
    }
    values = _allStrings;
    @try {
        // validate the multi-value array
        CTValidationResult *dataResult = [_profileDataValidator cleanArray:values forKey:key];
        if (dataResult.shouldDrop) {
            return;
        }
        NSArray *multiValue = [self _constructLocalMultiValueWithOriginalValues:dataResult.cleanedData forKey:key usingCommand:command localDataStore:dataStore];
        if (!multiValue) {
            [errors addObject:[self _generateEmptyMultiValueErrorForKey:key]];
            completion(nil, nil, errors);
            return;
        }
        [self _validateAndPushMultiValue:dataResult.cleanedData forKey:key withOriginalValues:values usingCommand:command completionHandler:completion];
    } @catch (NSException *e) {
        CleverTapLogStaticInternal(@"%@: error in _handleMultiValues forKey: %@ Reason: %@", self, key, e.debugDescription);
        completion(nil, nil, errors);
    }
}



+ (NSArray<NSString *> *) _constructLocalMultiValueWithOriginalValues:(NSArray *)values forKey:(NSString *)key usingCommand:(CTProfileOperation)command localDataStore:(CTLocalDataStore*)dataStore {
    if (!command) {
        CleverTapLogStaticInternal(@"%@: Unknown multi-value command %ld, aborting", self, (long)command);
        return nil;
    }
    BOOL remove = command == CTProfileOperationRemove;
    BOOL add = command == CTProfileOperationAdd;
    NSArray *_existingMultiValue = [self _constructExistingMultiValueForKey:key usingCommand:command localDataStore:dataStore];
    // if its a remove operation and there is no existing multi-value abort
    if (remove && _existingMultiValue == nil) {
        return nil;
    }
    // create a mutable array to operate on
    NSMutableArray *multiValue = (_existingMultiValue == nil) ? [NSMutableArray new] : [_existingMultiValue mutableCopy];
    for (__strong NSString *value in values) {
        @try {
            CTValidationResult *dataResult = [_profileDataValidator validate:value forKey:key];
            NSString *cleanedValue = dataResult.cleanedData;
            
            if (dataResult.outcome == CTValidationOutcomeWarning && dataResult.subResults.count > 0) {
                for (CTValidationResult *warning in dataResult.subResults) {
                    CleverTapLogStaticDebug(@"%@: Property validation while constructing multi values - %@", self, warning.errorDesc);
                }
            }
            if (cleanedValue == nil) {
                CleverTapLogStaticDebug(@"%@: Property validation failed while constructing multi values", self);
                continue;
            }
            long existingIndex = [multiValue indexOfObject:value];
            
            // if its an add or a remove remove the value from its current index in the local copy
            // if its an add we will add it back at the end
            if (add || remove) {
                if (existingIndex != NSNotFound) {
                    [multiValue removeObject:value];
                }
            }
            // if its not a remove add the value to the end of the local copy
            if (!remove) {
                // add the value; for the local copy
                [multiValue addObject:value];
            }
        } @catch (NSException *e) {
            CleverTapLogStaticInternal(@"%@: error %@ when adding value %@ to multi-value property for key %@", self, e.debugDescription, value, key);
            return nil;
        }
    }
    return multiValue;
}

+ (NSArray<NSString *> *) _constructExistingMultiValueForKey:(NSString *)key usingCommand:(CTProfileOperation)command localDataStore:(CTLocalDataStore*)dataStore {
    BOOL remove = command == CTProfileOperationRemove;
    BOOL add = command == CTProfileOperationAdd;
    // only relevant for add's and remove's; a set overrides the existing value
    if (!remove && !add) return nil;
    id existing = [dataStore getProfileFieldForKey:key];
    // if there is no existing value or its already an array just return it
    if (existing == nil || [existing isKindOfClass:[NSArray class]]) return existing;
    // handle a scalar value as the existing value
    /* if its an add, our rule is to promote the scalar value to multi value and include the cleaned stringified scalar value as the first element of the resulting array
     NOTE: the existing scalar value is currently limited to 120 bytes; when adding it to a multi value
     it is subject to the current 40 byte limit
     if its a remove, our rule is to delete the key from the local copy if the cleaned stringified existing value is equal to any of the cleaned values passed to the remove method
     if its an add, return an empty array as the default, in the event the existing scalar value fails stringifying/cleaning
     returning nil will signal that a remove operation should be aborted, as there is no valid promoted multi value to remove against
     */
    NSArray *_default = (add) ? [NSArray new] : nil;
    NSString *stringified = [self _stringifyAndCleanScalarProfilePropValue:existing];
    NSArray *constructedMultiValue = (stringified != nil) ? @[stringified] : _default;
    return constructedMultiValue;
}

+ (NSString *)_stringifyScalarProfilePropValue:(id)value {
    // valid types are NSString or NSNumber
    NSString *stringified = nil;
    @try {
        if ([value isKindOfClass:[NSString class]]) {
            stringified = (NSString *) value;
        }
        if ([value isKindOfClass:[NSNumber class]]) {
            stringified = [(NSNumber *)value stringValue];
        }
    } @catch (NSException *e) {
        // no-op
    }
    return stringified;
}

+ (NSString *)_stringifyAndCleanScalarProfilePropValue:(id)value {
    NSString *ret = [self _stringifyScalarProfilePropValue:value];
    if (ret) {
        @try {
            CTValidationResult *dataResult = [_profileDataValidator validate:ret forKey:nil];
            NSString *cleanedValue = dataResult.cleanedData;
            
            if (dataResult.outcome == CTValidationOutcomeWarning && dataResult.subResults.count > 0) {
                for (CTValidationResult *warning in dataResult.subResults) {
                    CleverTapLogStaticDebug(@"%@: Property validation while constructing multi values - %@", self, warning.errorDesc);
                }
            }
            ret = (cleanedValue != nil) ? (NSString *) cleanedValue : nil;
        } @catch (NSException *e) {
            // no-op
        }
    }
    return ret;
}

+ (void)_validateAndPushMultiValue:(NSArray<NSString *> *)multiValue forKey:(NSString *)key withOriginalValues:(NSArray<NSString *> *)values usingCommand:(CTProfileOperation)operation completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion {
    NSMutableArray<CTValidationResult*> *errors = [NSMutableArray new];
    // if the local copy is nil here it means there has been some kind of problem, so just abort the whole operation
    if (!multiValue) {
        completion(nil, nil, errors);
        return;
    }
    NSString *command = [self getStringForOperation:operation];
    NSDictionary *fields = @{key : @{command : values} };
    
    completion(fields, multiValue, errors);
}

# pragma mark End Multi-Value Handling

+ (id)getJSONKey:(id)jsonObject
          forKey:(NSString *)key
     withDefault:(id)defValue {
    
    if (!jsonObject) return defValue;
    
    id prop = [jsonObject valueForKey:key];
    if (prop)
        return prop;
    else
        return defValue;
}


#pragma mark - Increment and Decrement Operator Handling

+ (void)buildIncrementValueBy:(NSNumber* _Nonnull)value forKey:(NSString* _Nonnull)key localDataStore:(CTLocalDataStore* _Nonnull)dataStore completionHandler: (void(^ _Nonnull )(NSDictionary* _Nullable operatorDict, NSArray<CTValidationResult*>* _Nullable errors))completion {
    [self _handleIncrementDecrementValue:value forKey:key
                             withCommand:kCLTAP_COMMAND_INCREMENT
                          localDataStore:dataStore completionHandler:completion];
}

+ (void)buildDecrementValueBy:(NSNumber* _Nonnull)value forKey:(NSString* _Nonnull)key localDataStore:(CTLocalDataStore* _Nonnull)dataStore completionHandler: (void(^ _Nonnull )(NSDictionary* _Nullable operatorDict, NSArray<CTValidationResult*>* _Nullable errors))completion {
    [self _handleIncrementDecrementValue:value forKey:key
                             withCommand:kCLTAP_COMMAND_DECREMENT
                          localDataStore:dataStore completionHandler:completion];
}

+ (void)_handleIncrementDecrementValue:(NSNumber *_Nonnull)value forKey:(NSString *_Nonnull)key withCommand:(NSString *_Nonnull)command localDataStore:(CTLocalDataStore *_Nonnull)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary *_Nullable operatorDict, NSArray<CTValidationResult *> *_Nullable errors))completion {
    
    if ([key length] == 0) {
        NSMutableArray<CTValidationResult*> *errors = [NSMutableArray new];
        CTValidationResult* error =  [self _generateInvalidMultiValueError: @"Profile key cannot be empty while incrementing/decrementing a property value"];
        
        [errors addObject: error];
        completion(nil, errors);
        return;
    }
    
    if (value && (value.longValue <= 0 || value.floatValue <= 0 || value.doubleValue <= 0)) {
        NSMutableArray<CTValidationResult*> *errors = [NSMutableArray new];
        CTValidationResult* error =  [self _generateInvalidMultiValueError: [NSString stringWithFormat:@"Increment/Decrement value for profile key %@ cannot be zero or negative", key]];
        
        [errors addObject: error];
        completion(nil, errors);
        return;
    }
    
    NSDictionary* operatorDict = @{
        key: @{command: value}
    };
    
    completion(operatorDict, nil);
}

+ (NSNumber *_Nullable)_getUpdatedValue:(NSNumber *_Nonnull)value forKey:(NSString *_Nonnull)key withCommand:(NSString *_Nonnull)command cachedValue:(id)cachedValue {
    // Set the new value to be the increment/decrement value in case there is no cached value
    NSNumber *newValue = value;
    if ([cachedValue isKindOfClass: [NSNumber class]]) {
        NSNumber *cachedNumber = (NSNumber*)cachedValue;
        CFNumberType numberType = CFNumberGetType((CFNumberRef)cachedNumber);
        
        switch (numberType) {
            case kCFNumberSInt8Type:
            case kCFNumberSInt16Type:
            case kCFNumberIntType:
            case kCFNumberSInt32Type:
            case kCFNumberSInt64Type:
            case kCFNumberNSIntegerType:
            case kCFNumberShortType:
                if ([command isEqualToString: kCLTAP_COMMAND_INCREMENT]) {
                    newValue = [NSNumber numberWithInt: cachedNumber.intValue + value.intValue];
                } else {
                    newValue = [NSNumber numberWithInt: cachedNumber.intValue - value.intValue];
                }
                break;
            case kCFNumberLongType:
                if ([command isEqualToString: kCLTAP_COMMAND_INCREMENT]) {
                    newValue = [NSNumber numberWithLong: cachedNumber.longValue + value.longValue];
                } else {
                    newValue = [NSNumber numberWithLong: cachedNumber.longValue - value.longValue];
                }
                break;
            case kCFNumberLongLongType:
                if ([command isEqualToString: kCLTAP_COMMAND_INCREMENT]) {
                    newValue = [NSNumber numberWithLongLong: cachedNumber.longLongValue + value.longLongValue];
                } else {
                    newValue = [NSNumber numberWithLongLong: cachedNumber.longLongValue - value.longLongValue];
                }
                break;
            case kCFNumberFloatType:
            case kCFNumberFloat32Type:
            case kCFNumberFloat64Type:
            case kCFNumberCGFloatType:
                if ([command isEqualToString: kCLTAP_COMMAND_INCREMENT]) {
                    newValue = [NSNumber numberWithFloat: cachedNumber.floatValue + value.floatValue];
                } else {
                    newValue = [NSNumber numberWithFloat: cachedNumber.floatValue - value.floatValue];
                }
                break;
            case kCFNumberDoubleType:
                if ([command isEqualToString: kCLTAP_COMMAND_INCREMENT]) {
                    newValue = [NSNumber numberWithDouble: cachedNumber.doubleValue + value.doubleValue];
                } else {
                    newValue = [NSNumber numberWithDouble: cachedNumber.doubleValue - value.doubleValue];
                }
                break;
            default:
                break;
        }
    }
    return newValue;
}

+ (NSString *)getStringForOperation:(CTProfileOperation)operation {
    switch (operation) {
        case CTProfileOperationAdd:
            return kCLTAP_COMMAND_ADD;
        case CTProfileOperationRemove:
        case CTProfileOperationArrayRemove:
            return kCLTAP_COMMAND_REMOVE;
        case CTProfileOperationSet:
            return kCLTAP_COMMAND_SET;
        case CTProfileOperationIncrement:
            return kCLTAP_COMMAND_INCREMENT;
        case CTProfileOperationDecrement:
            return kCLTAP_COMMAND_DECREMENT;
        default: return @"";
    }
}
@end

#import "CTProfileBuilder.h"
#import "CTValidationResult.h"
#import "CTValidator.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTKnownProfileFields.h"
#import "CTLocalDataStore.h"
#import "CTUtils.h"

// profile commands
static NSString* const kCLTAP_COMMAND_SET = @"$set";
static NSString* const kCLTAP_COMMAND_ADD = @"$add";
static NSString* const kCLTAP_COMMAND_REMOVE = @"$remove";
#define CLTAP_MULTIVAL_COMMANDS @[kCLTAP_COMMAND_SET, kCLTAP_COMMAND_ADD, kCLTAP_COMMAND_REMOVE]

static NSString* kCLTAP_COMMAND_DELETE = @"$delete";

@implementation CTProfileBuilder

+ (void)build:(NSDictionary *)profile completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CTValidationResult*>* _Nullable errors))completion {
    NSMutableArray<CTValidationResult*> *errors = [NSMutableArray new];
    
    if (profile == nil || profile.count == 0) {
        completion(nil, nil, errors);
        return;
    }
    @try {
        NSMutableDictionary *customFields = [NSMutableDictionary new];
        NSMutableDictionary *systemFields = [NSMutableDictionary new];
        
        CTValidationResult *vr;
        NSArray *profileAllKeys = [profile allKeys];
        for (int i = 0; i < [profileAllKeys count]; i++) {
            NSString *key = profileAllKeys[(NSUInteger) i];
            id value = profile[key];
            
            vr = [CTValidator cleanObjectKey:key];
            if ([vr object] == nil || [((NSString *) [vr object]) isEqualToString:@""]) {
                [errors addObject:[CTValidationResult resultWithErrorCode:512 andMessage:[NSString stringWithFormat:@"Invalid user profile key: %@", key]]];
                CleverTapLogStaticDebug(@"Invalid user profile key: %@", key);
                continue;
            }
            key = (NSString *) [vr object];
            if ([vr errorCode] != 0) {
                [errors addObject:vr];
                if ([vr errorDesc] != nil) {
                    CleverTapLogStaticDebug(@"%@", [vr errorDesc]);
                }
            }
            BOOL accepted = false;
            @try {
                vr = [CTValidator cleanObjectValue:value context:CTValidatorContextProfile];
                accepted = [vr object] != nil;
            } @catch (NSException *e) {
                accepted = false;
                vr = nil;
            }
            if (!accepted) {
                if (vr != nil && [vr errorDesc] != nil) {
                    CleverTapLogStaticDebug(@"%@", [vr errorDesc]);
                }
                NSString *errString = [NSString stringWithFormat:@"Invalid value: %@ for user profile field: %@", value, key];
                CTValidationResult *error = [[CTValidationResult alloc] init];
                [error setErrorCode:512];
                [error setErrorDesc:errString];
                [errors addObject:error];
                CleverTapLogStaticDebug(@"%@", errString);
                continue;
            }
            value = [vr object];
            // Check for an error
            if ([vr errorCode] != 0) {
                [errors addObject:vr];
                if ([vr errorDesc] != nil) {
                    CleverTapLogStaticDebug(@"%@: %@", self, [vr errorDesc]);
                }
            }            
            // if a reserved key add to systemFields else add to customFields
            KnownField kf = [CTKnownProfileFields getKnownFieldIfPossibleForKey:key];
            if (kf != UNKNOWN) {
                systemFields[[CTKnownProfileFields getStorageValueForField:kf]] = value;
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

+ (void)buildGraphUser:(id)graphUser completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CTValidationResult*>* _Nullable errors))completion {
    NSMutableArray<CTValidationResult*> *errors = [NSMutableArray new];
    @try {
        if (graphUser == nil || ![graphUser isKindOfClass:[NSDictionary class]]) {
            completion(nil, nil, errors);
            return;
        }
        NSString *name = [self getJSONKey:graphUser forKey:@"name" withDefault:nil];
        if (name) {
            @try {
                CTValidationResult *vr = [CTValidator cleanObjectValue:name context:CTValidatorContextProfile];
                if ([vr object] && [vr.object isKindOfClass:[NSString class]]) {
                    name = (NSString *) [vr object];
                }
                if ([vr errorCode] != 0) {
                    [errors addObject:vr];
                    if ([vr errorDesc] != nil) {
                        CleverTapLogStaticDebug(@"%@: %@", self, [vr errorDesc]);
                    }
                }
            } @catch (NSException *e) {
                name = @"";
            }
        }
        NSString *gender = [self getJSONKey:graphUser forKey:@"gender" withDefault:nil];
        if (gender) {
            if ([CTUtils doesString:gender.lowercaseString startWith:@"m"])
                gender = @"M";
            else if ([CTUtils doesString:gender.lowercaseString startWith:@"f"])
                gender = @"F";
            else
                gender = @"";
        }
        NSString *email = [self getJSONKey:graphUser forKey:@"email" withDefault:nil];
        NSString *birthday = [self getJSONKey:graphUser forKey:@"birthday" withDefault:nil];
        if (birthday) {
            @try {
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:CLTAP_FB_DOB_DATE_FORMAT];
                NSDate *date = [dateFormatter dateFromString:birthday];
                if (date != nil) {
                    birthday = [NSString stringWithFormat:@"$D_%d", (int) ((NSDate *) date).timeIntervalSince1970];
                } else {
                    birthday = @"";
                }
            } @catch (NSException *e) {
                birthday = @"";
            }
        }
        NSString *work;
        @try {
            id workArray = [self getJSONKey:graphUser forKey:@"work" withDefault:nil];
            if (workArray) {
                if ([workArray isKindOfClass:[NSArray class]] && ((int) [(NSArray *) workArray count]) > 0) {
                    work = @"Y";
                } else {
                    work = @"N";
                }
            }
        } @catch (NSException *e) {
            work = nil;
        }
        NSString *education;
        @try {
            id eduArray = [self getJSONKey:graphUser forKey:@"education" withDefault:nil];
            if (eduArray) {
                if ([eduArray isKindOfClass:[NSArray class]] && ((int) [(NSArray *) eduArray count]) > 0) {
                    NSString *fbEdu = [[eduArray lastObject] objectForKey:@"type"];
                    if ([fbEdu.lowercaseString rangeOfString:@"high school"].location != NSNotFound)
                        education = @"School";
                    else if ([fbEdu.lowercaseString rangeOfString:@"college"].location != NSNotFound)
                        education = @"College";
                    else if ([fbEdu.lowercaseString rangeOfString:@"graduate school"].location != NSNotFound)
                        education = @"Graduate";
                    else
                        education = @"";
                } else {
                    education = @"N";
                }
            }
        } @catch (NSException *e) {
            education = @"";
        }
        NSString *fbID = [self getJSONKey:graphUser forKey:@"id" withDefault:nil];
        NSString *married = [self getJSONKey:graphUser forKey:@"relationship_status" withDefault:nil];
        if (married) {
            if ([married.lowercaseString isEqualToString:@"married"]) {
                married = @"Y";
            } else {
                married = @"N";
            }
        }
        NSMutableDictionary *systemFields = [NSMutableDictionary new];
        if (fbID) {
            systemFields[CLTAP_FB_ID] = fbID;
        }
        if (name) {
            systemFields[CLTAP_FB_NAME] = name;
        }
        if (email) {
            systemFields[CLTAP_FB_EMAIL] = email;
        }
        if (gender) {
            systemFields[CLTAP_FB_GENDER] = gender;
        }
        if (education) {
            systemFields[CLTAP_FB_EDUCATION] = education;
        }
        if (work) {
            systemFields[CLTAP_FB_EMPLOYED] = work;
        }
        if (birthday) {
            systemFields[CLTAP_FB_DOB] = birthday;
        }
        if (married) {
            systemFields[CLTAP_FB_MARRIED] = married;
        }
        completion(nil, systemFields, errors);
    } @catch (NSException *e) {
        CleverTapLogStaticDebug(@"%@: Error building a FB profile update: %@", self, e.debugDescription);
        completion(nil, nil, errors);
    }
}

+ (void)buildGooglePlusUser:(id)googleUser completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CTValidationResult*>* _Nullable errors))completion {
    NSMutableArray<CTValidationResult*> *errors = [NSMutableArray new];
    @try {
        if (googleUser == nil) {
            completion(nil, nil, errors);
            return;
        }
        NSString *name = [self getJSONKey:googleUser forKey:@"displayName" withDefault:nil];
        if (name) {
            @try {
                CTValidationResult *vr = [CTValidator cleanObjectValue:name context:CTValidatorContextProfile];
                if (vr.object && [[vr object] isKindOfClass:[NSString class]]) {
                    if ([vr object] == nil || [((NSString *) [vr object]) isEqualToString:@""]) {
                        [errors addObject:vr];
                        CleverTapLogStaticDebug(@"%@: Invalid Google Plus user name: %@", self, name);
                        completion(nil, nil, errors);
                        return;
                    }
                }
                name = (NSString *) [vr object];
                
                if ([vr errorCode] != 0) {
                    [errors addObject:vr];
                    if ([vr errorDesc] != nil) {
                        CleverTapLogStaticDebug(@"%@: %@", self, [vr errorDesc]);
                    }
                }
            } @catch (NSException *e) {
                name = @"";
            }
        }
        NSString *married = [self getJSONKey:googleUser forKey:@"relationshipStatus" withDefault:nil];
        if (married) {
            if ([married.lowercaseString isEqualToString:@"married"]) {
                married = @"Y";
            } else {
                married = @"N";
            }
        }
        NSString *gender = [self getJSONKey:googleUser forKey:@"gender" withDefault:nil];
        if (gender) {
            // Convert to WR format
            if ([CTUtils doesString:gender.lowercaseString startWith:@"m"])
                gender = @"M";
            else if ([CTUtils doesString:gender.lowercaseString startWith:@"f"])
                gender = @"F";
            else
                gender = @"";
        }
        NSString *email;
        id emailArr = [self getJSONKey:googleUser forKey:@"emails" withDefault:nil];
        if (emailArr && [(NSArray *) emailArr count]) {
            @try {
                email = [emailArr firstObject];
                email = [self getJSONKey:email forKey:@"value" withDefault:nil];
            }
            @catch (NSException *exception) {
                email = @"";
            }
        } else {
            email = @"";
        }
        NSString *birthday = [self getJSONKey:googleUser forKey:@"birthday" withDefault:nil];
        if (birthday) {
            @try {
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:CLTAP_GP_DOB_DATE_FORMAT];
                NSDate *date = [dateFormatter dateFromString:birthday];
                
                if (date != nil) {
                    birthday = [NSString stringWithFormat:@"$D_%d", (int) ((NSDate *) date).timeIntervalSince1970];
                } else {
                    birthday = @"";
                }
            } @catch (NSException *e) {
                // Differs from the specs
                birthday = @"";
            }
        }
        NSString *work;
        @try {
            NSMutableArray *workArray = [self getJSONKey:googleUser forKey:@"organizations" withDefault:nil];
            if (workArray) {
                if (((int) [workArray count]) > 0) {
                    @try {
                        for (id org in workArray) {
                            NSString *orgType = [self getJSONKey:org forKey:@"type" withDefault:nil];
                            if (orgType && [orgType.lowercaseString rangeOfString:@"work"].location != NSNotFound) {
                                work = @"Y";
                                break;
                            }
                            work = @"N";
                        }
                    }
                    @catch (NSException *exception) {
                        work = nil;
                    }
                } else {
                    work = @"N";
                }
            }
        } @catch (NSException *e) {
            work = nil;
        }
        NSString *gpID = nil;
        @try {
            gpID = [self getJSONKey:googleUser forKey:@"identifier" withDefault:nil];
        } @catch (NSException *e) {
            // no-op
        }
        NSMutableDictionary *systemFields = [NSMutableDictionary new];
        if (gpID) {
            systemFields[CLTAP_GP_ID] = gpID;
        }
        if (name) {
            systemFields[CLTAP_GP_NAME] = name;
        }
        if (email) {
            systemFields[CLTAP_GP_EMAIL] = email;
        }
        if (gender) {
            systemFields[CLTAP_GP_GENDER] = gender;
        }
        if (work) {
            systemFields[CLTAP_GP_EMPLOYED] = work;
        }
        if (birthday) {
            systemFields[CLTAP_GP_DOB] = birthday;
        }
        if (married) {
            systemFields[CLTAP_GP_MARRIED] = married;
        }
        completion(nil, systemFields, errors);
    } @catch (NSException *e) {
        // We won't get here
        CleverTapLogStaticDebug(@"Creating Google+ profile update event failed: %@", e);
        completion(nil, nil, errors);
    }
}

+ (void)buildRemoveValueForKey:(NSString *)key completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields, NSDictionary* _Nullable systemFields, NSArray<CTValidationResult*>* _Nullable errors))completion {
    NSMutableArray<CTValidationResult*> *errors = [NSMutableArray new];
    CTValidationResult *vr;
    vr = [CTValidator cleanObjectKey:key];
    if ([vr object] == nil || [((NSString *) [vr object]) isEqualToString:@""]) {
        [errors addObject:[CTValidationResult resultWithErrorCode:512 andMessage:[NSString stringWithFormat:@"Invalid profile value for %@", key]]];
        CleverTapLogStaticDebug(@"Invalid user profile key: %@", key);
        completion(nil, nil, errors);
        return;
    }
    key = (NSString *) [vr object];
    if ([vr errorCode] != 0) {
        [errors addObject:vr];
        if ([vr errorDesc] != nil) {
            CleverTapLogStaticDebug(@"%@: %@", self, [vr errorDesc]);
        }
    }
    completion(@{key : @{kCLTAP_COMMAND_DELETE : @(YES)}}, nil, errors);
}

# pragma mark start multi-value handling


+ (void)buildSetMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key localDataStore:(CTLocalDataStore*)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion {
    [self _handleMultiValues:values forKey:key withCommand:kCLTAP_COMMAND_SET localDataStore:dataStore completionHandler:completion];
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
    [self _handleMultiValues:values forKey:key withCommand:kCLTAP_COMMAND_ADD localDataStore:dataStore completionHandler:completion];
}

+ (void)buildRemoveMultiValue:(NSString *)value forKey:(NSString *)key localDataStore:(CTLocalDataStore*)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion {
    if (value == nil || [value isEqualToString:@""]) {
        NSMutableArray<CTValidationResult*> *errors = [NSMutableArray new];
        [errors addObject:[self _generateEmptyMultiValueErrorForKey:key]];
        completion(nil, nil, errors);
    }
    [self buildRemoveMultiValues:@[value] forKey:key localDataStore:dataStore completionHandler:completion];
}

+ (void)buildRemoveMultiValues:(NSArray *)values forKey:(NSString *)key localDataStore:(CTLocalDataStore*)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion {
    [self _handleMultiValues:values forKey:key withCommand:kCLTAP_COMMAND_REMOVE localDataStore:dataStore completionHandler:completion];
}

+ (CTValidationResult*)_generateEmptyMultiValueErrorForKey:(NSString *)key {
    return [self _generateInvalidMultiValueError:[NSString stringWithFormat:@"Empty multi-value property value for key %@", key]];
}

+ (CTValidationResult*)_generateInvalidMultiValueKeyErrorForKey:(NSString *)key {
    return [self _generateInvalidMultiValueError:[NSString stringWithFormat:@"Invalid multi-value property key %@", key]];
}

+ (CTValidationResult*) _generateInvalidMultiValueError:(NSString *)message {
    return [CTValidationResult resultWithErrorCode:512 andMessage:message];
    CleverTapLogStaticDebug(@"%@: %@", self, message);
}

+ (void)_handleMultiValues:(NSArray<NSString *> *)values forKey:(NSString *)key withCommand:(NSString *)command localDataStore:(CTLocalDataStore*)dataStore completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion  {
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
        CTValidationResult *vr;
        // validate key
        vr = [CTValidator cleanMultiValuePropertyKey:key];
        // Check for an error
        if ([vr errorCode] != 0) {
            [errors addObject:vr];
            if ([vr errorDesc] != nil) {
                CleverTapLogStaticDebug(@"%@: %@", self, [vr errorDesc]);
            }
        }
        // if key is empty generate an error and return
        if ([vr object] == nil || [(NSString *) [vr object] isEqualToString:@""]) {
            [errors addObject:[self _generateEmptyMultiValueErrorForKey:key]];
            completion(nil, nil, errors);
            return;
        }
        key = (NSString *) [vr object];
        NSArray *multiValue = [self _constructLocalMultiValueWithOriginalValues:values forKey:key usingCommand:command localDataStore:dataStore];
        if (!multiValue) {
            [errors addObject:[self _generateEmptyMultiValueErrorForKey:key]];
            completion(nil, nil, errors);
            return;
        }
        [self _validateAndPushMultiValue:multiValue forKey:key withOriginalValues:values usingCommand:command completionHandler:completion];
    } @catch (NSException *e) {
        CleverTapLogStaticInternal(@"%@: error in _handleMultiValues forKey: %@ Reason: %@", self, key, e.debugDescription);
        completion(nil, nil, errors);
    }
}

+ (NSArray<NSString *> *) _constructLocalMultiValueWithOriginalValues:(NSArray *)values forKey:(NSString *)key usingCommand:(NSString *)command localDataStore:(CTLocalDataStore*)dataStore {
    if (!command || ![CLTAP_MULTIVAL_COMMANDS containsObject:command]) {
        CleverTapLogStaticInternal(@"%@: Unknown multi-value command %@, aborting", self, command);
        return nil;
    }
    CTValidationResult *vr;
    BOOL remove = [command isEqualToString:kCLTAP_COMMAND_REMOVE];
    BOOL add = [command isEqualToString:kCLTAP_COMMAND_ADD];
    NSArray *_existingMultiValue = [self _constructExistingMultiValueForKey:key usingCommand:command localDataStore:dataStore];
    // if its a remove operation and there is no existing multi-value abort
    if (remove && _existingMultiValue == nil) {
        return nil;
    }
    // create a mutable array to operate on
    NSMutableArray *multiValue = (_existingMultiValue == nil) ? [NSMutableArray new] : [_existingMultiValue mutableCopy];
    for (__strong NSString *value in values) {
        @try {
            vr = [CTValidator cleanMultiValuePropertyValue:value];
            if ([vr errorCode] != 0) {
                if ([vr errorDesc] != nil) {
                    CleverTapLogStaticDebug(@"%@: %@", self, [vr errorDesc]);
                }
            }
            if ([vr object] == nil || [(NSString *) [vr object] isEqualToString:@""]) {
                return nil;
            }
            value = (NSString *) [vr object];
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

+ (NSArray<NSString *> *) _constructExistingMultiValueForKey:(NSString *)key usingCommand:(NSString *)command localDataStore:(CTLocalDataStore*)dataStore {
    BOOL remove = [command isEqualToString:kCLTAP_COMMAND_REMOVE];
    BOOL add = [command isEqualToString:kCLTAP_COMMAND_ADD];
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
            CTValidationResult *vr = [CTValidator cleanMultiValuePropertyValue:ret];
            ret = ([vr object] != nil) ? (NSString *) [vr object] : nil;
        } @catch (NSException *e) {
            // no-op
        }
    }
    return ret;
}

+ (void)_validateAndPushMultiValue:(NSArray<NSString *> *)multiValue forKey:(NSString *)key withOriginalValues:(NSArray<NSString *> *)values usingCommand:(NSString *)command completionHandler:(void(^ _Nonnull )(NSDictionary* _Nullable customFields,  NSArray* _Nullable updatedMultiValue, NSArray<CTValidationResult*>* _Nullable errors))completion {
    NSMutableArray<CTValidationResult*> *errors = [NSMutableArray new];
    // if the local copy is nil here it means there has been some kind of problem, so just abort the whole operation
    if (!multiValue) {
        completion(nil, nil, errors);
        return;
    }
    // validate the multi-value array
    CTValidationResult *vr = [CTValidator cleanMultiValuePropertyArray:multiValue forKey:key];
    // Check for an error
    if ([vr errorCode] != 0) {
        [errors addObject:vr];
        if ([vr errorDesc] != nil) {
            CleverTapLogStaticDebug(@"%@: %@", self, [vr errorDesc]);
        }
    }
    NSArray *updatedMultiValue = (NSArray *) [vr object];
    NSDictionary *fields = @{key : @{command : values} };
    completion(fields, updatedMultiValue, errors);
}

# pragma mark end multi-value handling

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

@end

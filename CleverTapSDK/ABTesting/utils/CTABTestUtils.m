#import "CTABTestUtils.h"

NSString * const kCTSessionVariantKey = @"session_variant";
NSString * const kSnapshotSerializerConfigKey = @"snapshot_class_descriptions";

NSString * const CTABTestEditorSessionStartRequestType = @"matched";
NSString * const CTABTestEditorChangeMessageRequestType = @"change_request";
NSString * const CTABTestEditorClearMessageRequestType = @"clear_request";
NSString * const CTABTestEditorDisconnectMessageRequestType = @"disconnect";
NSString * const CTABTestVarsRequestType = @"test_vars";


static NSDictionary *_varTypeMap;

NSString* const kUnknown = @"unknown";
NSString* const kBool = @"bool";
NSString* const kDouble = @"double";
NSString* const kInteger = @"integer";
NSString* const kString = @"string";
NSString* const kArrayOfBool = @"arrayofbool";
NSString* const kArrayOfDouble = @"arrayofdouble";
NSString* const kArrayOfInteger = @"arrayofinteger";
NSString* const kArrayOfString = @"arrayofstring";
NSString* const kDictionaryOfBool = @"dictionaryofbool";
NSString* const kDictionaryOfDouble = @"dictionaryofdouble";
NSString* const kDictionaryOfInteger = @"dictionaryofinteger";
NSString* const kDictionaryOfString = @"dictionaryofstring";

@implementation CTABTestUtils

+ (void)load {
    _varTypeMap = @{
                    kBool: @(CTVarTypeBool),
                    kDouble: @(CTVarTypeDouble),
                    kInteger: @(CTVarTypeInteger),
                    kString: @(CTVarTypeString),
                    kArrayOfBool: @(CTVarTypeArrayOfBool),
                    kArrayOfDouble: @(CTVarTypeArrayOfDouble),
                    kArrayOfInteger: @(CTVarTypeArrayOfInteger),
                    kArrayOfString: @(CTVarTypeArrayOfString),
                    kDictionaryOfBool: @(CTVarTypeDictionaryOfBool),
                    kDictionaryOfDouble: @(CTVarTypeDictionaryOfDouble),
                    kDictionaryOfInteger: @(CTVarTypeDictionaryOfInteger),
                    kDictionaryOfString: @(CTVarTypeDictionaryOfString)
                    };
}

+ (CTVarType)CTVarTypeFromString:(NSString*_Nonnull)type {
    NSNumber *_type = type != nil ? _varTypeMap[type] : @(CTVarTypeUnknown);
    if (!_type) {
        _type = @(CTVarTypeUnknown);
    }
    return [_type integerValue];
}

+ (NSString* _Nonnull)StringFromCTVarType:(CTVarType)type {
    NSString *val = kUnknown;
    switch (type) {
        case CTVarTypeBool:
            val = kBool;
            break;
        case CTVarTypeDouble:
            val = kDouble;
            break;
        case CTVarTypeInteger:
            val = kInteger;
            break;
        case CTVarTypeString:
            val = kString;
            break;
        case CTVarTypeArrayOfBool:
            val = kArrayOfBool;
            break;
        case CTVarTypeArrayOfDouble:
            val = kArrayOfDouble;
            break;
        case CTVarTypeArrayOfInteger:
            val = kArrayOfInteger;
            break;
        case CTVarTypeArrayOfString:
            val = kArrayOfString;
            break;
        case CTVarTypeDictionaryOfBool:
            val = kDictionaryOfBool;
            break;
        case CTVarTypeDictionaryOfDouble:
            val = kDictionaryOfDouble;
            break;
        case CTVarTypeDictionaryOfInteger:
            val = kDictionaryOfInteger;
            break;
        case CTVarTypeDictionaryOfString:
            val = kDictionaryOfString;
            break;
        default:
            break;
    }
    return val;
}

@end

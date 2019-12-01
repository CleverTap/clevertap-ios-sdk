
#import <Foundation/Foundation.h>

extern NSString * _Nullable const kCTSessionVariantKey;
extern NSString * _Nullable const kSnapshotSerializerConfigKey;

extern NSString * _Nullable const CTABTestEditorChangeMessageRequestType;
extern NSString * _Nullable const CTABTestEditorSessionStartRequestType;
extern NSString * _Nullable const CTABTestEditorClearMessageRequestType;
extern NSString * _Nullable const CTABTestEditorDisconnectMessageRequestType;
extern NSString * _Nullable const CTABTestVarsRequestType;

typedef NS_ENUM(NSUInteger, CTVarType){
    CTVarTypeUnknown,
    CTVarTypeBool,
    CTVarTypeDouble,
    CTVarTypeInteger,
    CTVarTypeString,
    CTVarTypeArrayOfBool,
    CTVarTypeArrayOfDouble,
    CTVarTypeArrayOfInteger,
    CTVarTypeArrayOfString,
    CTVarTypeDictionaryOfBool,
    CTVarTypeDictionaryOfDouble,
    CTVarTypeDictionaryOfInteger,
    CTVarTypeDictionaryOfString,
};

@interface CTABTestUtils : NSObject

+ (CTVarType)CTVarTypeFromString:(NSString*_Nonnull)type;

+ (NSString* _Nonnull)StringFromCTVarType:(CTVarType)type;

@end


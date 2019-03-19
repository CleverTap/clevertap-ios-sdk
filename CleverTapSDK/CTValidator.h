
#import <Foundation/Foundation.h>

typedef NS_ENUM(int, CTValidatorContext) {
    CTValidatorContextEvent,
    CTValidatorContextProfile,
    CTValidatorContextOther
};

@class CTValidationResult;

@interface CTValidator : NSObject

+ (CTValidationResult *)cleanEventName:(NSString *)name;

+ (CTValidationResult *)cleanObjectKey:(NSString *)name;

+ (CTValidationResult *)cleanMultiValuePropertyKey:(NSString *)name;

+ (CTValidationResult *)cleanMultiValuePropertyValue:(NSString *)value;

+ (CTValidationResult *)cleanMultiValuePropertyArray:(NSArray *)multi forKey:(NSString*)key;

+ (CTValidationResult *)cleanObjectValue:(NSObject *)o context:(CTValidatorContext)context;

+ (BOOL)isRestrictedEventName:(NSString *)name;

+ (BOOL)isValidCleverTapId:(NSString *)cleverTapID;


@end

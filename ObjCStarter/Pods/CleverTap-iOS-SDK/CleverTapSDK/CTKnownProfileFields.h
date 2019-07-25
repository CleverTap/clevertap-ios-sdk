#import <Foundation/Foundation.h>

// Needs to start from 100
typedef enum {
    Name = 100, Email, Education, Married, DOB, Birthday, Employed, Gender, Phone, Age, UNKNOWN
} KnownField;

@interface CTKnownProfileFields : NSObject

+ (NSString *)getStorageValueForField:(KnownField)field;

+ (KnownField)getKnownFieldIfPossibleForKey:(NSString *)key;

@end

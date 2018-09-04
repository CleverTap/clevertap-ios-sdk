#import "CTKnownProfileFields.h"
#import "CTConstants.h"

@implementation CTKnownProfileFields {
    
}
+ (NSString *)getStorageValueForField:(KnownField)field {
    switch (field) {
        case Name:
            return CLTAP_USER_NAME;
        case Email:
            return CLTAP_USER_EMAIL;
        case Education:
            return CLTAP_USER_EDUCATION;
        case Married:
            return CLTAP_USER_MARRIED;
        case DOB:
            return CLTAP_USER_DOB;
        case Birthday:
            return CLTAP_USER_BIRTHDAY;
        case Employed:
            return CLTAP_USER_EMPLOYED;
        case Gender:
            return CLTAP_USER_GENDER;
        case Phone:
            return CLTAP_USER_PHONE;
        case Age:
            return CLTAP_USER_AGE;
        default:
            return nil;
    }
}

+ (KnownField)getKnownFieldIfPossibleForKey:(NSString *)key {
    if ([key isEqualToString:@"Name"])
        return Name;
    else if ([key isEqualToString:@"Email"])
        return Email;
    else if ([key isEqualToString:@"Education"])
        return Education;
    else if ([key isEqualToString:@"Married"])
        return Married;
    else if ([key isEqualToString:@"DOB"])
        return DOB;
    else if ([key isEqualToString:@"Birthday"])
        return Birthday;
    else if ([key isEqualToString:@"Employed"])
        return Employed;
    else if ([key isEqualToString:@"Gender"])
        return Gender;
    else if ([key isEqualToString:@"Phone"])
        return Phone;
    else if ([key isEqualToString:@"Age"])
        return Age;
    else
        return UNKNOWN;
}


@end

#import "CTKnownProfileFields.h"
#import "CTConstants.h"

@implementation CTKnownProfileFields {
    
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

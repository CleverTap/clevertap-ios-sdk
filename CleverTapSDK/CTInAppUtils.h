#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CTInAppType){
    CTInAppTypeHTML,
    
};

@interface CTInAppUtils : NSObject

+(CTInAppType)inAppTypeFromString:(NSString*)type;

@end

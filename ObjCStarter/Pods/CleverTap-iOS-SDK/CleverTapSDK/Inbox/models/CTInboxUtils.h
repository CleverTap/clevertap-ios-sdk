#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CTInboxMessageType){
    CTInboxMessageTypeUnknown,
    CTInboxMessageTypeSimple,
    CTInboxMessageTypeMessageIcon,
    CTInboxMessageTypeCarousel,
    CTInboxMessageTypeCarouselImage,
};

@interface CTInboxUtils : NSObject

+ (CTInboxMessageType)inboxMessageTypeFromString:(NSString*_Nonnull)type;
+ (NSString *_Nullable)XibNameForControllerName:(NSString *_Nonnull)controllerName;

@end

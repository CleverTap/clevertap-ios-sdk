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

@end

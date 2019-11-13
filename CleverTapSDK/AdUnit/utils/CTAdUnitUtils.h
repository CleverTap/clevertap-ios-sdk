#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CTAdUnitType){
    CTAdUnitTypeUnknown,
    CTAdUnitTypeSimple,
    CTAdUnitTypeCarousel,
    CTAdUnitTypeCarouselImage,
    CTAdUnitTypeAdUnitIcon,
    CTAdUnitTypeCustomExtras,
};

@interface CTAdUnitUtils : NSObject

+ (CTAdUnitType)adUnitTypeFromString:(NSString*)type;

@end



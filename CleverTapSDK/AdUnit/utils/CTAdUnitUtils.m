#import "CTAdUnitUtils.h"

@implementation CTAdUnitUtils

static NSDictionary *_adUnitTypeMap;

+ (CTAdUnitType)adUnitTypeFromString:(NSString*)type {
    if (_adUnitTypeMap == nil) {
        _adUnitTypeMap = @{
                          @"simple": @(CTAdUnitTypeSimple),
                          @"carousel": @(CTAdUnitTypeCarousel),
                          @"carousel-image": @(CTAdUnitTypeCarouselImage),
                          @"icon-banner": @(CTAdUnitTypeAdUnitIcon),
                          @"custom-banner": @(CTAdUnitTypeCustomExtras)
                          };
    }
    
    NSNumber *_type = type != nil ? _adUnitTypeMap[type] : @(CTAdUnitTypeUnknown);
    if (!_type) {
        _type = @(CTAdUnitTypeUnknown);
    }
    return [_type integerValue];
}

@end


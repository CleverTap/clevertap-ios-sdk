#import "CTInAppUtils.h"

static NSDictionary *_inAppTypeMap;

@implementation CTInAppUtils

+ (void)load {
    _inAppTypeMap = @{
                      @"html": @(CTInAppTypeHTML),
                      };
}

+(CTInAppType)inAppTypeFromString:(NSString*)type {
    NSNumber *_type = _inAppTypeMap[type];
    if (!_type) {
        _type = @(CTInAppTypeHTML);
    }
    return [_type integerValue];
}

@end

#import "CTInboxUtils.h"

static NSDictionary *_inboxMessageTypeMap;

@implementation CTInboxUtils

+ (void)load {
    _inboxMessageTypeMap = @{
                             @"simple": @(CTInboxMessageTypeSimple),
                             @"message-icon": @(CTInboxMessageTypeMessageIcon),
                             @"carousel": @(CTInboxMessageTypeCarousel),
                             @"carousel-image": @(CTInboxMessageTypeCarouselImage),
                             };
}

+ (CTInboxMessageType)inboxMessageTypeFromString:(NSString*)type {
    NSNumber *_type = type != nil ? _inboxMessageTypeMap[type] : @(CTInboxMessageTypeUnknown);
    if (!_type) {
        _type = @(CTInboxMessageTypeUnknown);
    }
    return [_type integerValue];
}

@end

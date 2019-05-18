#import "CTInboxUtils.h"
#if !CLEVERTAP_NO_INBOX_SUPPORT
#import "CTInAppResources.h"
#endif

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

+ (NSString *)XibNameForControllerName:(NSString *)controllerName {
#if CLEVERTAP_NO_INBOX_SUPPORT
    return nil;
#else
    NSMutableString *xib = [NSMutableString stringWithString:controllerName];
    UIApplication *sharedApplication = [CTInAppResources getSharedApplication];
    BOOL landscape = UIInterfaceOrientationIsLandscape(sharedApplication.statusBarOrientation);
    if (landscape) {
        [xib appendString:@"~land"];
    } else {
        [xib appendString:@"~port"];
    }
    return xib;
#endif
}

@end

#import "CleverTap+Inbox.h"

@implementation CTInboxNotificationContentItem

- (instancetype)initWithJSON:(NSDictionary *)jsonObject {
    if (self = [super init]) {
        @try {
            _title = jsonObject[@"title"][@"text"];
            _titleColor = jsonObject[@"title"][@"color"];
            _message = jsonObject[@"body"][@"text"];
            _messageColor = jsonObject[@"body"][@"color"];
            _backgroundColor = jsonObject[@"bg"];
            _iconUrl = jsonObject[@"icon"][@"url"];
            _mediaUrl = jsonObject[@"media"][@"url"];
            _actionUrl = jsonObject[@"action"][@"url"][@"ios"];
            _actionType = jsonObject[@"action"][@"type"];
            
            id buttons = jsonObject[@"action"][@"links"];
            NSMutableArray *_buttons = [NSMutableArray new];
            
            if ([buttons isKindOfClass:[NSArray class]]) {
                buttons = (NSArray *) buttons;
                for (NSDictionary *button in buttons) {
                    [_buttons addObject:button];
                }
            }
            _links = _buttons;
            
        } @catch (NSException *e) {
        }
    }
    return self;
}

@end

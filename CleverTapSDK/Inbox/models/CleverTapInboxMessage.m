#import "CleverTap+Inbox.h"

#if !CLEVERTAP_NO_INBOX_SUPPORT
@interface CTInboxNotificationContentItem ()
- (instancetype) init __unavailable;
- (instancetype)initWithJSON:(NSDictionary *)json;
@end
#endif

@implementation CleverTapInboxMessage

- (instancetype)initWithJSON:(NSDictionary *)json {
    self = [super init];
    if (self) {
        _json = json;
        NSString *id = json[@"id"];
        if (id) {
            _messageId = id;
        }
        NSString *type = json[@"type"];
        if (type) {
            _type = type;
        }
        NSDictionary *media = json[@"media"];
        if (media) {
            _media = media;
        }
        NSString *title = json[@"title"];
        if (title) {
            _title = title;
        }
        NSString *body = json[@"body"];
        if (body) {
            _body = body;
        }
        NSString *imageUrl = json[@"media"][@"url"];
        if (imageUrl) {
            _imageUrl = imageUrl;
        }
        NSString *actionUrl = json[@"media"][@"actionUrl"];
        if (actionUrl) {
            _actionUrl = actionUrl;
        }
        NSDictionary *customData = json[@"kv"];
        if (customData) {
            _customData = customData;
        }
        NSArray *tags = json[@"tags"];
        if (tags) {
            _tags = tags;
        }
        NSString *tagString = [tags componentsJoinedByString:@","];
        if (tagString) {
            _tagString = tagString;
        }
        
        NSMutableArray *_contents = [NSMutableArray new];
        NSMutableArray *contents = json[@"content"];
        
        for (NSDictionary *content in contents) {
            CTInboxNotificationContentItem *ct_content = [[CTInboxNotificationContentItem alloc] initWithJSON:content];
            [_contents addObject:ct_content];
            
            NSString *iconUrl = content[@"icon"][@"url"];
            if (iconUrl) {
                _iconUrl = iconUrl;
            }
        }
        
        _content = _contents;
        
        NSDate *date = json[@"date"];
        _date = date ? date : [NSDate new];
        
        NSDate *expires = json[@"expires"];
        _expires = expires ? expires : nil;
        
        _isRead = [json[@"isRead"] boolValue];
    }
    return self;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@",  self.json];
}

@end

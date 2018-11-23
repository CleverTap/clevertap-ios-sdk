
#import "CleverTap+Inbox.h"

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

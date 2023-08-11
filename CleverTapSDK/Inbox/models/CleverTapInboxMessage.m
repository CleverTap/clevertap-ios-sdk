#import "CleverTap+Inbox.h"

#if !CLEVERTAP_NO_INBOX_SUPPORT
@interface CleverTapInboxMessageContent ()
- (instancetype) init __unavailable;
- (instancetype)initWithJSON:(NSDictionary *)json;
@end
#endif

@implementation CleverTapInboxMessage

- (instancetype)initWithJSON:(NSDictionary *)json {
    self = [super init];
    if (self) {
        _json = json;
        NSString *id = json[@"_id"];
        if (id) {
            _messageId = id;
        }
        NSString *campaignId = json[@"wzrk_id"];
        if (campaignId) {
            _campaignId = campaignId;
        }
        NSArray *customData = json[@"msg"][@"custom_kv"];
        if (customData) {
            _customData = [self getMessageCustomKV:customData];
        }
        NSArray *tags = json[@"msg"][@"tags"];
        if (tags) {
            _tags = tags;
        }
        if ([_tags isKindOfClass:[NSArray class]]) {
            NSString *tagString = [tags componentsJoinedByString:@","];
            if (tagString) {
                _tagString = tagString;
            }
        }
        NSString *backgroundColor = json[@"msg"][@"bg"];
        if (backgroundColor) {
            _backgroundColor = backgroundColor;
        }
        NSString *orientation = json[@"msg"][@"orientation"];
        if (orientation) {
            _orientation = orientation;
        }
        NSString *type = json[@"msg"][@"type"];
        if (type) {
            _type = type;
        }
        
        NSMutableArray *_contents = [NSMutableArray new];
        
#if !CLEVERTAP_NO_INBOX_SUPPORT
        NSMutableArray *contents = json[@"msg"][@"content"];
        for (NSDictionary *content in contents) {
            CleverTapInboxMessageContent *ct_content = [[CleverTapInboxMessageContent alloc] initWithJSON:content];
            if (ct_content) {
                [_contents addObject:ct_content];
            }
        }
#endif
        _content = _contents;
        
        _date = (long)[json[@"date"] longValue];
        
        NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:_date];
        NSString *relativeDate = [self relativeDateStringForDate:date];
        if (relativeDate ) {
            _relativeDate = relativeDate ;
        }
        
        NSUInteger expires = [json[@"wzrk_ttl"] longValue];
        _expires = expires? expires : 0;
        
        _isRead = [json[@"isRead"] boolValue];
    }
    return self;
}

- (void)setRead:(BOOL)read {
    _isRead = read;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@",  self.json];
}

- (NSString *)relativeDateStringForDate:(NSDate *)date
{
    NSCalendarUnit units = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitDay | NSCalendarUnitWeekOfYear | NSCalendarUnitMonth | NSCalendarUnitYear;
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:units
                                                                   fromDate:date
                                                                     toDate:[NSDate date]
                                                                    options:0];
    
    if (components.year > 0 || components.month > 0 || components.weekOfYear > 0 || components.day > 2) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"dd MMM"];
        NSString *dateString = [formatter stringFromDate:date];
        return dateString;
    } else if (components.day > 0 && components.day < 3) {
        return (components.day > 1) ? [NSString stringWithFormat:@"%ld days ago", (long)components.day] : @"Yesterday";
    } else if (components.hour > 0) {
        return (components.hour > 1) ? [NSString stringWithFormat:@"%ld hours ago", (long)components.hour] : [NSString stringWithFormat:@"%ld hour ago", (long)components.hour];
    } else if (components.minute > 0) {
        return (components.minute > 1) ? [NSString stringWithFormat:@"%ld minutes ago", (long)components.minute] : [NSString stringWithFormat:@"%ld minute ago", (long)components.minute];
    } else {
        return @"Just now";
    }
}

- (NSDictionary *)getMessageCustomKV:(NSArray *)data {
    NSMutableDictionary *customKV = [NSMutableDictionary new];
    for (NSUInteger i = 0; i < [data count]; ++i) {
        NSDictionary *kv = data[i];
        if ([kv objectForKey:@"key"]) {
            NSString *key = kv[@"key"];
            if ([kv objectForKey:@"value"]) {
                NSDictionary *value = kv[@"value"];
                if ([value objectForKey:@"text"]) {
                    NSString *text = value[@"text"];
                    customKV[key] = text;
                }
            }
        }
    }
    return customKV;
}

@end

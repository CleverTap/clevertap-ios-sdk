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
        NSMutableArray *contents = json[@"msg"][@"content"];
        
        for (NSDictionary *content in contents) {
            CleverTapInboxMessageContent *ct_content = [[CleverTapInboxMessageContent alloc] initWithJSON:content];
            [_contents addObject:ct_content];
        }
        _content = _contents;
        
        NSString *timeStamp = json[@"date"];
        NSDate *date;
        if (timeStamp && ![timeStamp isEqual:[NSNull null]]) {
            NSTimeInterval _interval = [timeStamp doubleValue];
            date = [NSDate dateWithTimeIntervalSince1970:_interval];
        }
        _date = date ? date : [NSDate new];
        
        NSString *relativeDate = [self relativeDateStringForDate:_date];
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
    
    if (components.year > 0) {
        return [NSString stringWithFormat:@"%ld years ago", (long)components.year];
    } else if (components.month > 0) {
        return [NSString stringWithFormat:@"%ld months ago", (long)components.month];
    } else if (components.weekOfYear > 0) {
        return [NSString stringWithFormat:@"%ld weeks ago", (long)components.weekOfYear];
    } else if (components.day > 0) {
        return (components.day > 1) ? [NSString stringWithFormat:@"%ld days ago", (long)components.day] : @"Yesterday";
    } else if (components.hour > 0) {
        return (components.hour > 1) ? [NSString stringWithFormat:@"%ld hours ago", (long)components.minute] : [NSString stringWithFormat:@"%ld hour ago", (long)components.hour];
    } else if (components.minute > 0) {
        return (components.minute > 1) ? [NSString stringWithFormat:@"%ld minutes ago", (long)components.minute] : [NSString stringWithFormat:@"%ld minute ago", (long)components.minute];
    } else {
       return @"Now";
    }
}

@end

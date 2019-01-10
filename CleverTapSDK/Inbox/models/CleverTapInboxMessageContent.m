#import "CleverTap+Inbox.h"

@implementation CleverTapInboxMessageContent

- (instancetype)initWithJSON:(NSDictionary *)jsonObject {
    if (self = [super init]) {
        @try {
            _title = jsonObject[@"title"][@"text"];
            _titleColor = jsonObject[@"title"][@"color"];
            _message = jsonObject[@"message"][@"text"];
            _messageColor = jsonObject[@"message"][@"color"];
            _iconUrl = jsonObject[@"icon"][@"url"];
            _mediaUrl = jsonObject[@"media"][@"url"];
            if ([jsonObject[@"action"][@"url"][@"ios"] isKindOfClass:[NSDictionary class]]) {
                _actionUrl = jsonObject[@"action"][@"url"][@"ios"][@"text"];
            }
            
            _actionHasUrl = [(jsonObject[@"action"][@"hasUrl"]) boolValue];
            _actionHasLinks = [(jsonObject[@"action"][@"hasLinks"]) boolValue];
            
            NSDictionary *_media = (NSDictionary*) jsonObject[@"media"];
            if (_media) {
                NSString *contentType = _media[@"content_type"];
                NSString *_mediaUrl = _media[@"url"];
                if (_mediaUrl) {
                    if ([contentType hasPrefix:@"image"]) {
                        if ([contentType isEqualToString:@"image/gif"] ) {
                            _mediaIsGif = YES;
                        }else {
                            _mediaIsImage = YES;
                        }
                    } else {
                        if ([contentType hasPrefix:@"video"]) {
                            _mediaIsVideo = YES;
                        }
                        if ([contentType hasPrefix:@"audio"]) {
                            _mediaIsAudio = YES;
                        }
                    }
                }
            }
            
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

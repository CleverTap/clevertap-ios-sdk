#import "CleverTap+DisplayUnit.h"
#import "CTConstants.h"

@implementation CleverTapDisplayUnitContent

- (instancetype)initWithJSON:(NSDictionary *)jsonObject {
    if (self = [super init]) {
        @try {
           _title = jsonObject[@"title"][@"text"];
           _titleColor = jsonObject[@"title"][@"color"];
           _message = jsonObject[@"message"][@"text"];
           _messageColor = jsonObject[@"message"][@"color"];
           _iconUrl = jsonObject[@"icon"][@"url"];
           _mediaUrl = jsonObject[@"media"][@"url"];
           _videoPosterUrl = jsonObject[@"media"][@"poster"];
            
           if ([jsonObject[@"action"][@"url"][@"ios"] isKindOfClass:[NSDictionary class]]) {
                _actionUrl = jsonObject[@"action"][@"url"][@"ios"][@"text"];
           }
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
        } @catch (NSException *e) {
            CleverTapLogStaticDebug(@"Error intitializing CleverTapDisplayUnitContent: %@", e.reason);
            return nil;
        }
    }
    return self;
}

@end

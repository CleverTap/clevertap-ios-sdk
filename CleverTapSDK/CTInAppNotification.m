#import "CTInAppNotification.h"
#import "CTConstants.h"
#import "CTUIUtils.h"
#if !(TARGET_OS_TV)
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDAnimatedImageView.h>
#endif

@interface CTInAppNotification() {
    
}

@property (nonatomic, readwrite) NSString *Id;
@property (nonatomic, readwrite) NSString *campaignId;
@property (nonatomic, readwrite) CTInAppType inAppType;

@property (nonatomic, strong, readwrite) NSURL *imageURL;
@property (nonatomic, strong, readwrite) NSURL *imageUrlLandscape;

@property (nonatomic, readwrite, strong) UIImage *inAppImage;
@property (nonatomic, readwrite, strong) UIImage *inAppImageLandscape;
@property (nonatomic, readwrite, strong) NSData *imageData;
@property (nonatomic, readwrite, strong) NSData *imageLandscapeData;
@property (nonatomic, copy, readwrite) NSString *contentType;
@property (nonatomic, copy, readwrite) NSString *landscapeContentType;
@property (nonatomic, copy, readwrite) NSString *mediaUrl;

@property (nonatomic, readwrite) NSString *title;
@property (nonatomic, readwrite) NSString *titleColor;
@property (nonatomic, readwrite) NSString *message;
@property (nonatomic, readwrite) NSString *messageColor;

@property (nonatomic, readwrite) NSString *backgroundColor;

@property (nonatomic, readwrite, assign) BOOL hideMedia;
@property (nonatomic, readwrite, assign) BOOL showCloseButton;
@property (nonatomic, readwrite, assign) BOOL tablet;
@property (nonatomic, readwrite, assign) BOOL hasLandscape;
@property (nonatomic, readwrite, assign) BOOL hasPortrait;

@property (nonatomic, copy, readwrite) NSString *html;
@property (nonatomic, copy, readwrite) NSString *url;
@property (nonatomic, readwrite) BOOL showClose;
@property (nonatomic, readwrite) BOOL darkenScreen;
@property (nonatomic, readwrite) BOOL excludeFromCaps;
@property (nonatomic, readwrite) int maxPerSession;
@property (nonatomic, readwrite) int totalLifetimeCount;
@property (nonatomic, readwrite) int totalDailyCount;
@property (nonatomic, readwrite) NSInteger timeToLive;
@property (nonatomic, assign, readwrite) char position;
@property (nonatomic, assign, readwrite) float height;
@property (nonatomic, assign, readwrite) float heightPercent;
@property (nonatomic, assign, readwrite) float width;
@property (nonatomic, assign, readwrite) float widthPercent;

@property (nonatomic, readwrite) NSArray<CTNotificationButton *> *buttons;

@property (nonatomic, copy, readwrite) NSDictionary *jsonDescription;
@property (nonatomic, copy, readwrite) NSDictionary *customExtras;

@property (nonatomic, readwrite) BOOL isLocalInApp;
@property (nonatomic, readwrite) BOOL isPushSettingsSoftAlert;
@property (nonatomic, readwrite) BOOL fallBackToNotificationSettings;
@property (nonatomic, readwrite) BOOL skipSettingsAlert;

@property (nonatomic, readwrite) CTCustomTemplateInAppData *customTemplateInAppData;

@end

@implementation CTInAppNotification: NSObject

@synthesize mediaIsImage=_mediaIsImage;
@synthesize mediaIsGif=_mediaIsGif;
@synthesize mediaIsAudio=_mediaIsAudio;
@synthesize mediaIsVideo=_mediaIsVideo;

- (instancetype)initWithJSON:(NSDictionary *)jsonObject {
    if (self = [super init]) {
        @try {
            self.inAppType = CTInAppTypeUnknown;
            self.jsonDescription = jsonObject;
            self.campaignId = (NSString*) jsonObject[CLTAP_NOTIFICATION_ID_TAG];
            if (jsonObject[CLTAP_INAPP_EXCLUDE_GLOBAL_CAPS] != nil) {
                self.excludeFromCaps = [jsonObject[CLTAP_INAPP_EXCLUDE_GLOBAL_CAPS] boolValue];
            } else {
                self.excludeFromCaps = [jsonObject[CLTAP_INAPP_EXCLUDE_FROM_CAPS] boolValue];
            }
            self.maxPerSession = jsonObject[CLTAP_INAPP_MAX_PER_SESSION] ? [jsonObject[CLTAP_INAPP_MAX_PER_SESSION] intValue] : -1;
            self.totalLifetimeCount = jsonObject[CLTAP_INAPP_TOTAL_LIFETIME_COUNT] ? [jsonObject[CLTAP_INAPP_TOTAL_LIFETIME_COUNT] intValue] : -1;
            self.totalDailyCount = jsonObject[CLTAP_INAPP_TOTAL_DAILY_COUNT] ? [jsonObject[CLTAP_INAPP_TOTAL_DAILY_COUNT] intValue] : -1;
            self.isLocalInApp = jsonObject[@"isLocalInApp"] ? [jsonObject[@"isLocalInApp"] boolValue] : NO;
            self.isPushSettingsSoftAlert = jsonObject[@"isPushSettingsSoftAlert"] ? [jsonObject[@"isPushSettingsSoftAlert"] boolValue] : NO;
            self.fallBackToNotificationSettings = jsonObject[@"fallbackToNotificationSettings"] ? [jsonObject[@"fallbackToNotificationSettings"] boolValue] : NO;
            self.skipSettingsAlert = jsonObject[@"skipSettingsAlert"] ? [jsonObject[@"skipSettingsAlert"] boolValue] : NO;
            NSString *inAppId = [CTInAppNotification inAppId:jsonObject];
            if (inAppId) {
                self.Id = inAppId;
            }
            NSString *type = (NSString*) jsonObject[@"type"];
            if (!type || [type isEqualToString:CLTAP_INAPP_HTML_TYPE]) {
                [self legacyConfigureFromJSON:jsonObject];
            } else {
                [self configureFromJSON:jsonObject];
                self.customTemplateInAppData = [CTCustomTemplateInAppData createWithJSON:jsonObject];
            }
            if (self.inAppType == CTInAppTypeUnknown) {
                self.error = @"Unknown InApp Type";
            }
            
            NSUInteger timeToLive = [jsonObject[CLTAP_INAPP_TTL] longValue];
            if (timeToLive) {
                _timeToLive = timeToLive;
            } else {
                NSDate *now = [NSDate date];
                NSDate *timeToLiveDate = [now dateByAddingTimeInterval:(48 * 60 * 60)];
                NSTimeInterval timeToLiveEpoch = [timeToLiveDate timeIntervalSince1970];
                NSInteger defaultTimeToLive = (long)timeToLiveEpoch;
                _timeToLive = defaultTimeToLive;
            }
        } @catch (NSException *e) {
            self.error = e.debugDescription;
        }
    }
    return self;
}

- (void)configureFromJSON: (NSDictionary *)jsonObject {
    self.inAppType = [CTInAppUtils inAppTypeFromString:jsonObject[@"type"]];
    self.backgroundColor = jsonObject[@"bg"];
    self.title = (NSString*) jsonObject[@"title"][@"text"];
    self.titleColor = (NSString*) jsonObject[@"title"][@"color"];
    self.message = (NSString*) jsonObject[@"message"][@"text"];
    self.messageColor = (NSString*) jsonObject[@"message"][@"color"];
    self.showCloseButton = [jsonObject[@"close"] boolValue];
    self.tablet = [jsonObject[@"tablet"] boolValue];
    self.hasPortrait = jsonObject[@"hasPortrait"] ? [jsonObject[@"hasPortrait"] boolValue] : YES;
    self.hasLandscape = jsonObject[@"hasLandscape"] ? [jsonObject[@"hasLandscape"] boolValue] : NO;
    NSDictionary *_media = (NSDictionary*) jsonObject[CLTAP_INAPP_MEDIA];
    if (_media) {
        self.contentType = _media[CLTAP_INAPP_MEDIA_CONTENT_TYPE];
        NSString *_mediaUrl = _media[CLTAP_INAPP_MEDIA_URL];
        if (_mediaUrl && _mediaUrl.length > 0) {
            if ([self.contentType hasPrefix:@"image"]) {
                self.imageURL = [NSURL URLWithString:_mediaUrl];
                if ([self.contentType isEqualToString:@"image/gif"] ) {
                    _mediaIsGif = YES;
                }else {
                    _mediaIsImage = YES;
                }
            } else {
                self.mediaUrl = _mediaUrl;
                if ([self.contentType hasPrefix:@"video"]) {
                    _mediaIsVideo = YES;
                }
                if ([self.contentType hasPrefix:@"audio"]) {
                    _mediaIsAudio = YES;
                }
            }
        }
    }
    
    NSDictionary *_mediaLandscape = (NSDictionary*) jsonObject[CLTAP_INAPP_MEDIA_LANDSCAPE];
    if (_mediaLandscape) {
        self.landscapeContentType = _mediaLandscape[CLTAP_INAPP_MEDIA_CONTENT_TYPE];
        NSString *_mediaUrlLandscape = _mediaLandscape[CLTAP_INAPP_MEDIA_URL];
        if (_mediaUrlLandscape && _mediaUrlLandscape.length > 0) {
            if ([self.landscapeContentType hasPrefix:@"image"]) {
                self.imageUrlLandscape = [NSURL URLWithString:_mediaUrlLandscape];
                if (![self.landscapeContentType isEqualToString:@"image/gif"] ) {
                    _mediaIsImage = YES;
                }
            }
        }
    }
    
    id buttons = jsonObject[@"buttons"];
    
    NSMutableArray *_buttons = [NSMutableArray new];
    
    if ([buttons isKindOfClass:[NSArray class]]) {
        buttons = (NSArray *) buttons;
        for (NSDictionary *button in buttons) {
            CTNotificationButton *ct_button = [[CTNotificationButton alloc] initWithJSON:button];
            if (ct_button && !ct_button.error) {
                [_buttons addObject:ct_button];
            }
        }
    }
    else if ([buttons isKindOfClass:[NSDictionary class]]) {
        buttons = (NSDictionary*) buttons;
        for (NSString *key in [buttons allKeys]) {
            CTNotificationButton *ct_button = [[CTNotificationButton alloc] initWithJSON:buttons[key]];
            if (ct_button && !ct_button.error) {
                [_buttons addObject:ct_button];
            }
        }
    }
    self.buttons = _buttons;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.hasPortrait && !self.hasLandscape && [self deviceOrientationIsLandscape]) {
            self.error = [NSString stringWithFormat:@"The in-app in %@, dismissing %@ InApp Notification.", @"portrait", @"landscape"];
            return;
        }
        
        if (self.hasLandscape && !self.hasPortrait && ![self deviceOrientationIsLandscape]) {
            self.error = [NSString stringWithFormat:@"The in-app in %@, dismissing %@ InApp Notification.", @"landscape", @"portrait"];
            return;
        }
    });
    
    switch (self.inAppType) {
        case CTInAppTypeHeader:
        case CTInAppTypeFooter:
            if  (_mediaIsGif || _mediaIsAudio || _mediaIsVideo){
                self.imageURL = nil;
                CleverTapLogStaticDebug(@"unable to download media, wrong media type for template");
            }
            break;
        case CTInAppTypeCoverImage:
        case CTInAppTypeInterstitialImage:
        case CTInAppTypeHalfInterstitialImage:
            if  (_mediaIsGif || _mediaIsAudio || _mediaIsVideo || !_mediaIsImage){
                self.error = [NSString stringWithFormat:@"wrong media type for template"];
            }
            break;
        case CTInAppTypeCover:
        case CTInAppTypeHalfInterstitial:
            if  (_mediaIsGif || _mediaIsAudio || _mediaIsVideo){
                self.imageURL = nil;
                CleverTapLogStaticDebug(@"unable to download media, wrong media type for template");
            }
            break;
        default:
            break;
    }
}

- (void)legacyConfigureFromJSON:(NSDictionary *)jsonObject {
    if (![self validateLegacyJSON:jsonObject]) {
        self.error = @"Invalid JSON";
        return;
    }
    NSDictionary *data = (NSDictionary*) jsonObject[@"d"];
    if (data) {
        NSString *html = (NSString*) data[@"html"];
        if (html) {
            self.html = html;
            self.inAppType = [CTInAppUtils inAppTypeFromString:CLTAP_INAPP_HTML_TYPE];
        }
        NSString *url = (NSString*) data[@"url"];
        if (url && url.length > 5) {
            self.url = url;
            self.inAppType = [CTInAppUtils inAppTypeFromString:CLTAP_INAPP_HTML_TYPE];
        } else {
            if (url) {
                self.error = [NSString stringWithFormat:@"Invalid url: %@",url];
                return;
            }
        }
        NSDictionary* customExtras = (NSDictionary *) data[@"kv"];
        if (!customExtras) customExtras = [NSDictionary new];
        self.customExtras = customExtras;
        self.hasLandscape = YES;
        self.hasPortrait = YES;
    }
    NSDictionary *displayParams = jsonObject[@"w"];
    if (displayParams) {
        self.darkenScreen = [displayParams[CLTAP_INAPP_NOTIF_DARKEN_SCREEN] boolValue];
        self.showClose = [displayParams[CLTAP_INAPP_NOTIF_SHOW_CLOSE] boolValue];
        self.position = (char) [displayParams[CLTAP_INAPP_POSITION] characterAtIndex:0];
        self.width = displayParams[CLTAP_INAPP_X_DP] ? [displayParams[CLTAP_INAPP_X_DP] floatValue] : 0.0;
        self.widthPercent = displayParams[CLTAP_INAPP_X_PERCENT] ? [displayParams[CLTAP_INAPP_X_PERCENT] floatValue] : 0.0;
        self.height = displayParams[CLTAP_INAPP_Y_DP] ? [displayParams[CLTAP_INAPP_Y_DP] floatValue] : 0.0;
        self.heightPercent = displayParams[CLTAP_INAPP_Y_PERCENT] ? [displayParams[CLTAP_INAPP_Y_PERCENT] floatValue] : 0.0;
        self.maxPerSession = displayParams[CLTAP_INAPP_MAX_PER_SESSION] ? [displayParams[CLTAP_INAPP_MAX_PER_SESSION] intValue] : -1;
    }
}

- (BOOL)mediaIsAudio {
    return _mediaIsAudio;
}

- (BOOL)mediaIsImage {
    return _mediaIsImage;
}
- (BOOL)mediaIsGif {
    return _mediaIsGif;
}

- (BOOL)mediaIsVideo {
    return _mediaIsVideo;
}

- (BOOL)deviceOrientationIsLandscape {
#if (TARGET_OS_TV)
    return nil;
#else
    return [CTUIUtils isDeviceOrientationLandscape];
#endif
}

- (void)setPreparedInAppImage:(UIImage *)inAppImage
               inAppImageData:(NSData *)inAppImageData error:(NSString *)error {
    self.error = error;
    self.inAppImage = inAppImage;
    self.imageData = inAppImageData;
}

- (void)setPreparedInAppImageLandscape:(UIImage *)inAppImageLandscape
               inAppImageLandscapeData:(NSData *)inAppImageLandscapeData error:(NSString *)error {
    self.error = error;
    self.inAppImageLandscape = inAppImageLandscape;
    self.imageLandscapeData = inAppImageLandscapeData;
}

- (BOOL)validateLegacyJSON:(NSDictionary *)jsonObject {
    // Check that either xdp or xp is set
    NSDictionary *w = jsonObject[@"w"];
    if (![self isKeyValidInDictionary:w forKey:CLTAP_INAPP_X_DP ofClass:[NSNumber class]]) if (![self isKeyValidInDictionary:w forKey:CLTAP_INAPP_X_PERCENT ofClass:[NSNumber class]])
        return FALSE;
    
    // Check that either ydp or yp is set
    if (![self isKeyValidInDictionary:w forKey:CLTAP_INAPP_Y_DP ofClass:[NSNumber class]]) if (![self isKeyValidInDictionary:w forKey:CLTAP_INAPP_Y_PERCENT ofClass:[NSNumber class]])
        return FALSE;
    
    // Check that dk is set
    if ([self isKeyValidInDictionary:w forKey:CLTAP_INAPP_NOTIF_DARKEN_SCREEN ofClass:[NSNumber class]]) {
        @try {
            [w[CLTAP_INAPP_NOTIF_DARKEN_SCREEN] boolValue];
        }
        @catch (NSException *exception) {
            return FALSE;
        }
    } else {
        return FALSE;
    }
    
    // Check that sc is set
    if ([self isKeyValidInDictionary:w forKey:CLTAP_INAPP_NOTIF_SHOW_CLOSE ofClass:[NSNumber class]]) {
        @try {
            [w[CLTAP_INAPP_NOTIF_SHOW_CLOSE] boolValue];
        }
        @catch (NSException *exception) {
            return FALSE;
        }
    } else {
        return FALSE;
    }
    
    NSDictionary *d = jsonObject[@"d"];
    // Check that html is set
    if (![self isKeyValidInDictionary:d forKey:@"html" ofClass:[NSString class]])
        return FALSE;
    
    // Check that pos contains the right value
    if ([self isKeyValidInDictionary:w forKey:CLTAP_INAPP_POSITION ofClass:[NSString class]]) {
        char pos = (char) [w[CLTAP_INAPP_POSITION] characterAtIndex:0];
        switch (pos) {
            case CLTAP_INAPP_POSITION_TOP:
                break;
            case CLTAP_INAPP_POSITION_RIGHT:
                break;
            case CLTAP_INAPP_POSITION_BOTTOM:
                break;
            case CLTAP_INAPP_POSITION_LEFT:
                break;
            case CLTAP_INAPP_POSITION_CENTER:
                break;
            default:
                return false;
        }
    } else
        return false;
    
    return true;
}

- (BOOL)isKeyValidInDictionary:(NSDictionary *)d forKey:(NSString *)key ofClass:(Class)type {
    if (d[key] != nil) {
        if ([d[key] isKindOfClass:type]) {
            return TRUE;
        }
    }
    return FALSE;
}

+ (NSString * _Nullable)inAppId:(NSDictionary * _Nullable)inApp {
    if (inApp && inApp[CLTAP_INAPP_ID]) {
        NSString *inAppId = [NSString stringWithFormat:@"%@", inApp[CLTAP_INAPP_ID]];
        if ([inAppId length] > 0) {
            return inAppId;
        }
    }
    return nil;
}

@end

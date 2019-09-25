#import "CTInAppNotification.h"
#import "CTConstants.h"
#import "CTInAppResources.h"
#if !(TARGET_OS_TV)
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDAnimatedImageView.h>
#endif

@interface CTInAppNotification() {
}

@property (nonatomic, readwrite) NSString *Id;
@property (nonatomic, readwrite) NSString *campaignId;
@property (nonatomic, readwrite) NSString *type;
@property (nonatomic, readwrite) CTInAppType inAppType;

@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) NSURL *imageUrlLandscape;

@property (nonatomic, readwrite, strong) NSData *image;
@property (nonatomic, readwrite, strong) NSData *imageLandscape;
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
@property (nonatomic, assign, readwrite) char position;
@property (nonatomic, assign, readwrite) float height;
@property (nonatomic, assign, readwrite) float heightPercent;
@property (nonatomic, assign, readwrite) float width;
@property (nonatomic, assign, readwrite) float widthPercent;

@property (nonatomic, readwrite) NSArray<CTNotificationButton *> *buttons;

@property (nonatomic, copy, readwrite) NSDictionary *jsonDescription;
@property (nonatomic, copy, readwrite) NSDictionary *customExtras;

@property (nonatomic, readwrite) NSString *error;

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
            self.campaignId = (NSString*) jsonObject[@"wzrk_id"];
            self.excludeFromCaps = [jsonObject[@"efc"] boolValue];
            self.totalLifetimeCount = jsonObject[@"tlc"] ? [jsonObject[@"tlc"] intValue] : -1;
            self.totalDailyCount = jsonObject[@"tdc"] ? [jsonObject[@"tdc"] intValue] : -1;
            if (jsonObject[@"ti"]) {
                self.Id = [NSString stringWithFormat:@"%@", jsonObject[@"ti"]];
            }
            NSString *type = (NSString*) jsonObject[@"type"];
            if (!type || [type isEqualToString:@"custom-html"]) {
                [self legacyConfigureFromJSON:jsonObject];
            } else {
                [self configureFromJSON:jsonObject];
            }
            if (self.inAppType == CTInAppTypeUnknown) {
                self.error = @"Unknown InApp Type";
            }
        } @catch (NSException *e) {
            self.error = e.debugDescription;
        }
    }
    return self;
}

- (void)configureFromJSON: (NSDictionary *)jsonObject {
    self.type = (NSString*) jsonObject[@"type"];
    if (self.type) {
        self.inAppType = [CTInAppUtils inAppTypeFromString:self.type];
    }
    self.backgroundColor = jsonObject[@"bg"];
    self.title = (NSString*) jsonObject[@"title"][@"text"];
    self.titleColor = (NSString*) jsonObject[@"title"][@"color"];
    self.message = (NSString*) jsonObject[@"message"][@"text"];
    self.messageColor = (NSString*) jsonObject[@"message"][@"color"];
    self.showCloseButton = [jsonObject[@"close"] boolValue];
    self.tablet = [jsonObject[@"tablet"] boolValue];
    self.hasPortrait = jsonObject[@"hasPortrait"] ? [jsonObject[@"hasPortrait"] boolValue] : YES;
    self.hasLandscape = jsonObject[@"hasLandscape"] ? [jsonObject[@"hasLandscape"] boolValue] : NO;
    NSDictionary *_media = (NSDictionary*) jsonObject[@"media"];
    if (_media) {
        self.contentType = _media[@"content_type"];
        NSString *_mediaUrl = _media[@"url"];
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
    
    NSDictionary *_mediaLandscape = (NSDictionary*) jsonObject[@"mediaLandscape"];
    if (_mediaLandscape) {
        self.landscapeContentType = _mediaLandscape[@"content_type"];
        NSString *_mediaUrlLandscape = _mediaLandscape[@"url"];
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
        if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) {
            if (self.hasPortrait && !self.hasLandscape && [self deviceOrientationIsLandscape]) {
                self.error = [NSString stringWithFormat:@"The in-app in %@, dismissing %@ InApp Notification.", @"portrait", @"landscape"];
                return;
            }
            
            if (self.hasLandscape && !self.hasPortrait && ![self deviceOrientationIsLandscape]) {
                self.error = [NSString stringWithFormat:@"The in-app in %@, dismissing %@ InApp Notification.", @"landscape", @"portrait"];
                return;
            }
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
            self.inAppType = [CTInAppUtils inAppTypeFromString:@"custom-html"];
        }
        NSString *url = (NSString*) data[@"url"];
        if (url && url.length > 5) {
            self.url = url;
            self.inAppType = [CTInAppUtils inAppTypeFromString:@"custom-html"];
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
        self.maxPerSession = displayParams[@"mdc"] ? [displayParams[@"mdc"] intValue] : -1;
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
        UIApplication *sharedApplication = [CTInAppResources getSharedApplication];
        return UIInterfaceOrientationIsLandscape(sharedApplication.statusBarOrientation);
    #endif
}

- (void)prepareWithCompletionHandler: (void (^)(void))completionHandler {
#if !(TARGET_OS_TV)
    if ([NSThread isMainThread]) {
        self.error = [NSString stringWithFormat:@"[%@ prepareWithCompletionHandler] should not be called on the main thread", [self class]];
        completionHandler();
        return;
    }
    
    if (self.imageURL) {
        NSError *error = nil;
        NSData *imageData = [NSData dataWithContentsOfURL:self.imageURL options:NSDataReadingMappedIfSafe error:&error];
        if (error || !imageData) {
            self.error = [NSString stringWithFormat:@"unable to load image from URL: %@", self.imageURL];
        } else {
            if ([self.contentType isEqualToString:@"image/gif"] ) {
                SDAnimatedImage *gif = [SDAnimatedImage imageWithData:imageData];
                if (gif == nil) {
                    self.error = [NSString stringWithFormat:@"unable to decode gif for URL: %@", self.imageURL];
                }
            }
            self.image = self.error ? nil : imageData;
        }
    }
    if (self.imageUrlLandscape && self.hasLandscape) {
        NSError *error = nil;
        NSData *imageData = [NSData dataWithContentsOfURL:self.imageUrlLandscape options:NSDataReadingMappedIfSafe error:&error];
        if (error || !imageData) {
            self.error = [NSString stringWithFormat:@"unable to load landscape image from URL: %@", self.imageUrlLandscape];
        } else {
            if ([self.landscapeContentType isEqualToString:@"image/gif"] ) {
                SDAnimatedImage *gif = [SDAnimatedImage imageWithData:imageData];
                if (gif == nil) {
                    self.error = [NSString stringWithFormat:@"unable to decode landscape gif for URL: %@", self.imageUrlLandscape];
                }
            }
            self.imageLandscape = self.error ? nil : imageData;
        }
    }
#endif
    completionHandler();
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


@end

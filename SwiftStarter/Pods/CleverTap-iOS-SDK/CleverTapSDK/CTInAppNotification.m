#import "CTInAppNotification.h"
#import "CTConstants.h"

@interface CTInAppNotification() {
}

@property (nonatomic, readwrite) NSString* Id;
@property (nonatomic, readwrite) NSString* campaignId;
@property (nonatomic, readwrite) CTInAppType inAppType;
@property (nonatomic, copy, readwrite) NSString *html;
@property (nonatomic, copy, readwrite) NSDictionary *jsonDescription;
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

@property (nonatomic, copy, readwrite) NSDictionary *customExtras;

@property (nonatomic, readwrite) NSString *error;

@end

@implementation CTInAppNotification: NSObject

- (instancetype)initWithJSON:(NSDictionary *)jsonObject {
    if (self = [super init]) {
        @try {
            self.jsonDescription = jsonObject;
            if (![self validateJSON:jsonObject]) {
                self.error = @"Invalid JSON";
                return self;
            }
            if (jsonObject[@"ti"]) {
                self.Id = [NSString stringWithFormat:@"%@", jsonObject[@"ti"]];
            }
            self.campaignId = (NSString*) jsonObject[@"wzrk_id"];
            self.excludeFromCaps = [jsonObject[@"efc"] boolValue];
            self.totalLifetimeCount = jsonObject[@"tlc"] ? [jsonObject[@"tlc"] intValue] : -1;
            self.totalDailyCount = jsonObject[@"tdc"] ? [jsonObject[@"tdc"] intValue] : -1;
            NSDictionary *data = (NSDictionary*) jsonObject[@"d"];
            if (data) {
                NSString *html = (NSString*) data[CLTAP_INAPP_DATA_TAG];
                if (html) {
                    self.html = html;
                    self.inAppType = [CTInAppUtils inAppTypeFromString:@"html"];
                }
                NSDictionary* customExtras = (NSDictionary *) data[@"kv"];
                if (!customExtras) customExtras = [NSDictionary new];
                self.customExtras = customExtras;
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
        } @catch (NSException *e) {
            self.error = e.debugDescription;
        }
    }
    return self;
}

- (void)prepareWithCompletionHandler: (void (^)(void))completionHandler {
    if ([NSThread isMainThread]) {
        self.error = [NSString stringWithFormat:@"[%@ prepareWithCompletionHandler] should not be called on the main thread", [self class]];
        completionHandler();
        return;
    }
    completionHandler();
}

- (BOOL)validateJSON:(NSDictionary *)jsonObject {
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
    if (![self isKeyValidInDictionary:d forKey:CLTAP_INAPP_DATA_TAG ofClass:[NSString class]])
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

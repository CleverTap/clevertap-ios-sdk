#import <Foundation/Foundation.h>
#import "CTLocalInApp.h"
#import "CTConstants.h"

@interface CTLocalInApp () {}
@property (nonatomic, strong) NSString *inAppType;
@property (nonatomic, strong) NSString *titleText;
@property (nonatomic, strong) NSString *messageText;
@property (nonatomic) BOOL followDeviceOrientation;
@property (nonatomic, strong) NSString *positiveBtnText;
@property (nonatomic, strong) NSString *negativeBtnText;
@property (atomic, strong) NSMutableDictionary *inAppSettings;
@end

static NSDictionary *_inAppTypeMap;

@implementation CTLocalInApp

- (instancetype)initWithInAppType:(CTLocalInAppType)inAppType
                        titleText:(NSString *)titleText
                      messageText:(NSString *)messageText
          followDeviceOrientation:(BOOL)followDeviceOrientation
                  positiveBtnText:(NSString *)positiveBtnText
                  negativeBtnText:(NSString *)negativeBtnText {
    if (self = [super init]) {
        if (_inAppTypeMap == nil) {
            _inAppTypeMap = @{
                @(ALERT): @"alert-template",
                @(HALF_INTERSTITIAL): @"half-interstitial"
            };
        }
        _inAppType = [_inAppTypeMap objectForKey:@(inAppType)];
        _titleText = titleText;
        _messageText = messageText;
        _followDeviceOrientation = followDeviceOrientation;
        _positiveBtnText = positiveBtnText;
        _negativeBtnText = negativeBtnText;
        _inAppSettings = [NSMutableDictionary new];
        
        [self addRequiredProperties];
    }
    return self;
}

- (void)addRequiredProperties {
    self.inAppSettings[@"wzrk_id"] = @"";
    self.inAppSettings[@"isLocalInApp"] = @1;
    self.inAppSettings[@"close"] = @1;
    self.inAppSettings[@"type"] = self.inAppType;
    self.inAppSettings[@"hasPortrait"] = @1;
    self.inAppSettings[@"hasLandscape"] = self.followDeviceOrientation ? @1 : @0;
    self.inAppSettings[@"bg"] = @"#FFFFFF"; // White

    NSMutableDictionary *titleDict = [NSMutableDictionary new];
    titleDict[@"text"] = self.titleText;
    self.inAppSettings[@"title"] = titleDict;
    NSMutableDictionary *msgDict = [NSMutableDictionary new];
    msgDict[@"text"] = self.messageText;
    self.inAppSettings[@"message"] = msgDict;
    
    self.inAppSettings[@"buttons"] = [NSMutableArray new];
    // Positive Button
    NSMutableDictionary *positiveBtnObj = [NSMutableDictionary new];
    positiveBtnObj[@"text"] = self.positiveBtnText;
    positiveBtnObj[@"radius"] = @"2";
    positiveBtnObj[@"bg"] = @"#FFFFFF"; // White
    [self.inAppSettings[@"buttons"] addObject:positiveBtnObj];
    
    // Negative Button
    NSMutableDictionary *negativeBtnObj = [NSMutableDictionary new];
    negativeBtnObj[@"text"] = self.negativeBtnText;
    negativeBtnObj[@"radius"] = @"2";
    negativeBtnObj[@"bg"] = @"#FFFFFF"; // White
    [self.inAppSettings[@"buttons"] addObject:negativeBtnObj];
}

- (void)setFallbackToSettings:(BOOL)fallbackToSettings {
    self.inAppSettings[@"fallbackToNotificationSettings"] = fallbackToSettings ? @1 : @0;
}

- (void)setBackgroundColor:(NSString *)backgroundColor {
    self.inAppSettings[@"bg"] = backgroundColor;
}

- (void)setTitleTextColor:(NSString *)titleTextColor {
    self.inAppSettings[@"title"][@"color"] = titleTextColor;
}

- (void)setMessageTextColor:(NSString *)messageTextColor {
    self.inAppSettings[@"message"][@"color"] = messageTextColor;
}

- (void)setBtnBorderRadius:(NSString *)btnBorderRadius {
    self.inAppSettings[@"buttons"][0][@"radius"] = btnBorderRadius;
    self.inAppSettings[@"buttons"][1][@"radius"] = btnBorderRadius;
}

- (void)setBtnTextColor:(NSString *)btnTextColor {
    self.inAppSettings[@"buttons"][0][@"color"] = btnTextColor;
    self.inAppSettings[@"buttons"][1][@"color"] = btnTextColor;
    
}

- (void)setBtnBorderColor:(NSString *)btnBorderColor {
    self.inAppSettings[@"buttons"][0][@"border"] = btnBorderColor;
    self.inAppSettings[@"buttons"][1][@"border"] = btnBorderColor;
    
}

- (void)setBtnBackgroundColor:(NSString *)btnBackgroundColor {
    self.inAppSettings[@"buttons"][0][@"bg"] = btnBackgroundColor;
    self.inAppSettings[@"buttons"][1][@"bg"] = btnBackgroundColor;
}

- (void)setImageUrl:(NSString *)imageUrl {
    NSMutableDictionary *mediaObj = [NSMutableDictionary new];
    mediaObj[CLTAP_INAPP_MEDIA_CONTENT_TYPE] = @"image";
    mediaObj[CLTAP_INAPP_MEDIA_URL] = imageUrl;
    self.inAppSettings[CLTAP_INAPP_MEDIA] = mediaObj;
    if (self.followDeviceOrientation) {
        self.inAppSettings[CLTAP_INAPP_MEDIA_LANDSCAPE] = mediaObj;
    }
}

- (void)setSkipSettingsAlert:(BOOL)skipAlert {
    self.inAppSettings[@"skipSettingsAlert"] = skipAlert ? @1 : @0;
}

- (NSDictionary *)getLocalInAppSettings {
    return self.inAppSettings;
}

@end

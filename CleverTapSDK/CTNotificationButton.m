#import "CTNotificationButton.h"
#import "CTConstants.h"

@interface CTNotificationButton () {
    
}

@property (nonatomic, copy, readwrite) NSString *text;
@property (nonatomic, copy, readwrite) NSString *textColor;
@property (nonatomic, copy, readwrite) NSString *borderRadius;
@property (nonatomic, copy, readwrite) NSString *borderColor;
@property (nonatomic, copy, readwrite) NSString *backgroundColor;

@property (nonatomic, strong, readwrite) CTNotificationAction *action;

@property (nonatomic, copy, readwrite) NSDictionary *jsonDescription;

@property (nonatomic, readwrite) NSString *error;

@end

@implementation CTNotificationButton

- (instancetype)initWithJSON:(NSDictionary *)jsonObject {
    if (self = [super init]) {
        @try {
            self.jsonDescription = jsonObject;
            self.text = jsonObject[@"text"];
            self.textColor = jsonObject[@"color"];
            self.borderRadius = jsonObject[@"radius"];
            self.borderColor = jsonObject[@"border"];
            self.backgroundColor = jsonObject[@"bg"];
            
            NSDictionary *actions = jsonObject[CLTAP_INAPP_ACTIONS];
            if (actions) {
                self.action = [[CTNotificationAction alloc] initWithJSON:actions];
                if (self.action.error) {
                    self.error = self.action.error;
                }
            }
        } @catch (NSException *e) {
            self.error = [e debugDescription];
        }
    }
    return self;
}

- (NSDictionary *)customExtras {
    return [self.action keyValues];
}

- (CTInAppActionType)type {
    return [self.action type];
}

- (BOOL)fallbackToSettings {
    return [self.action fallbackToSettings];
}

- (NSURL *)actionURL {
    return [self.action actionURL];
}

@end

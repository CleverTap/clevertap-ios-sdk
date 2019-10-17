
#import "CTNotificationButton.h"

@interface CTNotificationButton () {
    
}

@property (nonatomic, copy, readwrite) NSString *text;
@property (nonatomic, copy, readwrite) NSString *textColor;
@property (nonatomic, copy, readwrite) NSString *borderRadius;
@property (nonatomic, copy, readwrite) NSString *borderColor;
@property (nonatomic, copy, readwrite) NSString *backgroundColor;
@property (nonatomic, copy, readwrite) NSDictionary *customExtras;
@property (nonatomic, readwrite) NSURL *actionURL;

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
            
            NSDictionary *actions = jsonObject[@"actions"];
            if (actions) {
                self.customExtras = (NSDictionary *) actions[@"kv"];
                NSString *action = actions[@"ios"];
                if (action && action.length > 0) {
                    @try {
                        self.actionURL = [NSURL URLWithString:action];
                    } @catch (NSException *e) {
                        self.error = [e debugDescription];
                    }
                }
            }
            
        } @catch (NSException *e) {
            self.error = [e debugDescription];
        }
    }
    return self;
}

@end

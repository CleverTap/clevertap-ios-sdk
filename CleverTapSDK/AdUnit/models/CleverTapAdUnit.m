#import "CleverTap+AdUnit.h"
#import "CTConstants.h"

@implementation CleverTapAdUnit

- (instancetype)initWithJSON:(NSDictionary *)json {
    if (self = [super init]) {
    @try {
        _json = json;
        
        NSString *wzrkId = json[@"wzrk_id"];
        if (wzrkId) {
            _adID = wzrkId;
        }
       
        NSString *type = json[@"type"];
        if (type) {
            _type = type;
        }
        
        NSString *body = json[@"body"];
        if (body) {
            _body = body;
        }
        
        NSDictionary* customExtras = (NSDictionary *) json[@"kv"];
        if (!customExtras) customExtras = [NSDictionary new];
        _customExtras = customExtras;
        
    } @catch (NSException *e) {
          CleverTapLogStaticDebug(@"Error intitializing CleverTapAdUnit: %@", e.reason);
          return nil;
       }
    }
    return self;
}
        
@end

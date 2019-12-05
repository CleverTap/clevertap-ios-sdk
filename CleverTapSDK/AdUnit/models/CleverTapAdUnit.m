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
        } else {
            _adID = @"0_0";
        }
       
        NSString *type = json[@"type"];
        if (type) {
            _type = type;
        }
        
        NSString *bgColor = json[@"bg"];
        if (bgColor) {
            _bgColor = bgColor;
        }
        
        NSDictionary *customExtras = (NSDictionary *) json[@"custom_kv"];
        if (!customExtras) customExtras = [NSDictionary new];
        _customExtras = customExtras;
        
        NSMutableArray<CleverTapAdUnitContent *> *contentList = [NSMutableArray new];
        NSArray *adUnitContent = json[@"content"];
        if (adUnitContent) {
            for (NSDictionary *obj in adUnitContent) {
                CleverTapAdUnitContent *content = [[CleverTapAdUnitContent alloc] initWithJSON:obj];
                [contentList addObject:content];
            }
        }
        _content = contentList;
               
    } @catch (NSException *e) {
          CleverTapLogStaticDebug(@"Error intitializing CleverTapAdUnit: %@", e.reason);
          return nil;
       }
    }
    return self;
}
        
@end

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
        
        NSDictionary *customExtras = (NSDictionary *) json[@"kv"];
        if (!customExtras) customExtras = [NSDictionary new];
        _customExtras = customExtras;
        
        NSArray *links = json[@"links"];
        if (links) {
           _links = links;
        }
        
        NSMutableArray<CleverTapAdUnitContent *> *contentList = [NSMutableArray new];
        
        NSArray *adUnitContent = json[@"content"];
        if (adUnitContent) {
            for (NSDictionary *obj in adUnitContent) {
                CleverTapAdUnitContent *content = [[CleverTapAdUnitContent alloc] initWithJSON:obj];
                [contentList addObject:content];
            }
        }
               
    } @catch (NSException *e) {
          CleverTapLogStaticDebug(@"Error intitializing CleverTapAdUnit: %@", e.reason);
          return nil;
       }
    }
    return self;
}
        
@end

#import "CleverTap+DisplayUnit.h"
#import "CTConstants.h"

@implementation CleverTapDisplayUnit

- (instancetype)initWithJSON:(NSDictionary *)json {
    if (self = [super init]) {
        @try {
            _json = json;
            
            NSString *wzrkId = json[@"wzrk_id"];
            if (wzrkId) {
                _unitID = wzrkId;
            } else {
                _unitID= @"0_0";
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
            
            NSMutableArray<CleverTapDisplayUnitContent *> *contentList = [NSMutableArray new];
            NSArray *displayUnitContent = json[@"content"];
            if (displayUnitContent) {
                for (NSDictionary *obj in displayUnitContent) {
                    CleverTapDisplayUnitContent *content = [[CleverTapDisplayUnitContent alloc] initWithJSON:obj];
                    [contentList addObject:content];
                }
            }
            _contents = contentList;
            
        } @catch (NSException *e) {
            CleverTapLogStaticDebug(CLTAP_ND_LOG_PREFIX @" Error intitializing CleverTapDisplayUnit: %@", e.reason);
            return nil;
        }
    }
    return self;
}

- (NSDictionary<NSString *, id> *)metaDataForContentAtIndex:(NSInteger)contentIndex {
    if (contentIndex < 0 || contentIndex >= (NSInteger)_contents.count) {
        CleverTapLogStaticDebug(CLTAP_ND_LOG_PREFIX @" Content index %ld out of range for unit %@",
                                (long)contentIndex, _unitID);
        return @{};
    }
    NSDictionary *metaData = _contents[contentIndex].metaData;
    if (!metaData) {
//        CleverTapLogStaticDebug(CLTAP_ND_LOG_PREFIX @" No metadata for content index %ld of unit %@, event will have no item attribution",
//                                (long)contentIndex, _unitID);
        return @{};
    }
    return metaData;
}

@end

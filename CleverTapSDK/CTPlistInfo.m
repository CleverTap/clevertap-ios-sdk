#import "CTPlistInfo.h"
#import "CleverTap.h"
#import "CTConstants.h"

static NSDictionary *plistRootInfoDict;
static NSArray *registeredURLSchemes;

@implementation CTPlistInfo

+ (id)getValueForKey:(NSString *)key {
    if (!plistRootInfoDict) {
        plistRootInfoDict = [[NSBundle mainBundle] infoDictionary];
    }
    return plistRootInfoDict[key];
}

+ (NSString *)getMetaDataForAttribute:(NSString *)name {
    @try {
        id _value = [self getValueForKey:name];
        
        if(_value && ![_value isKindOfClass:[NSString class]]) {
            _value = [NSString stringWithFormat:@"%@", _value];
        }
        
        NSString *value = (NSString *)_value;
        
        if (value == nil || [[value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
            CleverTapLogStaticDebug(@"%@: not specified in Info.plist", name);
            value = nil;
        } else {
            value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            CleverTapLogStaticDebug(@"%@: %@", name, value);
        }
        return value;
        
    } @catch (NSException *e) {
        CleverTapLogStaticInternal(@"Requested meta data entry not found: %@", name);
        return nil;
    }
}
+ (NSArray *)getRegisteredURLSchemes {
    
    if (!registeredURLSchemes) {
        registeredURLSchemes = [NSArray new];
        
        @try {
            NSArray *cfBundleURLTypes = [[self class] getValueForKey:@"CFBundleURLTypes"];
            if (cfBundleURLTypes && [cfBundleURLTypes isKindOfClass:[NSArray class]]) {
                for (NSDictionary *item in cfBundleURLTypes) {
                    NSArray* cfBundleURLSchemes = item[@"CFBundleURLSchemes"];
                    if (cfBundleURLSchemes && [cfBundleURLSchemes isKindOfClass:[NSArray class]]) {
                        registeredURLSchemes = [cfBundleURLSchemes copy];
                    }
                }
            }
        } @catch (NSException *e) {
            // no-op
        }
    }
    return registeredURLSchemes;
}

+ (instancetype)sharedInstance {
    static CTPlistInfo *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-   (instancetype)init {
    if ((self = [super init])) {
        _accountId = [CTPlistInfo getMetaDataForAttribute:CLTAP_ACCOUNT_ID_LABEL];
        _accountToken = [CTPlistInfo getMetaDataForAttribute:CLTAP_TOKEN_LABEL];
        _accountRegion = [CTPlistInfo getMetaDataForAttribute:CLTAP_REGION_LABEL];
        _registeredUrlSchemes = [CTPlistInfo getRegisteredURLSchemes];
        
        NSString *useIFA = [CTPlistInfo getMetaDataForAttribute:CLTAP_USE_IFA_LABEL];
        _useIDFA = (useIFA && [useIFA isEqualToString:@"1"]);
        
        NSString *useCustomCleverTapId = [CTPlistInfo getMetaDataForAttribute:CLTAP_USE_CUSTOM_CLEVERTAP_ID_LABEL];
        _useCustomCleverTapId = (useCustomCleverTapId && [useCustomCleverTapId isEqualToString:@"1"]);
    
        NSString *shouldDisableAppLaunchReporting = [CTPlistInfo getMetaDataForAttribute:CLTAP_DISABLE_APP_LAUNCH_LABEL];
        _disableAppLaunchedEvent = (shouldDisableAppLaunchReporting && [shouldDisableAppLaunchReporting isEqualToString:@"1"]);
        
        NSString *enableBeta = [CTPlistInfo getMetaDataForAttribute:CLTAP_BETA_LABEL];
        _beta = (enableBeta && [enableBeta isEqualToString:@"1"]);
    }
    return self;
}

- (void)changeCredentialsWithAccountID:(NSString *)accountID token:(NSString *)token region:(NSString *)region {
    _accountId = accountID;
    _accountToken = token;
    _accountRegion = region;
}
@end

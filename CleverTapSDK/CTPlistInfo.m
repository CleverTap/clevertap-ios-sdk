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
        _proxyDomain = [CTPlistInfo getMetaDataForAttribute:CLTAP_PROXY_DOMAIN_LABEL];
        _spikyProxyDomain = [CTPlistInfo getMetaDataForAttribute:CLTAP_SPIKY_PROXY_DOMAIN_LABEL];
        _registeredUrlSchemes = [CTPlistInfo getRegisteredURLSchemes];
                
        NSString *useCustomCleverTapId = [CTPlistInfo getMetaDataForAttribute:CLTAP_USE_CUSTOM_CLEVERTAP_ID_LABEL];
        _useCustomCleverTapId = (useCustomCleverTapId && [useCustomCleverTapId isEqualToString:@"1"]);
        
        NSString *shouldDisableAppLaunchReporting = [CTPlistInfo getMetaDataForAttribute:CLTAP_DISABLE_APP_LAUNCH_LABEL];
        _disableAppLaunchedEvent = (shouldDisableAppLaunchReporting && [shouldDisableAppLaunchReporting isEqualToString:@"1"]);
        
        NSString *enableBeta = [CTPlistInfo getMetaDataForAttribute:CLTAP_BETA_LABEL];
        _beta = (enableBeta && [enableBeta isEqualToString:@"1"]);
        
        // Fetch IDFV Flag from INFO.PLIST
        NSString *disableIDFV = [CTPlistInfo getMetaDataForAttribute:CLTAP_DISABLE_IDFV_LABEL];
        _disableIDFV = (disableIDFV && [disableIDFV isEqualToString:@"1"]);
        
        NSString *enableFileProtection = [CTPlistInfo getMetaDataForAttribute:CLTAP_ENABLE_FILE_PROTECTION];
        _enableFileProtection = (enableFileProtection && [enableFileProtection isEqualToString:@"1"]);
        
        _handshakeDomain = [CTPlistInfo getMetaDataForAttribute:CLTAP_HANDSHAKE_DOMAIN];
        
        NSString *encryptionLevel = [CTPlistInfo getMetaDataForAttribute:CLTAP_ENCRYPTION_LEVEL];
        [self setEncryption:encryptionLevel];
    }
    return self;
}

- (void)setCredentialsWithAccountID:(NSString *)accountID token:(NSString *)token region:(NSString *)region {
    _accountId = accountID;
    _accountToken = token;
    _accountRegion = region;
}

- (void)setCredentialsWithAccountID:(NSString *)accountID token:(NSString *)token proxyDomain:(NSString *)proxyDomain {
    _accountId = accountID;
    _accountToken = token;
    _proxyDomain = proxyDomain;
}

- (void)setCredentialsWithAccountID:(NSString * _Nonnull)accountID token:(NSString * _Nonnull)token proxyDomain:(NSString * _Nonnull)proxyDomain spikyProxyDomain:(NSString * _Nullable)spikyProxyDomain {
    _accountId = accountID;
    _accountToken = token;
    _proxyDomain = proxyDomain;
    _spikyProxyDomain = spikyProxyDomain;
}

- (void)setCredentialsWithAccountID:(NSString * _Nonnull)accountID token:(NSString * _Nonnull)token proxyDomain:(NSString * _Nonnull)proxyDomain spikyProxyDomain:(NSString * _Nullable)spikyProxyDomain handshakeDomain:(NSString*)handshakeDomain {
    _accountId = accountID;
    _accountToken = token;
    _proxyDomain = proxyDomain;
    _spikyProxyDomain = spikyProxyDomain;
    _handshakeDomain = handshakeDomain;
}

- (void)setEncryption:(NSString *)encryptionLevel {
    if (encryptionLevel && [encryptionLevel isEqualToString:@"0"]) {
        _encryptionLevel = CleverTapEncryptionNone;
    } else if (encryptionLevel && [encryptionLevel isEqualToString:@"1"]) {
        _encryptionLevel = CleverTapEncryptionMedium;
    } else {
        _encryptionLevel = CleverTapEncryptionNone;
        CleverTapLogStaticInternal(@"Supported encryption levels are only 0 and 1. Setting it to 0 by default");
    }
}

@end

#import "CleverTapInstanceConfig.h"
#import "CleverTapInstanceConfigPrivate.h"
#import "CTPlistInfo.h"
#import "CTConstants.h"

@implementation CleverTapInstanceConfig

- (instancetype)initWithAccountId:(NSString *)accountId
                     accountToken:(NSString *)accountToken {
    return [self initWithAccountId:accountId
                      accountToken:accountToken
                     accountRegion:nil
                 isDefaultInstance:NO];
}

- (instancetype)initWithAccountId:(NSString *)accountId
                     accountToken:(NSString *)accountToken
                    accountRegion:(NSString *)accountRegion {
    return [self initWithAccountId:accountId
                      accountToken:accountToken
                     accountRegion:accountRegion
                 isDefaultInstance:NO];
}

- (instancetype)initWithAccountId:(NSString *)accountId
                     accountToken:(NSString *)accountToken
                      proxyDomain:(NSString *)proxyDomain {
    return [self initWithAccountId:accountId
                      accountToken:accountToken
                       proxyDomain:proxyDomain
                 isDefaultInstance:NO];
}

- (instancetype)initWithAccountId:(NSString *)accountId
                     accountToken:(NSString *)accountToken
                      proxyDomain:(NSString *)proxyDomain
                 spikyProxyDomain:(NSString *)spikyProxyDomain {
    return [self initWithAccountId:accountId
                      accountToken:accountToken
                       proxyDomain:proxyDomain
                    spikyProxyDomain:spikyProxyDomain
                 isDefaultInstance:NO];
}

// SDK private
- (instancetype)initWithAccountId:(NSString *)accountId
                     accountToken:(NSString *)accountToken
                    accountRegion:(NSString *)accountRegion
                isDefaultInstance:(BOOL)isDefault {
    [self checkIfAvailableAccountId:accountId accountToken:accountToken];
    
    if (self = [super init]) {
        _accountId = accountId;
        _accountToken = accountToken;
        _accountRegion = accountRegion;
        _isDefaultInstance = isDefault;
        _queueLabel = [NSString stringWithFormat:@"com.clevertap.serialQueue:%@",accountId];
        
        [self setupPlistData:isDefault];
    }
    return self;
}

- (instancetype)initWithAccountId:(NSString *)accountId
                     accountToken:(NSString *)accountToken
                      proxyDomain:(NSString *)proxyDomain
                isDefaultInstance:(BOOL)isDefault {
    [self checkIfAvailableAccountId:accountId accountToken:accountToken];
    
    if (self = [super init]) {
        _accountId = accountId;
        _accountToken = accountToken;
        _proxyDomain = proxyDomain;
        _isDefaultInstance = isDefault;
        _queueLabel = [NSString stringWithFormat:@"com.clevertap.serialQueue:%@",accountId];
        
        [self setupPlistData:isDefault];
    }
    return self;
}

- (instancetype)initWithAccountId:(NSString *)accountId
                     accountToken:(NSString *)accountToken
                      proxyDomain:(NSString *)proxyDomain
                 spikyProxyDomain:(NSString *)spikyProxyDomain
                isDefaultInstance:(BOOL)isDefault {
    [self checkIfAvailableAccountId:accountId accountToken:accountToken];
    
    if (self = [super init]) {
        _accountId = accountId;
        _accountToken = accountToken;
        _proxyDomain = proxyDomain;
        _spikyProxyDomain = spikyProxyDomain;
        _isDefaultInstance = isDefault;
        _queueLabel = [NSString stringWithFormat:@"com.clevertap.serialQueue:%@",accountId];
        
        [self setupPlistData:isDefault];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone*)zone {
    CleverTapInstanceConfig *copy;
    NSString *proxyDomain = [self.proxyDomain stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSString *spikyProxyDomain = [self.spikyProxyDomain stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (spikyProxyDomain.length > 0 && proxyDomain.length > 0) {
        copy = [[[self class] allocWithZone:zone] initWithAccountId:self.accountId accountToken:self.accountToken proxyDomain:self.proxyDomain spikyProxyDomain:self.spikyProxyDomain isDefaultInstance:self.isDefaultInstance];
    } else if (proxyDomain.length > 0) {
        copy = [[[self class] allocWithZone:zone] initWithAccountId:self.accountId accountToken:self.accountToken proxyDomain:self.proxyDomain isDefaultInstance:self.isDefaultInstance];
    } else {
        copy = [[[self class] allocWithZone:zone] initWithAccountId:self.accountId accountToken:self.accountToken accountRegion:self.accountRegion isDefaultInstance:self.isDefaultInstance];
    }
    
    copy.analyticsOnly = self.analyticsOnly;
    copy.disableAppLaunchedEvent = self.disableAppLaunchedEvent;
    copy.enablePersonalization = self.enablePersonalization;
    copy.logLevel = self.logLevel;
    copy.useCustomCleverTapId = self.useCustomCleverTapId;
    copy.disableIDFV = self.disableIDFV;
    copy.identityKeys = self.identityKeys;
    copy.beta = self.beta;
    return copy;
}


- (void)setIdentityKeys:(NSArray *)identityKeys {
    if (!_isDefaultInstance) {
        // ONLY ADD SUPPORTED KEYS
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self IN %@", CLTAP_ALL_PROFILE_IDENTIFIER_KEYS];
        _identityKeys = [identityKeys filteredArrayUsingPredicate:predicate];
    }
}

- (void) setupPlistData:(BOOL)isDefault {
    CTPlistInfo *plist = [CTPlistInfo sharedInstance];
    
    _disableIDFV = isDefault ? plist.disableIDFV : NO;
    _disableAppLaunchedEvent = isDefault ? plist.disableAppLaunchedEvent : NO;
    _useCustomCleverTapId = isDefault ? plist.useCustomCleverTapId : NO;
    _enablePersonalization = YES;
    _logLevel = 0;
    _beta = plist.beta;
}

- (void) checkIfAvailableAccountId:(NSString *)accountId
                       accountToken:(NSString *)accountToken {
    if (accountId.length <= 0) {
        CleverTapLogStaticInfo("CleverTap accountId is empty");
    }
    
    if (accountToken.length <= 0) {
        CleverTapLogStaticInfo("CleverTap accountToken is empty");
    }
}
@end

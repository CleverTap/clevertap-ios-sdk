#import "CleverTapInstanceConfig.h"
#import "CleverTapInstanceConfigPrivate.h"
#import "CTPlistInfo.h"
#import "CTConstants.h"
#import "CTAES.h"

@implementation CleverTapInstanceConfig

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_accountId forKey:@"accountId"];
    [coder encodeObject:_accountToken forKey:@"accountToken"];
    [coder encodeObject:_accountRegion forKey:@"accountRegion"];
    [coder encodeObject:_proxyDomain forKey:@"proxyDomain"];
    [coder encodeObject:_spikyProxyDomain forKey:@"spikyProxyDomain"];
    [coder encodeBool:_analyticsOnly forKey:@"analyticsOnly"];
    [coder encodeBool:_disableAppLaunchedEvent forKey:@"disableAppLaunchedEvent"];
    [coder encodeBool:_enablePersonalization forKey:@"enablePersonalization"];
    [coder encodeBool:_useCustomCleverTapId forKey:@"useCustomCleverTapId"];
    [coder encodeBool:_disableIDFV forKey:@"disableIDFV"];
    [coder encodeInt:_logLevel forKey:@"logLevel"];
    [coder encodeObject:_identityKeys forKey:@"identityKeys"];
    
    [coder encodeBool: _isDefaultInstance forKey:@"isDefaultInstance"];
    [coder encodeObject: _queueLabel forKey:@"queueLabel"];
    [coder encodeBool: _isCreatedPostAppLaunched forKey:@"isCreatedPostAppLaunched"];
    [coder encodeBool: _beta forKey:@"beta"];
    [coder encodeBool: _wv_init forKey:@"wv_init"];
    [coder encodeInt: _encryptionLevel forKey:@"encryptionLevel"];
    [coder encodeObject: _aesCrypt forKey:@"aesCrypt"];
    [coder encodeBool:_enableFileProtection forKey:@"enableFileProtection"];
    [coder encodeObject:_handshakeDomain forKey:@"handshakeDomain"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    if (self = [super init]) {
        _accountId = [coder decodeObjectForKey:@"accountId"];
        _accountToken = [coder decodeObjectForKey:@"accountToken"];
        _accountRegion = [coder decodeObjectForKey:@"accountRegion"];
        _proxyDomain = [coder decodeObjectForKey:@"proxyDomain"];
        _spikyProxyDomain = [coder decodeObjectForKey:@"spikyProxyDomain"];
        _analyticsOnly = [coder decodeBoolForKey:@"analyticsOnly"];
        _disableAppLaunchedEvent = [coder decodeBoolForKey:@"disableAppLaunchedEvent"];
        _enablePersonalization = [coder decodeBoolForKey:@"enablePersonalization"];
        _useCustomCleverTapId = [coder decodeBoolForKey:@"useCustomCleverTapId"];
        _disableIDFV = [coder decodeBoolForKey:@"disableIDFV"];
        _logLevel = [coder decodeIntForKey:@"logLevel"];
        _identityKeys = [coder decodeObjectForKey:@"identityKeys"];
        
        _isDefaultInstance = [coder decodeBoolForKey:@"isDefaultInstance"];
        _queueLabel = [coder decodeObjectForKey:@"queueLabel"];
        _isCreatedPostAppLaunched = [coder decodeBoolForKey:@"isCreatedPostAppLaunched"];
        _beta = [coder decodeBoolForKey:@"beta"];
        _wv_init = [coder decodeBoolForKey:@"wv_init"];
        _encryptionLevel = [coder decodeIntForKey:@"encryptionLevel"];
        _aesCrypt = [coder decodeObjectForKey:@"aesCrypt"];
        _enableFileProtection = [coder decodeBoolForKey:@"enableFileProtection"];
        _handshakeDomain = [coder decodeObjectForKey:@"handshakeDomain"];
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}


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
                 handshakeDomain:(NSString *)handshakeDomain
                isDefaultInstance:(BOOL)isDefault {
    [self checkIfAvailableAccountId:accountId accountToken:accountToken];
    
    if (self = [super init]) {
        _accountId = accountId;
        _accountToken = accountToken;
        _handshakeDomain = handshakeDomain;
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

+ (NSString*)dataArchiveFileNameWithAccountId:(NSString*)accountId {
    return [NSString stringWithFormat:@"clevertap-%@-instance-config.plist", accountId];
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
    copy.encryptionLevel = self.encryptionLevel;
    copy.aesCrypt = self.aesCrypt;
    copy.enableFileProtection = self.enableFileProtection;
    copy.handshakeDomain = self.handshakeDomain;
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
    _encryptionLevel = isDefault ? plist.encryptionLevel : CleverTapEncryptionNone;
    _enableFileProtection = isDefault ? plist.enableFileProtection : NO;
    _handshakeDomain = isDefault ? plist.handshakeDomain : nil;
    if (isDefault) {
        _aesCrypt = [[CTAES alloc] initWithAccountID:_accountId encryptionLevel:_encryptionLevel isDefaultInstance:isDefault];
    }
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

- (void)setEncryptionLevel:(CleverTapEncryptionLevel)encryptionLevel {
    if (!_isDefaultInstance) {
        _encryptionLevel = encryptionLevel;
        _aesCrypt = [[CTAES alloc] initWithAccountID:_accountId encryptionLevel:_encryptionLevel isDefaultInstance:_isDefaultInstance];
    } else {
        CleverTapLogStaticInfo("CleverTap Encryption level for default instance can't be updated from setEncryptionLevel method");
    }
}

- (void)setEnableFileProtection:(BOOL)enableFileProtection {
    if (!_isDefaultInstance) {
        _enableFileProtection = enableFileProtection;
    } else {
        CleverTapLogStaticInfo("CleverTap enable file protection for default instance can't be updated from setEnableFileProtection method");
    }
}

- (void)setHandshakeDomain:(NSString *)handshakeDomain {
    if (!_isDefaultInstance) {
        _handshakeDomain = handshakeDomain;
    } else {
        CleverTapLogStaticInfo("CleverTap handshake domain for default instance can't be updated from setHandshakeDomain method");
    }
}
@end

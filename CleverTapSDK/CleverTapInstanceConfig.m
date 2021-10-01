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

// SDK private
- (instancetype)initWithAccountId:(NSString *)accountId
                     accountToken:(NSString *)accountToken
                    accountRegion:(NSString *)accountRegion
                isDefaultInstance:(BOOL)isDefault {
    [self checkIfAvavilableAccountId:accountId accountToken:accountToken];
    
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
    [self checkIfAvavilableAccountId:accountId accountToken:accountToken];
    
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

- (instancetype)copyWithZone:(NSZone*)zone {
    CleverTapInstanceConfig *copy;
    NSString *proxyDomain = [self.proxyDomain stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (proxyDomain.length > 0) {
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
    copy.beta = self.beta;
    return copy;
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

- (void) checkIfAvavilableAccountId:(NSString *)accountId
                       accountToken:(NSString *)accountToken {
    if (accountId.length <= 0) {
        CleverTapLogStaticInfo("CleverTap accountId is empty");
    }
    
    if (accountToken.length <= 0) {
        CleverTapLogStaticInfo("CleverTap accountToken is empty");
    }
}
@end

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
                       proxyDomain:nil
                 isDefaultInstance:NO];    
}

- (instancetype)initWithAccountId:(NSString *)accountId
                     accountToken:(NSString *)accountToken
                      proxyDomain:(NSString *)proxyDomain {
    return [self initWithAccountId:accountId
                      accountToken:accountToken
                     accountRegion:nil
                       proxyDomain:proxyDomain
                 isDefaultInstance:NO];
}

- (instancetype)initWithAccountId:(NSString *)accountId
                     accountToken:(NSString *)accountToken
                    accountRegion:(NSString *)accountRegion {
    return [self initWithAccountId:accountId
                      accountToken:accountToken
                     accountRegion:accountRegion
                       proxyDomain:nil
                 isDefaultInstance:NO];
}

- (instancetype)initWithAccountId:(NSString *)accountId
                     accountToken:(NSString *)accountToken
                    accountRegion:(NSString *)accountRegion
                      proxyDomain:(NSString *)proxyDomain {
    return [self initWithAccountId:accountId
                      accountToken:accountToken
                     accountRegion:accountRegion
                       proxyDomain:proxyDomain
                 isDefaultInstance:NO];
}

// SDK private
- (instancetype)initWithAccountId:(NSString *)accountId
                     accountToken:(NSString *)accountToken
                    accountRegion:(NSString *)accountRegion
                      proxyDomain:(NSString *)proxyDomain
                isDefaultInstance:(BOOL)isDefault {
    if (accountId.length <= 0) {
        CleverTapLogStaticInfo("CleverTap accountId is empty");
    }
    
    if (accountToken.length <= 0) {
        CleverTapLogStaticInfo("CleverTap accountToken is empty");
    }
    
    if (self = [super init]) {
        _accountId = accountId;
        _accountToken = accountToken;
        _accountRegion = accountRegion;
        _proxyDomain = proxyDomain;
        _isDefaultInstance = isDefault;
        
        CTPlistInfo *plist = [CTPlistInfo sharedInstance];
        _disableAppLaunchedEvent = isDefault ? plist.disableAppLaunchedEvent : NO;
        _useCustomCleverTapId = isDefault ? plist.useCustomCleverTapId : NO;
        _enablePersonalization = YES;
        _logLevel = 0;
        _queueLabel = [NSString stringWithFormat:@"com.clevertap.serialQueue:%@",accountId];
        _beta = plist.beta;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone*)zone {
    CleverTapInstanceConfig *copy = [[[self class] allocWithZone:zone] initWithAccountId:self.accountId accountToken:self.accountToken accountRegion:self.accountRegion proxyDomain:self.proxyDomain isDefaultInstance:self.isDefaultInstance];
    copy.analyticsOnly = self.analyticsOnly;
    copy.disableAppLaunchedEvent = self.disableAppLaunchedEvent;
    copy.enablePersonalization = self.enablePersonalization;
    copy.logLevel = self.logLevel;
    copy.enableABTesting = self.enableABTesting;
    copy.enableUIEditor = self.enableUIEditor;
    copy.useCustomCleverTapId = self.useCustomCleverTapId;
    copy.beta = self.beta;
    return copy;
}

@end

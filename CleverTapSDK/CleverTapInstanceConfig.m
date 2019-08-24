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
// SDK private
- (instancetype)initWithAccountId:(NSString *)accountId
                              accountToken:(NSString *)accountToken
                             accountRegion:(NSString *)accountRegion
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
        _isDefaultInstance = isDefault;
        
        CTPlistInfo *plist = [CTPlistInfo sharedInstance];
        _useIDFA = isDefault ? plist.useIDFA : NO;
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
    CleverTapInstanceConfig *copy = [[[self class] allocWithZone:zone] initWithAccountId:self.accountId accountToken:self.accountToken accountRegion:self.accountRegion isDefaultInstance:self.isDefaultInstance];
    copy.analyticsOnly = self.analyticsOnly;
    copy.disableAppLaunchedEvent = self.disableAppLaunchedEvent;
    copy.enablePersonalization = self.enablePersonalization;
    copy.useIDFA = self.useIDFA;
    copy.logLevel = self.logLevel;
    copy.enableABTesting = self.enableABTesting;
    copy.enableUIEditor = self.enableUIEditor;
    copy.useCustomCleverTapId = self.useCustomCleverTapId;
    copy.beta = self.beta;
    return copy;
}

@end

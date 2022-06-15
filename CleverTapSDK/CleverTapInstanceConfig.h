#import <Foundation/Foundation.h>
#import "CleverTap.h"

@interface CleverTapInstanceConfig : NSObject

@property (nonatomic, strong, readonly, nonnull) NSString *accountId;
@property (nonatomic, strong, readonly, nonnull) NSString *accountToken;
@property (nonatomic, strong, readonly, nullable) NSString *accountRegion;
@property (nonatomic, strong, readonly, nullable) NSString *proxyDomain;
@property (nonatomic, strong, readonly, nullable) NSString *spikyProxyDomain;

@property (nonatomic, assign) BOOL analyticsOnly;
@property (nonatomic, assign) BOOL disableAppLaunchedEvent;
@property (nonatomic, assign) BOOL enablePersonalization;
@property (nonatomic, assign) BOOL useCustomCleverTapId;
@property (nonatomic, assign) BOOL disableIDFV;
@property (nonatomic, assign) CleverTapLogLevel logLevel;
@property (nonatomic, strong, nullable) NSArray *identityKeys;


- (instancetype _Nonnull) init __unavailable;

- (instancetype _Nonnull)initWithAccountId:(NSString* _Nonnull)accountId
                              accountToken:(NSString* _Nonnull)accountToken;

- (instancetype _Nonnull)initWithAccountId:(NSString* _Nonnull)accountId
                              accountToken:(NSString* _Nonnull)accountToken
                             accountRegion:(NSString* _Nonnull)accountRegion;

- (instancetype _Nonnull)initWithAccountId:(NSString* _Nonnull)accountId
                              accountToken:(NSString* _Nonnull)accountToken
                               proxyDomain:(NSString* _Nonnull)proxyDomain;

- (instancetype _Nonnull)initWithAccountId:(NSString* _Nonnull)accountId
                              accountToken:(NSString* _Nonnull)accountToken
                               proxyDomain:(NSString* _Nonnull)proxyDomain
                          spikyProxyDomain:(NSString* _Nonnull)spikyProxyDomain;
@end

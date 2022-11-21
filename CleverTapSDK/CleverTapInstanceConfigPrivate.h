#import <Foundation/Foundation.h>

@interface CleverTapInstanceConfig () <NSCopying, NSCoding, NSSecureCoding> {}

@property (nonatomic, assign, readonly) BOOL isDefaultInstance;
@property (nonatomic, strong, readonly, nonnull) NSString *queueLabel;
@property (nonatomic, assign) BOOL isCreatedPostAppLaunched;
@property (nonatomic, assign) BOOL beta;

- (instancetype _Nonnull)initWithAccountId:(NSString * _Nonnull)accountId
                              accountToken:(NSString * _Nonnull)accountToken
                             accountRegion:(NSString * _Nullable)accountRegion
                         isDefaultInstance:(BOOL)isDefault;

- (instancetype _Nonnull)initWithAccountId:(NSString * _Nonnull)accountId
                              accountToken:(NSString * _Nonnull)accountToken
                               proxyDomain:(NSString * _Nonnull)proxyDomain
                         isDefaultInstance:(BOOL)isDefault;

- (instancetype _Nonnull)initWithAccountId:(NSString* _Nonnull)accountId
                              accountToken:(NSString* _Nonnull)accountToken
                               proxyDomain:(NSString* _Nonnull)proxyDomain
                          spikyProxyDomain:(NSString* _Nonnull)spikyProxyDomain
                         isDefaultInstance:(BOOL)isDefault;

+ (NSString* _Nonnull)dataArchiveFileNameWithAccountId:(NSString* _Nonnull)accountId;
@end

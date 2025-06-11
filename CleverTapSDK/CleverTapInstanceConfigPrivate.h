#import <Foundation/Foundation.h>

@interface CleverTapInstanceConfig () <NSCopying, NSCoding, NSSecureCoding> {}

@property (nonatomic, assign, readonly) BOOL isDefaultInstance;
@property (nonatomic, strong, readonly, nonnull) NSString *queueLabel;
@property (nonatomic, assign) BOOL isCreatedPostAppLaunched;
@property (nonatomic, assign) BOOL beta;

// SET ONLY WHEN THE USER INITIALISES A WEBVIEW WITH CT JS INTERFACE
@property (nonatomic, assign) BOOL wv_init;

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

- (instancetype _Nonnull)initWithAccountId:(NSString * _Nonnull)accountId
                     accountToken:(NSString * _Nonnull)accountToken
                 handshakeDomain:(NSString * _Nonnull)handshakeDomain
                isDefaultInstance:(BOOL)isDefault;

+ (NSString* _Nonnull)dataArchiveFileNameWithAccountId:(NSString* _Nonnull)accountId;
@end

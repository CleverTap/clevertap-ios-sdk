#if CLEVERTAP_SSL_PINNING
@import Foundation;

@class CleverTapInstanceConfig;

@interface CTPinnedNSURLSessionDelegate : NSObject <NSURLSessionDelegate>

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config;

- (void)pinSSLCerts:(NSArray *)filenames forDomains:(NSArray *)domains;

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler;

@end
#endif

#if CLEVERTAP_SSL_PINNING
#import "CTPinnedNSURLSessionDelegate.h"
#import "CTCertificatePinning.h"
#import "CTConstants.h"
#import "CleverTapInstanceConfig.h"
#import "CleverTapInstanceConfigPrivate.h"

@interface CTPinnedNSURLSessionDelegate () {}

@property (nonatomic, strong) CleverTapInstanceConfig *config;

@end

@implementation CTPinnedNSURLSessionDelegate

- (NSString*)description {
    return [NSString stringWithFormat:@"CleverTap.%@", self.config.accountId];
}

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config {
    if (self = [super init]) {
        _config = config;
    }
    return self;
}

- (void)pinSSLCerts:(NSArray *)filenames forDomains:(NSArray *)domains {
    CleverTapLogDebug(self.config.logLevel, @"%@: Pinning SSL certs", self);
    NSMutableArray *certs = [NSMutableArray array];
    for (NSString *filename in filenames) {
        NSString *certPath =  [[NSBundle bundleForClass:[self class]] pathForResource:filename ofType:@"cer"];
        NSData *certData = [[NSData alloc] initWithContentsOfFile:certPath];
        if (certData == nil) {
            CleverTapLogDebug(_config.logLevel, @"%@: Failed to load ssl certificate : %@", self, filename);
            return;
        }
        [certs addObject:certData];
    }
    NSMutableDictionary *pins = [[NSMutableDictionary alloc] init];
    for (NSString *domain in domains) {
        [pins setObject:certs forKey:domain];
    }
    if (pins == nil) {
        CleverTapLogDebug(_config.logLevel, @"Failed to pin ssl certificates");
        return;
    }
    
    if ([CTCertificatePinning setupSSLPinsUsingDictionnary:pins forAccountId:self.config.accountId] != YES) {
        CleverTapLogDebug(_config.logLevel, @"%@: Failed to pin ssl certificates", self);
    }
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    
    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        
        SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
        NSString *domain = [[challenge protectionSpace] host];
        SecTrustResultType trustResult;
        
        // Validate the certificate chain with the device's trust store anyway
        // This *might* give use revocation checking
        SecTrustEvaluate(serverTrust, &trustResult);
        if (trustResult == kSecTrustResultUnspecified) {
            
            // Look for a pinned certificate in the server's certificate chain
            if ([CTCertificatePinning verifyPinnedCertificateForTrust:serverTrust andDomain:domain forAccountId:self.config.accountId]) {
                
                // Found the certificate; continue connecting
                completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
            }
            else {
                // The certificate wasn't found in the certificate chain; cancel the connection
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
            }
        }
        else {
            // Certificate chain validation failed; cancel the connection
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
        }
    }
}

@end

#endif

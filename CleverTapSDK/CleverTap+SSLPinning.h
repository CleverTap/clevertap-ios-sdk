@import Foundation;
#import "CleverTap.h"

@interface CleverTap (SSLPinningTest)

#ifdef CLEVERTAP_SSL_PINNING
@property (nonatomic, assign, readonly) BOOL sslPinningEnabled;
#endif

@end

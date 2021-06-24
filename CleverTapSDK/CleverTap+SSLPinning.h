@import Foundation;
#import "CleverTap.h"

@interface CleverTap (SSLPinning)

#ifdef CLEVERTAP_SSL_PINNING
@property (nonatomic, assign, readonly) BOOL sslPinningEnabled;
#endif

@end

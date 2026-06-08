#import "CTInAppDisplayViewController.h"

NS_ASSUME_NONNULL_BEGIN

/// Main controller for the PiP In-App template.
/// Manages UIWindow lifecycle, entry animation, TTL expiry, and media lifecycle.
/// Subclass of CTInAppDisplayViewController to integrate with the existing delegate
/// and display infrastructure.
@interface CTPiPWindowController : CTInAppDisplayViewController

@end

NS_ASSUME_NONNULL_END

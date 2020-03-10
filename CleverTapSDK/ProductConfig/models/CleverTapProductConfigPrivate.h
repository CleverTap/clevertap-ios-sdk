#import <Foundation/Foundation.h>
#import "CleverTap+ProductConfig.h"

@protocol CleverTapPrivateProductConfigDelegate <NSObject>
@required

@property (atomic, weak) id<CleverTapProductConfigDelegate> _Nullable productConfigDelegate;

- (void)fetchProductConfig;  // TODO

// Getters TODO

@end

@interface CleverTapProductConfig () {}

@property (nonatomic, weak) id<CleverTapPrivateProductConfigDelegate> _Nullable privateDelegate;

- (instancetype _Nullable)init __unavailable;

- (instancetype _Nonnull)initWithPrivateDelegate:(id<CleverTapPrivateProductConfigDelegate> _Nonnull)delegate;

@end

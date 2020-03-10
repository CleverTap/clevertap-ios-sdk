#import <Foundation/Foundation.h>
#import "CleverTap.h"

@protocol CleverTapProductConfigDelegate <NSObject>
@optional
- (void)ctProductConfigUpdated;
@end

@interface CleverTap(ProductConfig)
@property (atomic, strong, readonly, nonnull) CleverTapProductConfig *productConfig;
@end

@interface CleverTapProductConfig : NSObject

@property (nonatomic, weak) id<CleverTapProductConfigDelegate> _Nullable delegate;

// TODO public methods

- (void)fetch;

@end

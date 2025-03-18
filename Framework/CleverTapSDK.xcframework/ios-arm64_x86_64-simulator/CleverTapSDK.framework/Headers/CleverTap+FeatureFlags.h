#import <Foundation/Foundation.h>
#import "CleverTap.h"

__attribute__((deprecated("This protocol has been deprecated and will be removed in the future versions of this SDK.")))
@protocol CleverTapFeatureFlagsDelegate <NSObject>
@optional
- (void)ctFeatureFlagsUpdated
__attribute__((deprecated("This protocol method has been deprecated and will be removed in the future versions of this SDK.")));
@end

@interface CleverTap (FeatureFlags)
@property (atomic, strong, readonly, nonnull) CleverTapFeatureFlags *featureFlags
__attribute__((deprecated("This property has been deprecated and will be removed in the future versions of this SDK.")));
@end

@interface CleverTapFeatureFlags : NSObject

@property (nonatomic, weak) id<CleverTapFeatureFlagsDelegate> _Nullable delegate
__attribute__((deprecated("This property has been deprecated and will be removed in the future versions of this SDK.")));;

- (BOOL)get:(NSString* _Nonnull)key withDefaultValue:(BOOL)defaultValue
__attribute__((deprecated("This method has been deprecated and will be removed in the future versions of this SDK.")));;

@end

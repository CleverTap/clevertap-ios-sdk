#import <Foundation/Foundation.h>
#import "CleverTap.h"

@protocol CleverTapFeatureFlagsDelegate <NSObject>
@optional
- (void)ctFeatureFlagsUpdated;
@end

@interface CleverTap (FeatureFlags)
@property (atomic, strong, readonly, nonnull) CleverTapFeatureFlags *featureFlags;
@end

@interface CleverTapFeatureFlags : NSObject

@property (nonatomic, weak) id<CleverTapFeatureFlagsDelegate> _Nullable delegate;

- (BOOL)get:(NSString* _Nonnull)key withDefaultValue:(BOOL)defaultValue;

@end

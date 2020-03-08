#import <Foundation/Foundation.h>
#import "CleverTap.h"

@protocol CleverTapFeatureFlagsDelegate <NSObject>
@optional
- (void)featureFlagsUpdated;
@end

@interface CleverTapFeatureFlags : NSObject

@property (nonatomic, weak) id<CleverTapFeatureFlagsDelegate> _Nullable delegate;

- (BOOL)get:(NSString* _Nonnull)key withDefaultValue:(BOOL)defaultValue;

@end

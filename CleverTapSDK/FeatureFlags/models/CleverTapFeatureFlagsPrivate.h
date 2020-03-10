#import <Foundation/Foundation.h>
#import "CleverTap+FeatureFlags.h"

@protocol CleverTapPrivateFeatureFlagsDelegate <NSObject>
@required

@property (atomic, weak) id<CleverTapFeatureFlagsDelegate> _Nullable featureFlagsDelegate;

- (BOOL)getFeatureFlag:(NSString* _Nonnull)key withDefaultValue:(BOOL)defaultValue;

@end

@interface CleverTapFeatureFlags () {}

@property (nonatomic, weak) id<CleverTapPrivateFeatureFlagsDelegate> _Nullable privateDelegate;

- (instancetype _Nullable)init __unavailable;

- (instancetype _Nonnull)initWithPrivateDelegate:(id<CleverTapPrivateFeatureFlagsDelegate> _Nonnull)delegate;

@end

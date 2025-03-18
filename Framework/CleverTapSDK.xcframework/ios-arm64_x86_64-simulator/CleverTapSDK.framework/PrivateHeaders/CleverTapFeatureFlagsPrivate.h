#import <Foundation/Foundation.h>
#import "CleverTap+FeatureFlags.h"

@protocol CleverTapPrivateFeatureFlagsDelegate <NSObject>
@required

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property (atomic, weak) id<CleverTapFeatureFlagsDelegate> _Nullable featureFlagsDelegate;
#pragma clang diagnostic pop

- (BOOL)getFeatureFlag:(NSString* _Nonnull)key withDefaultValue:(BOOL)defaultValue;

@end

@interface CleverTapFeatureFlags () {}

@property (nonatomic, weak) id<CleverTapPrivateFeatureFlagsDelegate> _Nullable privateDelegate;

- (instancetype _Nullable)init __unavailable;

- (instancetype _Nonnull)initWithPrivateDelegate:(id<CleverTapPrivateFeatureFlagsDelegate> _Nonnull)delegate;

@end

#import "CleverTapFeatureFlagsPrivate.h"

@implementation CleverTapFeatureFlags

@synthesize delegate=_delegate;

- (instancetype _Nonnull)initWithPrivateDelegate:(id<CleverTapPrivateFeatureFlagsDelegate>)delegate {
    self = [super init];
    if (self) {
        self.privateDelegate = delegate;
    }
    return self;
}

- (void)setDelegate:(id<CleverTapFeatureFlagsDelegate>)delegate {
    [self.privateDelegate setFeatureFlagsDelegate:delegate];
}

- (BOOL)get:(NSString* _Nonnull)key withDefaultValue:(BOOL)defaultValue {
    if (self.privateDelegate) {
        return [self.privateDelegate getFeatureFlag:key withDefaultValue:defaultValue];
    }
    return defaultValue;
}

@end

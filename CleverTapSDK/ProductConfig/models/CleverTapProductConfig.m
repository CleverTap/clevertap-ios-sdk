#import "CleverTapProductConfigPrivate.h"

@implementation CleverTapProductConfig

@synthesize delegate=_delegate;

- (instancetype _Nonnull)initWithPrivateDelegate:(id<CleverTapPrivateProductConfigDelegate>)delegate {
    self = [super init];
    if (self) {
        self.privateDelegate = delegate;
    }
    return self;
}

- (void)setDelegate:(id<CleverTapProductConfigDelegate>)delegate {
    [self.privateDelegate setProductConfigDelegate:delegate];
}

// TODO

- (void)fetch {
    if (self.privateDelegate && [self.privateDelegate respondsToSelector:@selector(fetchProductConfig)]) {
        [self.privateDelegate fetchProductConfig];
    }
}

// Getters TODO

@end

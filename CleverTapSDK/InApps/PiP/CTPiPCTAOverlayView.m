#import "CTPiPCTAOverlayView.h"

@implementation CTPiPCTAOverlayView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)handleTap {
    [self.delegate pipCTAOverlayDidTap];
}

@end

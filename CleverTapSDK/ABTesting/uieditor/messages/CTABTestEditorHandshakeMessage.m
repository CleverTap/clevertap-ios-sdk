#import "CTABTestEditorHandshakeMessage.h"

@implementation CTABTestEditorHandshakeMessage

+ (instancetype)message {
    return [[[self class] alloc] initWithType:@"handshake"];
}

- (CTABTestEditorMessage *)response {
    return self;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@ type=%@, data=%@>", NSStringFromClass([self class]), self.type, self.data];
}

@end

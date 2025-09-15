#import "CTUserMO.h"

@implementation CTUserMO
@synthesize encryptionManager;

- (NSString*)description {
    return [NSString stringWithFormat:@"CTUserMO: %@ messages count=%lu", self.identifier, (long)[self.messages count]];
}

@end

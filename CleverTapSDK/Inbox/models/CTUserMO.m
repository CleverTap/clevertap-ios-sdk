#import "CTUserMO.h"

@implementation CTUserMO

-(NSString*)description {
    return [NSString stringWithFormat:@"CTUserMO: %@ messages count=%lu", self.identifier, (long)[self.messages count]];
}

@end

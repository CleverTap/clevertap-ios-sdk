#import "CleverTapEventDetail.h"

@implementation CleverTapEventDetail

- (NSString*) description {
    return [NSString stringWithFormat:@"CleverTapEventDetail (event name = %@; normalized event name = %@; first time = %d, last time = %d; count = %lu; device ID = %@)",
            self.eventName, self.normalizedEventName, (int) self.firstTime, (int) self.lastTime, (unsigned long)self.count, self.deviceID];
}

@end

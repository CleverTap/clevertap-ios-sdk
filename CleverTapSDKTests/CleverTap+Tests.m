#import "CleverTap+Tests.h"

@interface CleverTap (Tests)
@property (nonatomic, strong) NSMutableArray *eventsQueue;
@property (nonatomic, strong) NSMutableArray *profileQueue;
@property (nonatomic, strong) NSMutableArray *notificationsQueue;

- (NSDictionary *)batchHeader;

@end

@implementation CleverTap (Tests)

@dynamic eventsQueue;
@dynamic profileQueue;
@dynamic notificationsQueue;

-(NSDictionary*)getBatchHeader {
    return [self batchHeader]; // just an example of exposing a private method for testing
}

@end

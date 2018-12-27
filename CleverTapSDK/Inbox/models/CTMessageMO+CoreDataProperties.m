#import "CTMessageMO.h"
#import "CTConstants.h"

@implementation CTMessageMO (CoreDataProperties)

+ (NSFetchRequest<CTMessageMO *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"CTMessage"];
}

- (instancetype)initWithJSON:(NSDictionary *)json forContext:(NSManagedObjectContext *)context {
    CleverTapLogStaticInternal(@"Initializing new CTMessageMO with data: %@", json);
    
    self = [self initWithEntity:[NSEntityDescription entityForName:@"CTMessage" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    
    if (self != nil) {
        
        self.json = [json copy];
        self.tags = json[@"tags"];
        
        NSString *id = json[@"_id"];
        if (id) {
            self.id = id;
        }
        
        NSString *wzrkId = json[@"wzrk_id"];
        if (wzrkId) {
            self.wzrk_id = wzrkId;
        }
        
        NSString *timeStamp = json[@"date"];
        if (timeStamp && ![timeStamp isEqual:[NSNull null]]) {
            NSTimeInterval _interval = [timeStamp doubleValue];
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:_interval];
            self.date = date ? date : [NSDate new];
        }

        NSString *expireTimeStamp = json[@"wzrk_ttl"];
        if (expireTimeStamp && ![expireTimeStamp isEqual:[NSNull null]]) {
            NSTimeInterval _interval = [expireTimeStamp doubleValue];
            NSDate *expires = [NSDate dateWithTimeIntervalSince1970:_interval];
            self.expires = expires ? expires : nil;
        }
    }
    return self;
}

- (NSDictionary *)toJSON {
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithDictionary:self.json];
    json[@"isRead"] = @(self.isRead);
    return json;
}

@dynamic date;
@dynamic expires;
@dynamic id;
@dynamic wzrk_id;
@dynamic user;
@dynamic json;
@dynamic isRead;
@dynamic tags;

@end

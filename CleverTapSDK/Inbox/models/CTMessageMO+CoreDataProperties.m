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
        self.tags = json[@"msg"][@"tags"];
        
        NSString *id = json[@"_id"];
        if (id) {
            self.id = id;
        }
        
        NSString *wzrkId = json[@"wzrk_id"];
        if (wzrkId) {
            self.wzrk_id = wzrkId;
        }
        
        NSUInteger date = [json[@"date"] longValue];
        self.date = date ? date : (long)[[NSDate date] timeIntervalSince1970];
        
        NSUInteger expires = [json[@"wzrk_ttl"] longValue];
        self.expires = expires ? expires : 0;
    }
    return self;
}

- (NSDictionary *)toJSON {
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithDictionary:self.json];
    json[@"isRead"] = @(self.isRead);
    json[@"date"] = @(self.date);
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

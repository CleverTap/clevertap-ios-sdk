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
        
        NSString *id = json[@"id"];
        if (id) {
            self.id = id;
        }
        
        NSDate *date = json[@"date"];
        self.date = date ? date : [NSDate new];
        
        NSDate *expires = json[@"expires"];
        self.expires = expires ? expires : nil;
    }
    return self;
}

- (instancetype)updateWithJson:(NSDictionary *)json forMessage:(CTMessageMO*)msg{
    
    CTMessageMO *obj =  [self init];
    obj = msg;
    [obj setValue:@"44" forKey:@"expires"];
    return obj;
}

- (NSDictionary *)toJSON {
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithDictionary:self.json];
    json[@"isRead"] = @(self.isRead);
    return json;
}

@dynamic date;
@dynamic expires;
@dynamic id;
@dynamic user;
@dynamic json;
@dynamic isRead;

@end

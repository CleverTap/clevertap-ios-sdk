#import "CTUserMO.h"
#import "CTMessageMO.h"
#import "CTConstants.h"

@interface CTUserMO ()
 - (void)insertObject:(CTMessageMO *)value inMessagesAtIndex:(NSUInteger)idx;
 - (void)removeObjectFromMessagesAtIndex:(NSUInteger)idx;
 - (void)insertMessages:(NSArray<CTMessageMO *> *)value atIndexes:(NSIndexSet *)indexes;
 - (void)removeMessagesAtIndexes:(NSIndexSet *)indexes;
 - (void)replaceObjectInMessagesAtIndex:(NSUInteger)idx withObject:(CTMessageMO *)value;
 - (void)replaceMessagesAtIndexes:(NSIndexSet *)indexes withMessages:(NSArray<CTMessageMO *> *)values;
 - (void)addMessagesObject:(CTMessageMO *)value;
 - (void)removeMessagesObject:(CTMessageMO *)value;
 - (void)addMessages:(NSOrderedSet<CTMessageMO *> *)values;
 - (void)removeMessages:(NSOrderedSet<CTMessageMO *> *)values;
@end

@implementation CTUserMO (CoreDataProperties)

+ (instancetype)fetchOrCreateFromJSON:(NSDictionary *)json forContext:(NSManagedObjectContext *)context {
   CTUserMO *_user;
    @try {
        NSString *identifier = json[@"identifier"];
        
        if (!identifier) {
            CleverTapLogStaticInternal(@"CTUserMO fetchOrCreate for: %@ requires an identifier returning nil", json);
            return nil;
        }
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"CTUser"];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", identifier]];
        
        NSError *error = nil;
        NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
        if (!results) {
            CleverTapLogStaticDebug(@"Error fetching CTUser objects: %@\n%@", [error localizedDescription], [error userInfo]);
        }
        if ([results count] > 0) {
            _user = results[0];
            CleverTapLogStaticInternal(@"Found existing %@", _user);
        } else {
            _user = [[CTUserMO alloc] initWithJSON:json forContext:context];
        }
        
    } @catch (NSException *e) {
        CleverTapLogStaticDebug(@"Failed to fetchOrCreate CTUser: %@", e.debugDescription);
        return nil;
    }
    return _user;
}

- (instancetype)initWithJSON:(NSDictionary *)json forContext:(NSManagedObjectContext *)context {
    CleverTapLogStaticInternal(@"Initializing new CTUserMO with data: %@", json);
    self = [self initWithEntity:[NSEntityDescription entityForName:@"CTUser" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    NSString *accountId = json[@"accountId"];
    if (accountId) {
        self.accountId = accountId;
    }
    NSString *guid = json[@"guid"];
    if (guid) {
        self.guid = guid;
    }
    NSString *identifier = json[@"identifier"];
    if (identifier) {
        self.identifier = identifier;
    }
    return self;
}

- (BOOL)updateMessages:(NSArray<NSDictionary*> *)messages forContext:(NSManagedObjectContext *)context {
    NSMutableOrderedSet *newMessages = [NSMutableOrderedSet new];
    BOOL haveUpdates = NO;
    for (NSDictionary *message in messages) {
        NSString *messageId = message[@"_id"];
        if (!messageId) {
            CleverTapLogStaticDebug(@"CTUserMO dropping message: %@, missing id property", message);
            continue;
        }
        NSOrderedSet *results = [self.messages filteredOrderedSetUsingPredicate:[NSPredicate predicateWithFormat:@"id == %@", messageId]];
       
        BOOL existing = results && [results count] > 0;
        if (existing) {
            CleverTapLogStaticInternal(@"%@: already have message: %@, updating", self, message);
            CTMessageMO *msg = (CTMessageMO*)results[0];
            
            NSDate *today = [NSDate date];
            NSDate *expires = msg.expires;
           
            if([today compare:expires] == NSOrderedDescending){
                CleverTapLogStaticInternal(@"%@: message expires: %@, deleting", self, message);
            } else {
                [msg setValue:message forKey:@"json"];
            }
            continue;
        }
        CTMessageMO *_msg = [[CTMessageMO alloc] initWithJSON:message forContext:context];
        if (_msg) {
            [newMessages addObject:_msg];
        }
    } 
    
    if ([newMessages count] > 0) {
        [self addMessages:newMessages];
        haveUpdates = YES;
    }
    return haveUpdates;
}

@dynamic accountId;
@dynamic guid;
@dynamic identifier;
@dynamic messages;

@end

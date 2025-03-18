#import "CTUserMO.h"

@class CTMessageMO;

NS_ASSUME_NONNULL_BEGIN

@interface CTUserMO (CoreDataProperties)

+ (instancetype _Nullable)fetchOrCreateFromJSON:(NSDictionary *)json forContext:(NSManagedObjectContext *)context;
- (BOOL)updateMessages:(NSArray<NSDictionary*> *)messages forContext:(NSManagedObjectContext *)context;

@property (nullable, nonatomic, copy) NSString *accountId;
@property (nullable, nonatomic, copy) NSString *guid;
@property (nullable, nonatomic, copy) NSString *identifier;
@property (nullable, nonatomic, retain) NSOrderedSet<CTMessageMO *> *messages;

@end

@interface CTUserMO (CoreDataGeneratedAccessors)

@end

NS_ASSUME_NONNULL_END

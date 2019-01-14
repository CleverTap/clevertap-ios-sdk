
#import "CTMessageMO.h"

@class CTUserMO;

NS_ASSUME_NONNULL_BEGIN

@interface CTMessageMO (CoreDataProperties)
- (instancetype)initWithJSON:(NSDictionary *)json forContext:(NSManagedObjectContext *)context;
- (NSDictionary *)toJSON;

@property (nonatomic, assign) NSUInteger date;
@property (nonatomic, assign) NSUInteger expires;
@property (nullable, nonatomic, copy) NSString *wzrk_id;
@property (nullable, nonatomic, copy) NSString *id;
@property (nullable, nonatomic, copy) id tags;
@property (nullable, nonatomic, retain) CTUserMO *user;
@property (nullable, nonatomic, copy) id json;
@property (nonatomic, assign) BOOL isRead;




@end

NS_ASSUME_NONNULL_END

#import <Foundation/Foundation.h>
#import "CTDeviceInfo.h"
#import "CTDispatchQueueManager.h"

@class CleverTapInstanceConfig;
@class CleverTapEventDetail;

@interface CTLocalDataStore : NSObject


- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config profileValues:(NSDictionary*)profileValues andDeviceInfo:(CTDeviceInfo*)deviceInfo dispatchQueueManager:(CTDispatchQueueManager*)dispatchQueueManager;

- (void)persistEvent:(NSDictionary *)event;

- (void)addDataSyncFlag:(NSMutableDictionary *)event;

- (NSDictionary*)syncWithRemoteData:(NSDictionary *)responseData;

- (NSTimeInterval)getFirstTimeForEvent:(NSString *)event;

- (NSTimeInterval)getLastTimeForEvent:(NSString *)event;

- (int)getOccurrencesForEvent:(NSString *)event;

- (NSDictionary *)getEventHistory;

- (CleverTapEventDetail *)getEventDetail:(NSString *)event;

- (void)setProfileFields:(NSDictionary *)fields;

- (void)setProfileFieldWithKey:(NSString *)key andValue:(id)value;

- (void)removeProfileFieldsWithKeys:(NSArray *)keys;

- (void)removeProfileFieldForKey:(NSString *)key;

- (id)getProfileFieldForKey:(NSString *)key;

- (NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)getUserAttributeChangeProperties:(NSDictionary *)event;

- (void)persistLocalProfileIfRequired;

- (NSDictionary*)generateBaseProfile;

- (void)changeUser;

@end

#import <Foundation/Foundation.h>
#import "CTDeviceInfo.h"
#import "CTDispatchQueueManager.h"
#import "CTProfileOperationType.h"

@class CleverTapInstanceConfig;
@class CleverTapEventDetail;

@interface CTLocalDataStore : NSObject

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config 
                 profileValues:(NSDictionary *)profileValues
                 andDeviceInfo:(CTDeviceInfo *)deviceInfo
          dispatchQueueManager:(CTDispatchQueueManager *)dispatchQueueManager;

- (void)persistEvent:(NSDictionary *)event;

- (void)addDataSyncFlag:(NSMutableDictionary *)event;

- (NSDictionary*)syncWithRemoteData:(NSDictionary *)responseData;

- (NSTimeInterval)getFirstTimeForEvent:(NSString *)event __attribute__((deprecated("Deprecated as of version 7.1.0, use readUserEventLog instead")));

- (NSTimeInterval)getLastTimeForEvent:(NSString *)event __attribute__((deprecated("Deprecated as of version 7.1.0, use readUserEventLog instead")));

- (int)getOccurrencesForEvent:(NSString *)event __attribute__((deprecated("Deprecated as of version 7.1.0, use readUserEventLogCount instead")));

- (NSDictionary *)getEventHistory __attribute__((deprecated("Deprecated as of version 7.1.0, use readUserEventLogs instead")));

- (CleverTapEventDetail *)getEventDetail:(NSString *)event __attribute__((deprecated("Deprecated as of version 7.1.0, use readUserEventLog instead")));

- (void)setProfileFields:(NSDictionary *)fields;

- (void)setProfileFieldWithKey:(NSString *)key andValue:(id)value;

- (void)removeProfileFieldsWithKeys:(NSArray *)keys;

- (void)removeProfileFieldForKey:(NSString *)key;

- (id)getProfileFieldForKey:(NSString *)key;

- (void)persistLocalProfileIfRequired;

- (NSDictionary*)generateBaseProfile;

- (void)changeUser;

- (BOOL)isEventLoggedFirstTime:(NSString*)eventName;

- (int)readUserEventLogCount:(NSString *)eventName;

- (CleverTapEventDetail *)readUserEventLog:(NSString *)eventName;

- (NSDictionary *)readUserEventLogs;

- (NSDictionary<NSString *, NSDictionary *> *)processProfileTree:(NSString *)dotNotationKey value:(id)value command:(CTProfileOperation)operation;
- (NSDictionary<NSString *, NSDictionary *> *)processProfileTreeWithJson:(NSDictionary *)newJson operation:(CTProfileOperation)operation;
- (void) updateProfileFieldsLocally: (NSDictionary<NSString *, id> *) fieldsToPersistLocally;
@end

#import <Foundation/Foundation.h>
#import "CTDeviceInfo.h"
#import "CTDispatchQueueManager.h"

@class CleverTapInstanceConfig;
@class CleverTapEventDetail;

typedef NS_ENUM(NSInteger, CTProfileOperation) {
    CTProfileOperationGet = 0,
    CTProfileOperationSet = 1,
    CTProfileOperationRemove = 2,
    CTProfileOperationAdd = 3,
    CTProfileOperationIncrement = 4,
    CTProfileOperationDecrement = 5,
    CTProfileOperationDelete = 6,
    CTProfileOperationArrayRemove = 7,
    CTProfileOperationUpdate = 8
};

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

- (NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)userAttributeChangeProperties:(NSDictionary *)event;

- (void)persistLocalProfileIfRequired;

- (NSDictionary*)generateBaseProfile;

- (void)changeUser;

- (BOOL)isEventLoggedFirstTime:(NSString*)eventName;

- (int)readUserEventLogCount:(NSString *)eventName;

- (CleverTapEventDetail *)readUserEventLog:(NSString *)eventName;

- (NSDictionary *)readUserEventLogs;

- (NSDictionary<NSString *, NSDictionary *> *)processProfileTree:(NSString *)dotNotationKey value:(id)value command:(CTProfileOperation)operation;
- (NSDictionary<NSString *, NSDictionary *> *)processProfileTreeWithJson:(NSDictionary *)newJson operation:(CTProfileOperation)operation;
@end

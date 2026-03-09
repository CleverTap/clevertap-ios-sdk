#import <Foundation/Foundation.h>
#import <CleverTapSDK/CleverTap.h>
#import "CTValidationResult.h"
#import "CleverTapInstanceConfig.h"
#import "CTDeviceInfo.h"
#import "CleverTapInternal.h"
#import "CTDomainFactory.h"

@interface CleverTap (Tests)

@property (nonatomic, strong) CTDeviceInfo * deviceInfo;
@property (nonatomic, strong) CTDispatchQueueManager *dispatchQueueManager;
@property (nonatomic, strong) CTDomainFactory *domainFactory;
@property (atomic, assign) BOOL currentUserOptedOut;
@property (atomic, assign) BOOL currentUserOptedOutAllowSystemEvents;
@property (nonatomic, assign, readonly) BOOL offline;
@property (atomic, assign) CLLocationCoordinate2D userSetLocation;
@property (nonatomic, strong) NSMutableArray *eventsQueue;
@property (nonatomic, strong) NSMutableArray *profileQueue;
@property (nonatomic, strong) NSMutableArray *notificationsQueue;

- (BOOL)_shouldDropEvent:(NSDictionary *)event withType:(CleverTapEventType)type;
- (BOOL)isMuted;
- (NSDictionary *)getCachedGUIDs;
- (NSString *)getCachedIdentitiesForConfig:(CleverTapInstanceConfig*)config;
+ (void)notfityTestAppLaunch;
- (NSDictionary *)getBatchHeader;
- (void)pushValidationResults:(NSArray<CTValidationResult *> * _Nonnull )results;
- (void)queueEvent:(NSDictionary *)event withType:(CleverTapEventType)type;
- (void)setUserSetLocation:(CLLocationCoordinate2D)location;
+ (BOOL)isPersonalizationEnabled;
- (id)getProperty:(NSString *)propertyName;
- (void)flushQueue;
- (void)clearQueue;

@end

#import <Foundation/Foundation.h>
//#import "LPSecuredVars.h"
#import "CTVar-Internal.h"
#import "CleverTapInstanceConfig.h"
#import "CTDeviceInfo.h"

NS_ASSUME_NONNULL_BEGIN

//@class LPVar;

typedef void (^CacheUpdateBlock)(void);
typedef void (^RegionInitBlock)(NSDictionary *, NSSet *, NSSet *);

NS_SWIFT_NAME(VarCache)
@interface CTVarCache : NSObject

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config deviceInfo: (CTDeviceInfo*)deviceInfo;
//NS_UNAVAILABLE;

//+(instancetype)sharedCache
//NS_SWIFT_NAME(shared());

// Handling variables.
- (CTVar *)define:(NSString *)name
             with:(nullable NSObject *)defaultValue
             kind:(nullable NSString *)kind
NS_SWIFT_NAME(define(name:value:kind:));

- (NSArray<NSString *> *)getNameComponents:(NSString *)name;
- (void)loadDiffs;
- (void)saveDiffs;

- (void)registerVariable:(CTVar *)var;
- (nullable CTVar *)getVariable:(NSString *)name;

// Handling values.
- (nullable id)getValueFromComponentArray:(NSArray<NSString *> *) components fromDict:(NSDictionary<NSString *, id> *)values;
- (nullable id)getMergedValueFromComponentArray:(NSArray<NSString *> *) components;
- (nullable NSDictionary<NSString *, id> *)diffs;
- (BOOL)hasReceivedDiffs;
- (void)applyVariableDiffs:(nullable NSDictionary<NSString *, id> *)diffs_;
- (void)onUpdate:(CacheUpdateBlock)block;
- (void)setSilent:(BOOL)silent;
- (BOOL)silent;
- (nullable NSDictionary<NSString *, id> *)defaultKinds;

//- (void)clearUserContent;

@property (strong, nonatomic) NSMutableDictionary<NSString *, id> *vars;
@property (assign, nonatomic) BOOL appLaunchedRecorded;

@end

NS_ASSUME_NONNULL_END

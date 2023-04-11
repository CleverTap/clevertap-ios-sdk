#import <Foundation/Foundation.h>
#import "CTVar-Internal.h"
#import "CleverTapInstanceConfig.h"
#import "CTDeviceInfo.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^CacheUpdateBlock)(void);

NS_SWIFT_NAME(VarCache)
@interface CTVarCache : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config deviceInfo: (CTDeviceInfo*)deviceInfo;

@property (nonatomic, strong, readonly) CleverTapInstanceConfig *config;
@property (strong, nonatomic) NSMutableDictionary<NSString *, id> *vars;
@property (assign, nonatomic) BOOL hasVarsRequestCompleted;

- (nullable NSDictionary<NSString *, id> *)diffs;
- (void)loadDiffs;
- (void)applyVariableDiffs:(nullable NSDictionary<NSString *, id> *)diffs_;

- (void)registerVariable:(CTVar *)var;
- (nullable CTVar *)getVariable:(NSString *)name;
- (id)getMergedValue:(NSString *)name;

- (NSArray<NSString *> *)getNameComponents:(NSString *)name;
- (nullable id)getMergedValueFromComponentArray:(NSArray<NSString *> *) components;
- (void)clearUserContent;

@end

NS_ASSUME_NONNULL_END

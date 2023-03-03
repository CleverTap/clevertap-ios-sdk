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

// Location initialization
//- (void)registerRegionInitBlock:(RegionInitBlock)block;

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
- (void)applyVariableDiffs:(nullable NSDictionary<NSString *, id> *)diffs_
                  messages:(nullable NSDictionary<NSString *, id> *)messages_
                  variants:(nullable NSArray<NSString *> *)variants_
                 localCaps:(nullable NSArray<NSDictionary *> *)localCaps_
                   regions:(nullable NSDictionary<NSString *, id> *)regions_
          variantDebugInfo:(nullable NSDictionary<NSString *, id> *)variantDebugInfo_
                  varsJson:(nullable NSString *)varsJson_
             varsSignature:(nullable NSString *)varsSignature_;
- (void)onUpdate:(CacheUpdateBlock)block;
- (void)setSilent:(BOOL)silent;
- (BOOL)silent;
- (int)contentVersion;
//- (nullable NSArray<NSString *> *)variants;
//- (nullable NSDictionary<NSString *, id> *)regions;
- (nullable NSDictionary<NSString *, id> *)defaultKinds;

//- (nullable NSDictionary<NSString *, id> *)variantDebugInfo;
//- (void)setVariantDebugInfo:(nullable NSDictionary<NSString *, id> *)variantDebugInfo;

//- (void)clearUserContent;
//
//- (NSArray<NSDictionary *> *)getLocalCaps;

// Development mode.
//- (void)setDevModeValuesFromServer:(nullable NSDictionary<NSString *, id> *)values
//                    fileAttributes:(nullable NSDictionary<NSString *, id> *)fileAttributes
//                 actionDefinitions:(nullable NSDictionary<NSString *, id> *)actionDefinitions;
//- (BOOL)sendVariablesIfChanged;
//- (BOOL)sendActionsIfChanged;

// Handling files.
//- (void)registerFile:(NSString *)stringValue withDefaultValue:(NSString *)defaultValue;
//- (void)maybeUploadNewFiles;
//- (nullable NSDictionary<NSString *, id> *)fileAttributes;
//
//- (nullable NSMutableDictionary<NSString *, id> *)userAttributes;
//- (void)saveUserAttributes;

//- (LPSecuredVars *)securedVars;

@property (strong, nonatomic) NSMutableDictionary<NSString *, id> *vars;
@property (assign, nonatomic) BOOL appLaunchedRecorded;

@end

NS_ASSUME_NONNULL_END

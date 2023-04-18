#import "CTVar.h"
@class CTVarCache;

NS_ASSUME_NONNULL_BEGIN

@interface CTVar ()

- (instancetype)initWithName:(NSString *)name
            withDefaultValue:(NSObject *)defaultValue
                    withKind:(NSString *)kind
                    varCache:(CTVarCache *)cache;

@property (readonly, strong) CTVarCache *varCache;
@property (readonly, strong) NSString *name;
@property (readonly, strong) NSArray *nameComponents;
@property (readonly) BOOL hadStarted;
@property (readonly, strong) NSString *kind;
@property (readonly, strong) NSMutableArray *valueChangedBlocks;
@property (nonatomic, unsafe_unretained, nullable) id <CTVarDelegate> delegate;
@property (readonly) BOOL hasChanged;

- (void)update;
- (void)cacheComputedValues;
- (void)triggerValueChanged;

+ (BOOL)printedCallbackWarning;
+ (void)setPrintedCallbackWarning:(BOOL)newPrintedCallbackWarning;

@end

NS_ASSUME_NONNULL_END

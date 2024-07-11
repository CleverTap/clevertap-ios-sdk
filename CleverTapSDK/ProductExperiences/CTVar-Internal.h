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
@property (readonly, strong) NSMutableArray *fileReadyBlocks;
@property (nonatomic, unsafe_unretained, nullable) id <CTVarDelegate> delegate;
@property (readonly) BOOL hasChanged;
@property (readonly) BOOL shouldDownloadFile;
@property (readonly, strong, nullable) NSString *fileURL;

- (BOOL)update;
- (void)cacheComputedValues;
- (void)triggerValueChanged;
- (void)triggerFileIsReady;

+ (BOOL)printedCallbackWarning;
+ (void)setPrintedCallbackWarning:(BOOL)newPrintedCallbackWarning;

@end

NS_ASSUME_NONNULL_END

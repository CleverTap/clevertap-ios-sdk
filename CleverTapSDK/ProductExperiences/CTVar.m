#import "CTVar-Internal.h"
#import "CTVarCache.h"
#import "CTConstants.h"
// TODO: commented files
//#import "LPFileManager.h"

static BOOL LPVAR_PRINTED_CALLBACK_WARNING = NO;
CTVarCache *varCache;
@interface CTVar (PrivateProperties)


@property (nonatomic) BOOL isInternal;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *nameComponents;
@property (nonatomic, strong) NSString *stringValue;
@property (nonatomic, strong) NSNumber *numberValue;
@property (nonatomic) BOOL hadStarted;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) id defaultValue;
@property (nonatomic, strong) NSString *kind;
@property (nonatomic, strong) NSMutableArray *fileReadyBlocks;
@property (nonatomic, strong) NSMutableArray *valueChangedBlocks;
//@property (nonatomic, strong) LPVarCache *varCache;
@property (nonatomic) BOOL fileIsPending;
@property (nonatomic) BOOL hasChanged;

@end

@implementation CTVar

@synthesize stringValue=_stringValue;
@synthesize numberValue=_numberValue;
@synthesize hadStarted=_hadStarted;
@synthesize hasChanged=_hasChanged;

+ (BOOL)printedCallbackWarning
{
    return LPVAR_PRINTED_CALLBACK_WARNING;
}

+ (void)setPrintedCallbackWarning:(BOOL)newPrintedCallbackWarning
{
    LPVAR_PRINTED_CALLBACK_WARNING = newPrintedCallbackWarning;
}

- (instancetype)initWithName:(NSString *)name withComponents:(NSArray *)components
            withDefaultValue:(NSNumber *)defaultValue withKind:(NSString *)kind varCache:(CTVarCache *)cache
{
    self = [super init];
    if (self) {
        CT_TRY
        _name = name;
        varCache = cache;
        _nameComponents = [varCache getNameComponents:name];
        _defaultValue = defaultValue;
        _value = defaultValue;
        _kind = kind;
        [self cacheComputedValues];
        
        [varCache registerVariable:self];
        
        [self update];
        CT_END_TRY
    }
    return self;
}

#pragma mark Defines

//+ (LPVar *)define:(NSString *)name
//{
//    return [[LPVarCache sharedCache] define:name with:nil kind:nil];
//}
//
//+ (LPVar *)define:(NSString *)name withInt:(int)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name with:[NSNumber numberWithInt:defaultValue] kind:LP_KIND_INT];
//}
//
//+ (LPVar *)define:(NSString *)name withFloat:(float)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name with:[NSNumber numberWithFloat:defaultValue] kind:LP_KIND_FLOAT];
//}
//
//+ (LPVar *)define:(NSString *)name withDouble:(double)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name
//                         with:[NSNumber numberWithDouble:defaultValue]
//                         kind:LP_KIND_FLOAT];
//}
//
//+ (LPVar *)define:(NSString *)name withCGFloat:(CGFloat)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name
//                         with:[NSNumber numberWithDouble:defaultValue]
//                         kind:LP_KIND_FLOAT];
//}
//
//+ (LPVar *)define:(NSString *)name withShort:(short)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name
//                         with:[NSNumber numberWithShort:defaultValue]
//                         kind:LP_KIND_INT];
//}
//
//+ (LPVar *)define:(NSString *)name withChar:(char)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name
//                         with:[NSNumber numberWithChar:defaultValue]
//                         kind:LP_KIND_INT];
//}
//
//+ (LPVar *)define:(NSString *)name withBool:(BOOL)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name
//                         with:[NSNumber numberWithBool:defaultValue]
//                         kind:LP_KIND_BOOLEAN];
//}
//
//+ (LPVar *)define:(NSString *)name withInteger:(NSInteger)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name
//                         with:[NSNumber numberWithInteger:defaultValue]
//                         kind:LP_KIND_INT];
//}
//
//+ (LPVar *)define:(NSString *)name withLong:(long)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name
//                         with:[NSNumber numberWithLong:defaultValue]
//                         kind:LP_KIND_INT];
//}
//
//+ (LPVar *)define:(NSString *)name withLongLong:(long long)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name
//                         with:[NSNumber numberWithLongLong:defaultValue]
//                         kind:LP_KIND_INT];
//}
//
//+ (LPVar *)define:(NSString *)name withUnsignedChar:(unsigned char)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name
//                         with:[NSNumber numberWithUnsignedChar:defaultValue]
//                         kind:LP_KIND_INT];
//}
//
//+ (LPVar *)define:(NSString *)name withUnsignedInt:(unsigned int)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name
//                         with:[NSNumber numberWithUnsignedInt:defaultValue]
//                         kind:LP_KIND_INT];
//}
//
//+ (LPVar *)define:(NSString *)name withUnsignedInteger:(NSUInteger)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name
//                         with:[NSNumber numberWithUnsignedInteger:defaultValue]
//                         kind:LP_KIND_INT];
//}
//
//+ (LPVar *)define:(NSString *)name withUnsignedLong:(unsigned long)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name
//                         with:[NSNumber numberWithUnsignedLong:defaultValue]
//                         kind:LP_KIND_INT];
//}
//
//+ (LPVar *)define:(NSString *)name withUnsignedLongLong:(unsigned long long)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name
//                         with:[NSNumber numberWithUnsignedLongLong:defaultValue]
//                         kind:LP_KIND_INT];
//}
//
//+ (LPVar *)define:(NSString *)name withUnsignedShort:(unsigned short)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name
//                         with:[NSNumber numberWithUnsignedShort:defaultValue]
//                         kind:LP_KIND_INT];
//}
//
//+ (LPVar *)define:(NSString *)name withString:(NSString *)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name with:defaultValue kind:LP_KIND_STRING];
//}
//
//+ (LPVar *)define:(NSString *)name withNumber:(NSNumber *)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name with:defaultValue kind:LP_KIND_FLOAT];
//}

// TODO: commented files
//+ (LPVar *)define:(NSString *)name withFile:(NSString *)defaultFilename
//{
//    return [[LPVarCache sharedCache] define:name with:defaultFilename kind:LP_KIND_FILE];
//}

//+ (LPVar *)define:(NSString *)name withDictionary:(NSDictionary *)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name with:defaultValue kind:LP_KIND_DICTIONARY];
//}
//
//+ (LPVar *)define:(NSString *)name withArray:(NSArray *)defaultValue
//{
//    return [[LPVarCache sharedCache] define:name with:defaultValue kind:LP_KIND_ARRAY];
//}

#pragma mark Updating

- (void) cacheComputedValues
{
    // Cache computed values.
    if ([_value isKindOfClass:NSString.class]) {
        _stringValue = (NSString *) _value;
        _numberValue = [NSNumber numberWithDouble:[_stringValue doubleValue]];
    } else if ([_value isKindOfClass:NSNumber.class]) {
        _stringValue = [NSString stringWithFormat:@"%@", _value];
        _numberValue = (NSNumber *) _value;
    } else {
        _stringValue = nil;
        _numberValue = nil;
    }
}

- (void)update
{
    NSObject *oldValue = _value;
    _value = [varCache getMergedValueFromComponentArray:_nameComponents];
    
    if ([_value isEqual:oldValue] && _hadStarted) {
        return;
    }
    [self cacheComputedValues];
    
    if (![_value isEqual:oldValue]) {
        _hasChanged = YES;
    }
    
    if (varCache.silent) {
        return;
    }
    
    if (varCache.appLaunchedRecorded) {
        [self triggerValueChanged];
        _hadStarted = YES;
    }
}

#pragma mark Basic accessors

- (void)triggerValueChanged
{
    
    // TODO: will we provide both protocol valueDidChange method and valueChanged callback block?
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(valueDidChange:)]) {
        [self.delegate valueDidChange:self];
    }
    
    for (CleverTapVariablesChangedBlock block in _valueChangedBlocks.copy) {
        block();
    }
}

- (void)onValueChanged:(CleverTapVariablesChangedBlock)block
{
    if (!block) {
        CleverTapLogStaticDebug(@"Nil block parameter provided while calling [CTVar onValueChanged].");
        return;
    }
    
    CT_TRY
    if (!_valueChangedBlocks) {
        _valueChangedBlocks = [NSMutableArray array];
    }
    [_valueChangedBlocks addObject:[block copy]];
    if (varCache.appLaunchedRecorded) {
        [self triggerValueChanged];
    }
    CT_END_TRY
}

// TODO: Check if this method is needed
- (void)setDelegate:(id<CTVarDelegate>)delegate
{
//    CT_TRY
    _delegate = delegate;
    
    // TODO: commented files
//    if ([LPInternalState sharedState].hasStarted && !_fileIsPending) {
//        [self triggerFileIsReady];
//    }
//    CT_END_TRY
}

// TODO: decide if this method is relevant
- (void)warnIfNotStarted
{
    // TODO: Add hasStarted equivalent logic
    
//    if (!_isInternal && ![LPInternalState sharedState].hasStarted && ![LPVar printedCallbackWarning]) {
//        LPLog(LPInfo, @"Leanplum hasn't finished retrieving values from the server. You "
//              @"should use a callback to make sure the value for '%@' is ready. Otherwise, your "
//              @"app may not use the most up-to-date value.", self.name);
    
//        [CTVar setPrintedCallbackWarning:YES];
//    }
}

#pragma mark Dictionary handling

- (id) objectForKey:(NSString *)key
{
    return [self objectForKeyPath:key, nil];
}

- (id) objectAtIndex:(NSUInteger)index
{
    return [self objectForKeyPath:@(index), nil];
}

- (id) objectForKeyPath:(id)firstComponent, ...
{
    CT_TRY
    [self warnIfNotStarted];
    NSMutableArray *components = [_nameComponents mutableCopy];
    va_list args;
    va_start(args, firstComponent);
    for (id component = firstComponent;
         component != nil; component = va_arg(args, id)) {
        [components addObject:component];
    }
    va_end(args);
    return [varCache getMergedValueFromComponentArray:components];
    CT_END_TRY
    return nil;
}

- (id)objectForKeyPathComponents:(NSArray *)pathComponents
{
    CT_TRY
    [self warnIfNotStarted];
    NSMutableArray *components = [_nameComponents mutableCopy];
    [components addObjectsFromArray:pathComponents];
    return [varCache getMergedValueFromComponentArray:components];
    CT_END_TRY
    return nil;
}

#pragma mark Value accessors

- (NSNumber *)numberValue
{
    [self warnIfNotStarted];
    return _numberValue;
}

- (NSString *)stringValue
{
    [self warnIfNotStarted];
    return _stringValue;
}

- (int)intValue { return [[self numberValue] intValue]; }
- (double)doubleValue { return [[self numberValue] doubleValue];}
- (float)floatValue { return [[self numberValue] floatValue]; }
- (CGFloat)cgFloatValue { return [[self numberValue] doubleValue]; }
- (short)shortValue { return [[self numberValue] shortValue];}
- (BOOL)boolValue { return [[self numberValue] boolValue]; }
- (char)charValue { return [[self numberValue] charValue]; }
- (long)longValue { return [[self numberValue] longValue]; }
- (long long)longLongValue { return [[self numberValue] longLongValue]; }
- (NSInteger)integerValue { return [[self numberValue] integerValue]; }
- (unsigned char)unsignedCharValue { return [[self numberValue] unsignedCharValue]; }
- (unsigned short)unsignedShortValue { return [[self numberValue] unsignedShortValue]; }
- (unsigned int)unsignedIntValue { return [[self numberValue] unsignedIntValue]; }
- (NSUInteger)unsignedIntegerValue { return [[self numberValue] unsignedIntegerValue]; }
- (unsigned long)unsignedLongValue { return [[self numberValue] unsignedLongValue]; }
- (unsigned long long)unsignedLongLongValue { return [[self numberValue] unsignedLongLongValue]; }

@end

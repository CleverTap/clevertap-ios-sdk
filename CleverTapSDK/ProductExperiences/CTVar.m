#import "CTVar-Internal.h"
#import "CTVarCache.h"
#import "CTConstants.h"

static BOOL LPVAR_PRINTED_CALLBACK_WARNING = NO;

@interface CTVar (PrivateProperties)
@property (nonatomic, strong) CTVarCache *varCache;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *nameComponents;
@property (nonatomic, strong) NSString *stringValue;
@property (nonatomic, strong) NSNumber *numberValue;
@property (nonatomic, strong) NSString *fileValue;
@property (nonatomic, strong) NSString *fileURL;
@property (nonatomic) BOOL hadStarted;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) id defaultValue;
@property (nonatomic, strong) NSString *kind;
@property (nonatomic, strong) NSMutableArray *valueChangedBlocks;
@property (nonatomic, strong) NSMutableArray *fileReadyBlocks;
@property (nonatomic) BOOL hasChanged;
@property (nonatomic) BOOL shouldDownloadFile;
@end

@implementation CTVar

- (instancetype)initWithName:(NSString *)name withDefaultValue:(NSNumber *)defaultValue
                    withKind:(NSString *)kind varCache:(CTVarCache *)cache {
    self = [super init];
    if (self) {
        CT_TRY
        _name = name;
        self.varCache = cache;
        _nameComponents = [self.varCache getNameComponents:name];
        _defaultValue = defaultValue;
        _value = defaultValue;
        _kind = kind;
        [self cacheComputedValues];
        
        // If the file is defined after the Vars request has completed,
        // file needs to be downloaded individually
        if ([_kind isEqualToString:CT_KIND_FILE] && [[self varCache] hasVarsRequestCompleted]) {
            _shouldDownloadFile = YES;
        }
        
        [self.varCache registerVariable:self];
        
        [self update];
        
        // Store the actual file URL as _value returns path of file downloaded
        // after the var update
        if ([_kind isEqualToString:CT_KIND_FILE]) {
            _fileURL = _value;
        }
        CT_END_TRY
    }
    return self;
}

// Manually @synthesize since CTVar provides custom getters/setters
// Properties are defined as readonly in CTVar-Internal
// and readwrite in PrivateProperties category
@synthesize value = _value;
@synthesize stringValue = _stringValue;
@synthesize numberValue = _numberValue;
@synthesize varCache = _varCache;
@synthesize fileValue = _fileValue;

- (CTVarCache *)varCache {
    return _varCache;
}

- (void)setVarCache:(CTVarCache *)varCache {
    _varCache = varCache;
}

#pragma mark Updates

- (void)cacheComputedValues {
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

- (BOOL)update {
    NSObject *oldValue = _value;
    _value = [self.varCache getMergedValueFromComponentArray:_nameComponents];
    
    if ([_value isEqual:oldValue] && _hadStarted) {
        return NO;
    }
    [self cacheComputedValues];
    
    BOOL changed = NO;
    if (![_value isEqual:oldValue]) {
        _hasChanged = YES;
        changed = YES;
        // Update _fileURL with new value if it has changed.
        if ([_kind isEqualToString:CT_KIND_FILE]) {
            _fileURL = _value;
        }
    }
    
    if (_shouldDownloadFile) {
        [self.varCache fileVarUpdated:self];
    }
    
    if ([[self varCache] hasVarsRequestCompleted]) {
        [self triggerValueChanged];
        _hadStarted = YES;
        _shouldDownloadFile = NO;
    }
    return changed;
}

#pragma mark Callbacks

- (void)triggerValueChanged {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(valueDidChange:)]) {
        [self.delegate valueDidChange:self];
    }
    
    if (_valueChangedBlocks && _valueChangedBlocks.count > 0) {
        for (CleverTapVariablesChangedBlock block in _valueChangedBlocks.copy) {
            block();
        }
    }
}

- (void)onValueChanged:(CleverTapVariablesChangedBlock)block {
    if (!block) {
        CleverTapLogStaticDebug(@"Nil block parameter provided while calling [CTVar onValueChanged].");
        return;
    }
    
    CT_TRY
    if (!_valueChangedBlocks) {
        _valueChangedBlocks = [NSMutableArray array];
    }
    [_valueChangedBlocks addObject:[block copy]];
    if ([[self varCache] hasVarsRequestCompleted]) {
        [self triggerValueChanged];
    }
    CT_END_TRY
}

- (void)setDelegate:(id<CTVarDelegate>)delegate {
    CT_TRY
    _delegate = delegate;
    if ([[self varCache] hasVarsRequestCompleted]) {
        [self triggerValueChanged];
    }
    
    // Call fileIsReady if value is already fetched and file is already present.
    if ([_kind isEqualToString:CT_KIND_FILE] && _fileURL) {
        if ([self.varCache isFileAlreadyPresent:_fileURL]) {
            [self triggerFileIsReady];
        }
    }
    CT_END_TRY
}

#pragma mark File Handling

- (void)onFileIsReady:(CleverTapVariablesChangedBlock)block {
    if (!block) {
        CleverTapLogStaticDebug(@"Nil block parameter provided while calling [CTVar onFileIsReady].");
        return;
    }
    
    if (![_kind isEqualToString:CT_KIND_FILE]) {
        CleverTapLogStaticDebug(@"[CTVar onFileIsReady] is only available for File Variables.");
        return;
    }
    
    CT_TRY
    if (!_fileReadyBlocks) {
        _fileReadyBlocks = [NSMutableArray array];
    }
    [_fileReadyBlocks addObject:[block copy]];
    if ([self.varCache isFileAlreadyPresent:_fileURL]) {
        [self triggerFileIsReady];
    }
    CT_END_TRY
}

- (void)triggerFileIsReady {
    if (self.delegate &&
        [self.delegate respondsToSelector:@selector(fileIsReady:)]) {
        [self.delegate fileIsReady:self];
    }
    
    if (_fileReadyBlocks && _fileReadyBlocks.count > 0) {
        for (CleverTapVariablesChangedBlock block in _fileReadyBlocks.copy) {
            block();
        }
    }
}

- (nullable NSString *)fileValue {
    [self warnIfNotStarted];
    if ([_kind isEqualToString:CT_KIND_FILE]) {
        return [self.varCache fileDownloadPath:_fileURL];
    }
    return nil;
}

#pragma mark Dictionary handling

- (id)objectForKey:(NSString *)key {
    return [self objectForKeyPath:key, nil];
}

- (id)objectAtIndex:(NSUInteger)index {
    return [self objectForKeyPath:@(index), nil];
}

- (id)objectForKeyPath:(id)firstComponent, ... {
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
    return [self.varCache getMergedValueFromComponentArray:components];
    CT_END_TRY
    return nil;
}

- (id)objectForKeyPathComponents:(NSArray *)pathComponents {
    CT_TRY
    [self warnIfNotStarted];
    NSMutableArray *components = [_nameComponents mutableCopy];
    [components addObjectsFromArray:pathComponents];
    return [self.varCache getMergedValueFromComponentArray:components];
    CT_END_TRY
    return nil;
}

#pragma mark Value accessors

- (id)value {
    [self warnIfNotStarted];
    if ([_kind isEqualToString:CT_KIND_FILE]) {
        return [self.varCache fileDownloadPath:_fileURL];
    }
    return _value;
}

- (NSNumber *)numberValue {
    [self warnIfNotStarted];
    return _numberValue;
}

- (NSString *)stringValue {
    [self warnIfNotStarted];
    if ([_kind isEqualToString:CT_KIND_FILE]) {
        return [self.varCache fileDownloadPath:_fileURL];
    }
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

#pragma mark Utils

+ (BOOL)printedCallbackWarning {
    return LPVAR_PRINTED_CALLBACK_WARNING;
}

+ (void)setPrintedCallbackWarning:(BOOL)newPrintedCallbackWarning {
    LPVAR_PRINTED_CALLBACK_WARNING = newPrintedCallbackWarning;
}

- (void)warnIfNotStarted {
    if (!self.varCache.hasVarsRequestCompleted && ![CTVar printedCallbackWarning]) {
        CleverTapLogDebug(self.varCache.config.logLevel, @"%@: CleverTap hasn't finished retrieving values from the server. You "
                          @"should use a callback to make sure the value for '%@' is ready. Otherwise, your "
                          @"app may not use the most up-to-date value.", self, self.name);
        
        [CTVar setPrintedCallbackWarning:YES];
    }
}

- (void)clearState {
    _hadStarted = NO;
    _hasChanged = NO;
}

@end

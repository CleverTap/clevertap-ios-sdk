#import "CTVarCache.h"
#import "CTUtils.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "ContentMerger.h"

@interface CTVarCache()
@property (strong, nonatomic) NSRegularExpression *varNameRegex;
@property (strong, nonatomic) NSMutableDictionary<NSString *, id> *valuesFromClient;
@property (strong, nonatomic) id merged;
@property (strong, nonatomic) NSDictionary<NSString *, id> *diffs;

@property (strong, nonatomic) CacheUpdateBlock updateBlock;
@property (assign, nonatomic) BOOL hasReceivedDiffs;

@property (assign, nonatomic) BOOL silent;
@property (strong, nonatomic) RegionInitBlock regionInitBlock;

@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTDeviceInfo *deviceInfo;
@end

@implementation CTVarCache

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config deviceInfo: (CTDeviceInfo*)deviceInfo {
    if ((self = [super init])) {
        self.config = config;
        self.deviceInfo = deviceInfo;
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    self.vars = [NSMutableDictionary dictionary];
    self.diffs = [NSMutableDictionary dictionary];
    self.valuesFromClient = [NSMutableDictionary dictionary];
    self.hasReceivedDiffs = NO;
    self.silent = NO;
    NSError *error = NULL;
    self.varNameRegex = [NSRegularExpression regularExpressionWithPattern:@"(?:[^\\.\\[.(\\\\]+|\\\\.)+"
                                                             options:NSRegularExpressionCaseInsensitive error:&error];
}

- (CTVar *)define:(NSString *)name with:(NSObject *)defaultValue kind:(NSString *)kind
{
    if ([CTUtils isNullOrEmpty:name]) {
        CleverTapLogDebug(_config.logLevel, @"%@: Empty name provided as parameter while defining a variable.", self);
        return nil;
    }

    @synchronized (self.vars) {
        CT_TRY
        CTVar *existing = [self getVariable:name];
        if (existing) {
            CleverTapLogInfo(self.config.logLevel, @"%@: Variable with name: %@ already exists.", self, name);
            return existing;
        }
        CT_END_TRY
        CTVar *var = [[CTVar alloc] initWithName:name
                                  withComponents:[self getNameComponents:name]
                                withDefaultValue:defaultValue
                                        withKind:kind
                                        varCache:self];
        return var;
    }
}

- (NSArray *)arrayOfCaptureComponentsOfString:(NSString *)data matchedBy:(NSRegularExpression *)regExpression
{
    NSMutableArray *test = [NSMutableArray array];

    NSArray *matches = [regExpression matchesInString:data options:0 range:NSMakeRange(0, data.length)];

    for(NSTextCheckingResult *match in matches) {
        NSMutableArray *result = [NSMutableArray arrayWithCapacity:match.numberOfRanges];
        for(NSInteger i=0; i<match.numberOfRanges; i++) {
            NSRange matchRange = [match rangeAtIndex:i];
            NSString *matchStr = nil;
            if(matchRange.location != NSNotFound) {
                matchStr = [data substringWithRange:matchRange];
            } else {
                matchStr = @"";
            }
            [result addObject:matchStr];
        }
        [test addObject:result];
    }
    return test;
}

- (NSArray *)getNameComponents:(NSString *)name
{
    NSArray *matches = [self arrayOfCaptureComponentsOfString:name matchedBy:self.varNameRegex];
    NSMutableArray *nameComponents = [NSMutableArray array];
    for (NSArray *matchArray in matches) {
        [nameComponents addObject:matchArray[0]];
    }
    NSArray *result = [NSArray arrayWithArray:nameComponents];
    
    // iOS 3.x compatability. NSRegularExpression is not available, so there will be no components.
    if (result.count == 0) {
        return @[name];
    }
    
    return result;
}

- (id)traverse:(id)collection withKey:(id)key autoInsert:(BOOL)autoInsert
{
    id result = nil;
    if ([collection respondsToSelector:@selector(objectForKey:)]) {
        result = [collection objectForKey:key];
        if (autoInsert && !result && [key isKindOfClass:NSString.class]) {
            result = [NSMutableDictionary dictionary];
            [collection setObject:result forKey:key];
        }
    }
    
    if ([result isKindOfClass:[NSNull class]]) {
        return nil;
    }
    
    return result;
}

// Updates a JSON structure of variable values
- (void)updateValues:(NSString *)name
      nameComponents:(NSArray *)nameComponents
               value:(id)value
              values:(NSMutableDictionary *)values
{
    if (value) {
        id valuesPtr = values;
        for (int i = 0; i < nameComponents.count - 1; i++) {
            valuesPtr = [self traverse:valuesPtr withKey:nameComponents[i] autoInsert:YES];
        }
        
        // Make the value mutable. That way, if we add a dictionary variable,
        // we can still add subvariables.
        if ([value isKindOfClass:NSDictionary.class] &&
            [value class] != [NSMutableDictionary class]) {
            value = [NSMutableDictionary dictionaryWithDictionary:value];
        }
        
        // Check if value from another Variable will be overridden
        if (valuesPtr[nameComponents.lastObject] && ![valuesPtr[nameComponents.lastObject] isEqual:value]) {
            CleverTapLogInfo(self.config.logLevel, @"%@: Variable with name: %@ will override value: %@, with new value: %@.", self, name, valuesPtr[nameComponents.lastObject], value);
        }
        
        [valuesPtr setObject:value forKey:nameComponents.lastObject];
    }
}

// Merge default variable value with VarCache.merged value
// This is neccessary if variable was registered after VarCache.applyVariableDiffs
- (void)mergeVariable:(CTVar * _Nonnull)var {
    NSString *firsComponent = var.nameComponents.firstObject;
    id defaultValue = [self.valuesFromClient objectForKey:firsComponent];
    id mergedValue = [self.merged objectForKey:firsComponent];
    if (![defaultValue isEqual:mergedValue]) {
        id newValue = [ContentMerger mergeWithVars:defaultValue diff:mergedValue];
        [self.merged setObject:newValue forKey:firsComponent];
        
        NSMutableString *name = [[NSMutableString alloc] initWithString:firsComponent];
        for (int i = 1; i < var.nameComponents.count; i++)
        {
            CTVar *existingVar = self.vars[name];
            if (existingVar) {
                [existingVar update];
                break;
            }
            [name appendFormat:@".%@", var.nameComponents[i]];
        }
    }
}

- (void)registerVariable:(CTVar *)var
{
    [self.vars setObject:var forKey:var.name];
    
    [self updateValues:var.name
        nameComponents:var.nameComponents
                 value:var.defaultValue
                values:self.valuesFromClient];
    
    [self mergeVariable:var];
}

- (CTVar *)getVariable:(NSString *)name
{
    return [self.vars objectForKey:name];
}

- (id)getValueFromComponentArray:(NSArray *) components fromDict:(NSDictionary *)values
{
    id mergedPtr = values;
    for (id component in components) {
        mergedPtr = [self traverse:mergedPtr withKey:component autoInsert:NO];
    }
    return mergedPtr;
}

- (id)getMergedValueFromComponentArray:(NSArray *)components
{
    return [self getValueFromComponentArray:components fromDict:self.merged ? self.merged : self.valuesFromClient];
}

- (void)loadDiffs
{
    @try {
        NSString *fileName = [self dataArchiveFileName];
        NSString *filePath = [CTPreferences filePathfromFileName:fileName];
        NSData *diffsData = [NSData dataWithContentsOfFile:filePath];
        if (!diffsData) {
            return;
        }
        NSKeyedUnarchiver *unarchiver;
        if (@available(iOS 12.0, *)) {
            NSError *error = nil;
            unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:diffsData error:&error];
            if (error != nil) {
                CleverTapLogDebug(self.config.logLevel, @"%@: Error while loading variables: %@", self, error.localizedDescription);
                return;
            }
            unarchiver.requiresSecureCoding = NO;
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:diffsData];
#pragma clang diagnostic pop
        }
        NSDictionary *diffs = (NSDictionary *) [unarchiver decodeObjectForKey:CLEVERTAP_DEFAULTS_VARIABLES_KEY];
        
        [self applyVariableDiffs:diffs];
    } @catch (NSException *exception) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Error while loading variables: %@", self, exception.debugDescription);
    }
}

- (void)saveDiffs
{
    // Stores the variables on the device in case we don't have a connection.
    // Restores next time when the app is opened.
    // Diffs need to be locked incase other thread changes the diffs using
    // mergeHelper:.
    @synchronized (self.diffs) {
        NSMutableData *diffsData = [[NSMutableData alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:diffsData];
#pragma clang diagnostic pop
        [archiver encodeObject:self.diffs forKey:CLEVERTAP_DEFAULTS_VARIABLES_KEY];
        [archiver finishEncoding];

//        NSData *encryptedDiffs = [LPAES encryptedDataFromData:diffsData];

//        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//
//        [defaults setObject:encryptedDiffs forKey:LEANPLUM_DEFAULTS_VARIABLES_KEY];
//
//        [defaults setObject:LEANPLUM_SDK_VERSION forKey:LEANPLUM_DEFAULTS_SDK_VERSION];
//
//        [Leanplum synchronizeDefaults];
        
//        [CTPreferences putObject:diffsData forKey:CLEVERTAP_DEFAULTS_VARIABLES_KEY];
        NSError *writeError = nil;
        NSString *fileName = [self dataArchiveFileName];
        NSString *filePath = [CTPreferences filePathfromFileName:fileName];
        [diffsData writeToFile:filePath options:NSDataWritingAtomic error:&writeError];
        if (writeError) {
            CleverTapLogStaticInternal(@"%@ failed to write data at %@: %@", self, filePath, writeError);
        }
    }
}

- (NSString*)dataArchiveFileName {
    return [NSString stringWithFormat:@"clevertap-%@-%@-pe-vars.plist", _config.accountId, _deviceInfo.deviceId];
}

- (void)applyVariableDiffs:(NSDictionary *)diffs_
{
    @synchronized (self.vars) {
        if (diffs_ || (!self.silent && !self.hasReceivedDiffs)) {
            // Prevent overriding variables if API returns null
            // If no variables are defined, API returns {}
            if (diffs_ != nil && ![diffs_ isEqual:[NSNull null]]) {
                self.diffs = diffs_;
                
                // Merger helper will mutate diffs.
                // We need to lock it in case multiple threads will be accessing this.
                @synchronized (self.diffs) {
                    self.diffs = [self convert:self.diffs];
                    self.merged = [ContentMerger mergeWithVars:self.valuesFromClient diff:self.diffs];
                }

                // Update variables with new values.
                // Have to extract the keys because a dictionary variable may add a new sub-variable,
                // modifying the variable dictionary.
                for (NSString *name in [self.vars allKeys]) {
                    [self.vars[name] update];
                }
            } else {
                CleverTapLogDebug(self.config.logLevel, @"%@: No variables received from the server", self);
            }
        }
        
        // DONT SAVE VARS TO CACHE IF SILENT
        if (!self.silent) {
            [self saveDiffs];

            self.hasReceivedDiffs = YES;
            if (self.updateBlock) {
                self.updateBlock();
            }
        }
    }
}

- (void)onUpdate:(CacheUpdateBlock) block
{
    self.updateBlock = block;
}

//
//- (void)clearUserContent
//{
//    self.diffs = nil;
//    self.variants = nil;
//    self.localCaps = nil;
//    self.variantDebugInfo = nil;
//    self.vars = nil;
//    self.userAttributes = nil;
//    self.merged = nil;
//    self.varsJson = nil;
//    self.varsSignature = nil;
//
//    self.devModeValuesFromServer = nil;
//    self.devModeFileAttributesFromServer = nil;
//
//    [LPActionManager shared].messages = [NSMutableDictionary dictionary];
//    [LPActionManager shared].messagesDataFromServer = [NSMutableDictionary dictionary];
//    [LPActionManager shared].actionDefinitionsFromServer = [NSMutableDictionary dictionary];
//}
//
// Resets the VarCache to stock state. Used for testing purposes.
//- (void)reset
//{
//    [self clearUserContent];
//
//    self.filesToInspect = nil;
//    self.fileAttributes = nil;
//
//    self.valuesFromClient = nil;
//    self.defaultKinds = nil;
//
//    self.updateBlock = nil;
//    self.hasReceivedDiffs = NO;
//    self.silent = NO;
//    self.contentVersion = 0;
//    self.hasTooManyFiles = NO;
//}

- (NSDictionary*)convert:(NSDictionary*)result {
    NSMutableDictionary *varsPayload = [NSMutableDictionary dictionary];
    
    [result enumerateKeysAndObjectsUsingBlock:^(NSString* _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
        
        if ([key containsString:@"."]) {
            NSArray *components = [self getNameComponents:key];
            long namePosition =  components.count - 1;
            NSMutableDictionary *currentMap = varsPayload;
            
            for (int i = 0; i < components.count; i++) {
                NSString *component = components[i];
                if (i == namePosition) {
                    currentMap[component] = value;
                }
                else {
                    if (!currentMap[component]) {
                        NSMutableDictionary *nestedMap = [NSMutableDictionary dictionary];
                        currentMap[component] = nestedMap;
                        currentMap = nestedMap;
                    }
                    else {
                        currentMap = ((NSMutableDictionary*)currentMap[component]);
                    }
                }
            }
        }
        else {
            varsPayload[key] = value;
        }
    }];
    
    return varsPayload;
}

@end

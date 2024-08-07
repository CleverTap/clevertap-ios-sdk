#import "CTVarCache.h"
#import "CTUtils.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "ContentMerger.h"

@interface CTVarCache()
@property (strong, nonatomic) NSMutableDictionary<NSString *, id> *valuesFromClient;
@property (strong, nonatomic) id merged;
@property (strong, nonatomic) NSDictionary<NSString *, id> *diffs;

@property (strong, nonatomic) CacheUpdateBlock updateBlock;
@property (nonatomic, strong) CleverTapInstanceConfig *config;
@property (nonatomic, strong) CTDeviceInfo *deviceInfo;
@property (nonatomic, strong) CTFileDownloader *fileDownloader;
@property (strong, nonatomic) NSMutableDictionary<NSString *, id> *fileVarsInDownload;
@end

@implementation CTVarCache

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config 
                    deviceInfo:(CTDeviceInfo*)deviceInfo
                fileDownloader:(CTFileDownloader *)fileDownloader {
    if ((self = [super init])) {
        self.config = config;
        self.deviceInfo = deviceInfo;
        self.fileDownloader = fileDownloader;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.vars = [NSMutableDictionary dictionary];
    self.diffs = [NSMutableDictionary dictionary];
    self.valuesFromClient = [NSMutableDictionary dictionary];
    self.hasVarsRequestCompleted = NO;
    self.hasPendingDownloads = NO;
    self.fileVarsInDownload = [NSMutableDictionary dictionary];
}

- (NSArray *)getNameComponents:(NSString *)name {
    NSArray *nameComponents = [name componentsSeparatedByString:@"."];
    return nameComponents;
}

- (id)traverse:(id)collection withKey:(id)key autoInsert:(BOOL)autoInsert {
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
        
        // Do not override variable dictionary values. If value is dictionary and
        // already registered variable value is a dictionary, merge them.
        // If values are not dictionaries, check if value from another variable will be overridden and log it.
        id currentValue = valuesPtr[nameComponents.lastObject];
        if (currentValue && [currentValue isKindOfClass:NSDictionary.class] && [value isKindOfClass:NSMutableDictionary.class]) {
            // Merge all entries from both dictionaries. NSMutableDictionary addEntriesFromDictionary: will not work for nested dictionaries.
            value = [ContentMerger mergeWithVars:value diff:currentValue];
        } else if (currentValue && ![currentValue isEqual:value]) {
            CleverTapLogInfo(self.config.logLevel, @"%@: Variable with name: %@ will override value: %@, with new value: %@.", self, name, currentValue, value);
        }
        
        [valuesPtr setObject:value forKey:nameComponents.lastObject];
    }
}

// Merge default variable value with VarCache.merged value
// This is neccessary if variable was registered after VarCache.applyVariableDiffs
- (void)mergeVariable:(CTVar * _Nonnull)var {
    if (!self.merged || ![self.merged isKindOfClass:[NSMutableDictionary class]]) {
        return;
    }
    
    NSString *firstComponent = var.nameComponents.firstObject;
    id defaultValue = [self.valuesFromClient objectForKey:firstComponent];
    id mergedValue = [self.merged objectForKey:firstComponent];
    
    BOOL shouldMerge = (!defaultValue && mergedValue) ||
    (defaultValue && ![defaultValue isEqual:mergedValue]);
    if (shouldMerge) {
        id newValue = [ContentMerger mergeWithVars:defaultValue diff:mergedValue];
        if (newValue == nil) {
            return;
        }
        [self.merged setObject:newValue forKey:firstComponent];
        
        NSMutableString *name = [[NSMutableString alloc] initWithString:firstComponent];
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

- (void)registerVariable:(CTVar *)var {
    [self.vars setObject:var forKey:var.name];
    
    [self updateValues:var.name
        nameComponents:var.nameComponents
                 value:var.defaultValue
                values:self.valuesFromClient];
    
    [self mergeVariable:var];
}

- (CTVar *)getVariable:(NSString *)name {
    return [self.vars objectForKey:name];
}

- (id)getMergedValue:(NSString *)name {
    NSArray *components = [self getNameComponents:name];
    id value = [self getMergedValueFromComponentArray:components];
    if ([value conformsToProtocol:@protocol(NSCopying)] && [value respondsToSelector:@selector(copyWithZone:)]) {
        if ([value respondsToSelector:@selector(mutableCopyWithZone:)]) {
            return [value mutableCopy];
        }
        return [value copy];
    }
    
    return value;
}

- (id)getValueFromComponentArray:(NSArray *) components fromDict:(NSDictionary *)values {
    id mergedPtr = values;
    for (id component in components) {
        mergedPtr = [self traverse:mergedPtr withKey:component autoInsert:NO];
    }
    return mergedPtr;
}

- (id)getMergedValueFromComponentArray:(NSArray *)components {
    return [self getValueFromComponentArray:components fromDict:self.merged ? self.merged : self.valuesFromClient];
}

- (void)loadDiffs {
    @try {
        NSString *fileName = [self dataArchiveFileName];
        NSString *filePath = [CTPreferences filePathfromFileName:fileName];
        NSData *diffsData = [NSData dataWithContentsOfFile:filePath];
        if (!diffsData) {
            [self applyVariableDiffs:@{}];
            return;
        }
        NSKeyedUnarchiver *unarchiver;
        if (@available(iOS 12.0, tvOS 11.0, *)) {
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

- (void)saveDiffs {
    // Stores the variables on the device in case we don't have a connection.
    // Restores next time when the app is opened.
    // Diffs need to be locked incase other thread changes the diffs
    @synchronized (self.diffs) {
        NSMutableData *diffsData = [[NSMutableData alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:diffsData];
#pragma clang diagnostic pop
        [archiver encodeObject:self.diffs forKey:CLEVERTAP_DEFAULTS_VARIABLES_KEY];
        [archiver finishEncoding];
        
        NSError *writeError = nil;
        NSString *fileName = [self dataArchiveFileName];
        NSString *filePath = [CTPreferences filePathfromFileName:fileName];
        NSDataWritingOptions fileProtectionOption = _config.enableFileProtection ? NSDataWritingFileProtectionComplete : NSDataWritingAtomic;
        [diffsData writeToFile:filePath options:fileProtectionOption error:&writeError];
        if (writeError) {
            CleverTapLogStaticInternal(@"%@ failed to write data at %@: %@", self, filePath, writeError);
        }
    }
}

- (NSString*)dataArchiveFileName {
    return [NSString stringWithFormat:@"clevertap-%@-%@-pe-vars.plist", _config.accountId, _deviceInfo.deviceId];
}

- (void)applyVariableDiffs:(NSDictionary *)diffs_ {
    CleverTapLogDebug(self.config.logLevel, @"%@: Applying Variables: %@", self, diffs_);
    @synchronized (self.vars) {
        // Prevent overriding variables if API returns null
        // If no variables are defined, API returns {}
        if (diffs_ != nil && ![diffs_ isEqual:[NSNull null]]) {
            self.diffs = diffs_;
            
            // We need to lock it in case multiple threads will be accessing this.
            @synchronized (self.diffs) {
                self.merged = [ContentMerger mergeWithVars:self.valuesFromClient diff:self.diffs];
            }
            
            // Update variables with new values.
            // Have to extract the keys because a dictionary variable may add a new sub-variable,
            // modifying the variable dictionary.
            NSMutableArray *updatedFileVariables = [NSMutableArray array];
            for (NSString *name in [self.vars allKeys]) {
                CTVar *var = self.vars[name];
                // Always update the variable
                BOOL hasChanged = [var update];
                if (hasChanged && [var.kind isEqualToString:CT_KIND_FILE]) {
                    [updatedFileVariables addObject:var];
                }
            }
            
            NSMutableArray *fileURLs = [self fileURLs:updatedFileVariables];
            if ([fileURLs count] > 0) {
                [self setHasPendingDownloads:YES];
                [self startFileDownload:fileURLs];
            } else {
                [self.delegate triggerNoDownloadsPending];
            }
        } else {
            CleverTapLogDebug(self.config.logLevel, @"%@: No variables received from the server", self);
        }
        
        // Do NOT save diffs when loading from cache
        // Load diffs is called before vars request has been sent
        if (self.hasVarsRequestCompleted) {
            [self saveDiffs];
        }
    }
}

- (void)clearUserContent {
    // Disable callbacks and wait until fetch is finished
    [self setHasVarsRequestCompleted:NO];
    // Clear Var state to allow callback invocation when server values are downloaded
    [self.vars enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        CTVar *var = (CTVar *)obj;
        [var clearState];
    }];
}

#pragma mark - File Handling

- (void)startFileDownload:(NSMutableArray *)fileURLs {
    [self.fileDownloader downloadFiles:fileURLs withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
        NSMutableArray<NSString *> *retryURLs = [NSMutableArray new];
        // Call fileIsReady for variables whose files are downloaded.
        for (NSString *key in status.allKeys) {
            if ([status[key] boolValue]) {
                @synchronized (self) {
                    [self.fileVarsInDownload[key] triggerFileIsReady];
                    [self.fileVarsInDownload removeObjectForKey:key];
                }
            } else {
                [retryURLs addObject:key];
            }
        }
        // Retry once if a URL failed to download
        if (retryURLs.count == 0) {
            [self setHasPendingDownloads:NO];
            [self.delegate triggerNoDownloadsPending];
        } else {
            [self retryFileDownload:retryURLs];
        }
    }];
}

- (nullable NSString *)fileDownloadPath:(NSString *)fileURL {
    return [self.fileDownloader fileDownloadPath:fileURL];
}

- (BOOL)isFileAlreadyPresent:(NSString *)fileURL {
    return [self.fileDownloader isFileAlreadyPresent:fileURL andUpdateExpiryTime:YES];
}

- (NSMutableArray<NSString *> *)fileURLs:(NSArray *)fileVars {
    NSMutableArray<NSString *> *downloadURLs = [NSMutableArray new];
    for (CTVar *var in fileVars) {
        if (var.fileURL) {
            // If file is already present, call fileIsReady
            // else download the file and call fileIsReady when downloaded
            if ([self isFileAlreadyPresent:var.fileURL]) {
                [var triggerFileIsReady];
            } else {
                [downloadURLs addObject:var.fileURL];
                @synchronized (self) {
                    [self.fileVarsInDownload setObject:var forKey:var.fileURL];
                }
            }
        } else {
            // Trigger FileIsReady since the value changed to null (no override)
            [var triggerFileIsReady];
        }
    }
    
    return downloadURLs;
}

- (void)retryFileDownload:(NSMutableArray *)urls {
    [self.fileDownloader downloadFiles:urls withCompletionBlock:^(NSDictionary<NSString *,id> * _Nullable status) {
        [self setHasPendingDownloads:NO];
        for (NSString *key in status.allKeys) {
            @synchronized (self) {
                if ([status[key] boolValue]) {
                    [self.fileVarsInDownload[key] triggerFileIsReady];
                }
                [self.fileVarsInDownload removeObjectForKey:key];
            }
        }
        [self.delegate triggerNoDownloadsPending];
    }];
}

- (void)fileVarUpdated:(CTVar *)fileVar {
    NSString *url = fileVar.fileURL;
    if (!url) {
        // FileIsReady is not triggered if there is no override, fileURL is nil
        return;
    }
    
    if ([self isFileAlreadyPresent:url]) {
        [fileVar triggerFileIsReady];
    } else {
        [self.fileDownloader downloadFiles:@[url] withCompletionBlock:^(NSDictionary<NSString *,NSNumber *> * _Nonnull status) {
            if ([status[url] boolValue]) {
                [fileVar triggerFileIsReady];
            }
        }];
    }
}

@end

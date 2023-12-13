#import "CTPreferences.h"
#import "CTConstants.h"

#define PREF_PREFIX @"WizRocket"

@implementation CTPreferences

+ (long)getIntForKey:(NSString *)key withResetValue:(long)resetValue {
    key = [NSString stringWithFormat:@"%@%@", PREF_PREFIX, key];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id value = [defaults objectForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        return ((long) [value longLongValue]);
    } else {
        [defaults setObject:@(resetValue) forKey:key];
        [defaults synchronize];
    }
    return resetValue;
}

+ (void)putInt:(long)resetValue forKey:(NSString *)key {
    key = [NSString stringWithFormat:@"%@%@", PREF_PREFIX, key];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(resetValue) forKey:key];
    [defaults synchronize];
}

+ (NSString *_Nullable)getStringForKey:(NSString *_Nonnull)key withResetValue:(NSString *_Nullable)resetValue {
    key = [NSString stringWithFormat:@"%@%@", PREF_PREFIX, key];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id value = [defaults objectForKey:key];
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    } else {
        if (resetValue != nil) {
            [defaults setObject:resetValue forKey:key];
            [defaults synchronize];
        }
    }
    return resetValue;
}

+ (void)putString:(NSString *)resetValue forKey:(NSString *)key {
    key = [NSString stringWithFormat:@"%@%@", PREF_PREFIX, key];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:resetValue forKey:key];
    [defaults synchronize];
}

+ (id)getObjectForKey:(NSString *)key {
    key = [NSString stringWithFormat:@"%@%@", PREF_PREFIX, key];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:key];
}

+ (void)putObject:(id)object forKey:(NSString *)key {
    key = [NSString stringWithFormat:@"%@%@", PREF_PREFIX, key];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:object forKey:key];
    [defaults synchronize];
}

+ (void)removeObjectForKey:(NSString *)key {
    key = [NSString stringWithFormat:@"%@%@", PREF_PREFIX, key];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:key];
    [defaults synchronize];
}

+ (NSString *)filePathfromFileName:(NSString *)filename {
#if defined(CLEVERTAP_TVOS) // on apple tv can only write to caches directory, which is at risk of being purged when app isn't running
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject]
            stringByAppendingPathComponent:filename];
#else
    return [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
            stringByAppendingPathComponent:filename];
#endif
}

+ (void)logUnarchiveError:(NSError *)error filePath:(NSString *)filePath removeFile:(BOOL)remove {
    if (error) {
        CleverTapLogStaticInternal(@"%@ failed to unarchive data from %@ - %@", self, filePath, error);
    }
    
    if (remove && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError *error;
        BOOL removed = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        
        if (!removed) {
            CleverTapLogStaticInternal(@"%@ failed to remove archived file at %@ - %@", self, filePath, error);
        }
    }
}

+ (id _Nullable)unarchiveFromFile:(NSString *_Nonnull)filename ofTypes:(nonnull NSSet<Class> *)classes removeFile:(BOOL)remove {
    id data = nil;
    NSError *error = nil;
    NSString *filePath = [self filePathfromFileName:filename];
    
    @try {
        if (@available(iOS 11.0, tvOS 11.0, *)) {
            NSData *newData = [NSData dataWithContentsOfFile:filePath];
            if (newData == NULL) {
                CleverTapLogStaticInternal(@"%@ file not found %@", self, filePath);
            } else {
                data = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:newData error:&error];
                CleverTapLogStaticInternal(@"%@ unarchived data from %@: %@", self, filePath, data);
            }
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            data = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
#pragma clang diagnostic pop
            CleverTapLogStaticInternal(@"%@ unarchived data from %@: %@", self, filePath, data);
        }
    }
    @catch (NSException *e) {
        CleverTapLogStaticInternal(@"%@ failed to unarchive data from %@", self, filePath);
    }
    [self logUnarchiveError:error filePath:filePath removeFile:remove];
    
    return data;
}

+ (id _Nullable)unarchiveFromFile:(NSString *_Nonnull)filename ofType:(Class _Nonnull)cls  removeFile:(BOOL)remove{
    id data = nil;
    NSError *error = nil;
    
    NSString *filePath = [self filePathfromFileName:filename];
    
    @try {
        if (@available(iOS 11.0, tvOS 11.0 , *)) {
            NSData *newData = [NSData dataWithContentsOfFile:filePath];
            if (newData == NULL) {
                CleverTapLogStaticInternal(@"%@ file not found %@", self, filePath);
            } else {
                // Allow NSString, NSDictionary, NSNumber and NSSet unarchiving
                NSSet *allowedClasses = [NSSet setWithObjects:cls, [NSArray class], [NSString class], [NSDictionary class], [NSNumber class], nil];
                data = [NSKeyedUnarchiver unarchivedObjectOfClasses:allowedClasses fromData:newData error:&error];
                CleverTapLogStaticInternal(@"%@ unarchived data from %@: %@", self, filePath, data);
            }
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            data = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
#pragma clang diagnostic pop
            CleverTapLogStaticInternal(@"%@ unarchived data from %@: %@", self, filePath, data);
        }
    }
    @catch (NSException *e) {
        CleverTapLogStaticInternal(@"%@ failed to unarchive data from %@", self, filePath);
    }
    
    [self logUnarchiveError:error filePath:filePath removeFile:remove];
    
    return data;
}

+ (BOOL)archiveObject:(id)object forFileName:(NSString *)filename config: (CleverTapInstanceConfig *)config {
    
    NSString *filePath = [self filePathfromFileName:filename];
    NSError *archiveError = nil;
    NSError *writeError = nil;
    CleverTapLogStaticInternal(@"%@ archiving data to %@: %@", self, filePath, object);
    
    BOOL success = NO;
    
    if (@available(iOS 11.0, tvOS 11.0, *)) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:NO error:&archiveError];
        NSDataWritingOptions fileProtectionOption = config.enableFileProtection ? NSDataWritingFileProtectionComplete : NSDataWritingAtomic;
        success = [data writeToFile:filePath options:fileProtectionOption error:&writeError];
        if (archiveError) {
            CleverTapLogStaticInternal(@"%@ failed to archive data at %@: %@", self, filePath, archiveError);
        }
        if (writeError) {
            CleverTapLogStaticInternal(@"%@ failed to write data at %@: %@", self, filePath, writeError);
        }
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        success = [NSKeyedArchiver archiveRootObject:object toFile:filePath];
#pragma clang diagnostic pop
        if (!success) {
            CleverTapLogStaticInternal(@"%@ failed to archive data to %@: %@", self, filePath, object);
        }
    }
    return success;
}

+ (NSString * _Nonnull)storageKeyWithSuffix: (NSString * _Nonnull)suffix config: (CleverTapInstanceConfig* _Nonnull)config {
    return [NSString stringWithFormat:@"%@:%@", config.accountId, suffix];
}

@end

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

+ (NSString *)getStringForKey:(NSString *)key withResetValue:(NSString *)resetValue {
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

+ (id)unarchiveFromFile:(NSString *)filename removeFile:(BOOL)remove {
    id data = nil;
    
    NSString *filePath = [self filePathfromFileName:filename];
    
    @try {
        data = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        CleverTapLogStaticInternal(@"%@ unarchived data from %@: %@", self, filePath, data);
    }
    @catch (NSException *e) {
        CleverTapLogStaticInternal(@"%@ failed to unarchive data from %@", self, filePath);
    }
    
    if (remove && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError *error;
        BOOL removed = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        
        if (!removed) {
            CleverTapLogStaticInternal(@"%@ unable to remove archived file at %@ - %@", self, filePath, error);
        }
    }
    
    return data;
}

+ (BOOL)archiveObject:(id)object forFileName:(NSString *)filename {
    
    NSString *filePath = [self filePathfromFileName:filename];
    CleverTapLogStaticInternal(@"%@ archiving data to %@: %@", self, filePath, object);
    
    BOOL success = [NSKeyedArchiver archiveRootObject:object toFile:filePath];
    if (!success) {
        CleverTapLogStaticInternal(@"%@ failed to archive data to %@: %@", self, filePath, object);
    }
    
    return success;
}

@end

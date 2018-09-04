#import <Foundation/Foundation.h>

@interface CTPreferences : NSObject

+ (long)getIntForKey:(NSString *)key withResetValue:(long)resetValue;

+ (void)putInt:(long)resetValue forKey:(NSString *)key;

+ (NSString *)getStringForKey:(NSString *)key withResetValue:(NSString *)resetValue;

+ (void)putString:(NSString *)resetValue forKey:(NSString *)key;

+ (id)getObjectForKey:(NSString *)key;

+ (void)putObject:(id)object forKey:(NSString *)key;

+ (void)removeObjectForKey:(NSString *)key;

+ (id)unarchiveFromFile:(NSString *)filePath removeFile:(BOOL)remove;

+ (BOOL)archiveObject:(id)object forFileName:(NSString *)fileName;

@end

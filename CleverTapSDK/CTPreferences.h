#import <Foundation/Foundation.h>
#import "CleverTapInstanceConfig.h"

@interface CTPreferences : NSObject

+ (long)getIntForKey:(NSString *_Nonnull)key withResetValue:(long)resetValue;

+ (void)putInt:(long)resetValue forKey:(NSString *_Nonnull)key;

+ (NSString *_Nullable)getStringForKey:(NSString *_Nonnull)key withResetValue:(NSString *_Nullable)resetValue;

+ (void)putString:(NSString *_Nonnull)resetValue forKey:(NSString *_Nonnull)key;

+ (id _Nonnull)getObjectForKey:(NSString *_Nonnull)key;

+ (void)putObject:(id _Nonnull)object forKey:(NSString *_Nonnull)key;

+ (void)removeObjectForKey:(NSString *_Nonnull)key;

+ (id _Nullable)unarchiveFromFile:(NSString *_Nonnull)filename ofType:(Class _Nonnull)cls  removeFile:(BOOL)remove;

+ (id _Nullable)unarchiveFromFile:(NSString *_Nonnull)filename ofTypes:(nonnull NSSet<Class> *)classes removeFile:(BOOL)remove;

+ (BOOL)archiveObject:(id _Nonnull)object forFileName:(NSString *_Nonnull)fileName config: (CleverTapInstanceConfig *_Nonnull)config;

+ (NSString *_Nonnull)storageKeyWithSuffix: (NSString *_Nonnull)suffix config: (CleverTapInstanceConfig *_Nonnull)config;

+ (NSString *_Nonnull)filePathfromFileName:(NSString *_Nonnull)filename;

@end

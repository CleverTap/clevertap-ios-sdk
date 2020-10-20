#import <Foundation/Foundation.h>

@interface CTEditorSession : NSObject

- (void)setSessionObject:(id _Nullable )object forKey:(NSString* _Nullable)key;
- (id _Nullable)sessionObjectForKey:(NSString* _Nullable)key;

@end


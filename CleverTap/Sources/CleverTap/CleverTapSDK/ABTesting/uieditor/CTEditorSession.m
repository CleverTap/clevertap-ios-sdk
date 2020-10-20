#import "CTEditorSession.h"

@implementation CTEditorSession {
    NSMutableDictionary *_session;
}

- (instancetype)init {
    self = [super init];
    if (self){
        _session = [NSMutableDictionary new];
    }
    return self;
}

- (void)setSessionObject:(id)object forKey:(NSString *)key {
    if (!key) return;
    @synchronized (_session) {
        _session[key] = object ?: [NSNull null];
    }
}

- (id)sessionObjectForKey:(NSString *)key {
    if (!key) return nil;
    @synchronized (_session) {
        id object = _session[key];
        return [object isEqual:[NSNull null]] ? nil : object;
    }
}

@end

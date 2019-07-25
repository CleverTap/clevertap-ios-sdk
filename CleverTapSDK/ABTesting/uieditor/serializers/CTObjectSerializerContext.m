#import "CTObjectSerializerContext.h"

@implementation CTObjectSerializerContext {
    NSMutableSet *_visitedObjects;
    NSMutableSet *_unvisitedObjects;
    NSMutableDictionary *_serializedObjects;
}

- (instancetype)initWithRootObject:(id)object {
    self = [super init];
    if (self) {
        _visitedObjects = [NSMutableSet set];
        _unvisitedObjects = [NSMutableSet setWithObject:object];
        _serializedObjects = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)hasUnvisitedObjects {
    return _unvisitedObjects.count > 0;
}

- (void)enqueueUnvisitedObject:(NSObject *)object {
    if (!object) return;
    [_unvisitedObjects addObject:object];
}

- (NSObject *)dequeueUnvisitedObject {
    NSObject *object = [_unvisitedObjects anyObject];
    [_unvisitedObjects removeObject:object];
    return object;
}

- (void)addVisitedObject:(NSObject *)object {
    if (!object) return;
    [_visitedObjects addObject:object];
}

- (BOOL)isVisitedObject:(NSObject *)object {
    return object && [_visitedObjects containsObject:object];
}

- (void)addSerializedObject:(NSDictionary *)serializedObject {
    if (!serializedObject[@"id"]) return;
    _serializedObjects[serializedObject[@"id"]] = serializedObject;
}

- (NSArray *)allSerializedObjects {
    return _serializedObjects.allValues;
}

@end

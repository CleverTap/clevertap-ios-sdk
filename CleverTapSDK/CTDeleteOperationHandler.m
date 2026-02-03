//
//  CTDeleteOperationHandler.m
//  CleverTapSDK
//
//  Created by Sonal Kachare on 03/02/26.
//

#import "CTDeleteOperationHandler.h"
#import "CTConstants.h"

@interface CTDeleteOperationHandler ()
@property (nonatomic, strong) CTProfileChangeTracker *changeTracker;
@end

@implementation CTDeleteOperationHandler

- (instancetype)initWithChangeTracker:(CTProfileChangeTracker *)changeTracker {
    if (self = [super init]) {
        _changeTracker = changeTracker;
    }
    return self;
}

- (BOOL)handleDelete:(NSMutableDictionary *)target key:(NSString *)key newValue:(id)newValue currentPath:(NSString *)currentPath changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes recursiveMerge:(CTProfileRecursiveBlock)recursiveMerge {
    id oldValue = target[key];
    if (!oldValue) {
        return NO;
    }
    BOOL didModify = NO;
    if ([CTProfileOperationUtils isDeleteMarker:newValue]) {
        // Delete this key entirely
        [self deleteValue:target key:key value:oldValue path:currentPath changes:changes];
        didModify = YES;
    }
    else if ([oldValue isKindOfClass:[NSDictionary class]] && [newValue isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *mutableOldValue;
        if ([oldValue isKindOfClass:[NSMutableDictionary class]]) {
            mutableOldValue = (NSMutableDictionary *)oldValue;
        } else {
            mutableOldValue = [oldValue mutableCopy];
            target[key] = mutableOldValue;  // Replace immutable with mutable
        }
        NSUInteger beforeCount = mutableOldValue.count;
        // Recurse into nested objects for deletion
        recursiveMerge(mutableOldValue, (NSDictionary *)newValue, currentPath, changes);
        // Remove the object if it's now empty
        if (mutableOldValue.count == 0) {
            [target removeObjectForKey:key];
            didModify = YES;
        }
        else if (mutableOldValue.count != beforeCount) {
            didModify = YES;
        }
    }
    else if ([oldValue isKindOfClass:[NSArray class]] && [newValue isKindOfClass:[NSArray class]]) {
        NSMutableArray *mutableOldValue;
        if ([oldValue isKindOfClass:[NSMutableArray class]]) {
            mutableOldValue = (NSMutableArray *)oldValue;
        } else {
            mutableOldValue = [oldValue mutableCopy];
            target[key] = mutableOldValue;  // Replace immutable with mutable
        }
        NSUInteger beforeCount = mutableOldValue.count;
        // Handle array element deletions
        [self handleArrayDeletion:target key:key oldArray:mutableOldValue newArray:(NSArray *)newValue currentPath:currentPath changes:changes];
        if (mutableOldValue.count != beforeCount) {
            didModify = YES;
        }
    }
    return didModify;
}

- (void)handleArrayDeletion:(NSMutableDictionary *)parentJson key:(NSString *)key oldArray:(NSMutableArray *)oldArray newArray:(NSArray *)newArray currentPath:(NSString *)currentPath changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    if ([newArray count] == 0) return;
    BOOL hasDeleteMarkers = [CTArrayMergeUtils hasDeleteMarkerElements:newArray];
    BOOL hasObjectsToDelete = [CTArrayMergeUtils hasJsonObjectElements:newArray];
    if (hasDeleteMarkers) {
        [self deleteArrayElements:parentJson key:key oldArray:oldArray newArray:newArray basePath:currentPath changes:changes];
    }
    else if (hasObjectsToDelete) {
        [self deleteFromArrayElements:oldArray newArray:newArray basePath:currentPath changes:changes];
    } else {
        [self deleteValue:parentJson key:key value:oldArray path:currentPath changes:changes];
    }
}

- (void)deleteFromArrayElements:(NSMutableArray *)oldArray newArray:(NSArray *)newArray basePath:(NSString *)basePath changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    NSArray *oldArrayCopy = [CTArrayMergeUtils copyArray:oldArray];
    BOOL arrayModified = NO;
    NSInteger minLength = MIN(oldArray.count, newArray.count);
    NSMutableArray<NSNumber *> *indicesToRemove = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < minLength; i++) {
        id oldElement = oldArray[i];
        id newElement = newArray[i];
        if (![oldElement isKindOfClass:[NSDictionary class]] || ![oldElement isKindOfClass:[NSDictionary class]] || ![newElement isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSMutableDictionary *oldDict =
        [oldElement isKindOfClass:[NSMutableDictionary class]] ? (NSMutableDictionary *)oldElement : [oldElement mutableCopy];
        NSDictionary *newDict = (NSDictionary *)newElement;
        for (NSString *key in newDict) {
            id value = newDict[key];
            [self handleDelete:oldDict key:key newValue:value currentPath:@"" changes:[NSMutableDictionary dictionary] recursiveMerge:^(NSMutableDictionary * _Nonnull target, NSDictionary * _Nullable source, NSString * _Nonnull path, NSMutableDictionary<NSString *,NSDictionary *> * _Nonnull changes) {
                if (source != nil) {
                    [self handleDeleteRecursive:target source:source];
                }
            }];
        }
        arrayModified = YES;
        // Remove empty dictionaries
        if (oldDict.count == 0) {
            [indicesToRemove addObject:@(i)];
        }
    }
    // Remove in reverse order
    NSArray<NSNumber *> *sortedIndices =
    [indicesToRemove sortedArrayUsingDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO]
    ]];
    
    for (NSNumber *index in sortedIndices) {
        [oldArray removeObjectAtIndex:index.unsignedIntegerValue];
    }
    if (arrayModified) {
        [self.changeTracker recordChange:basePath oldValue:oldArrayCopy newValue:oldArray changes:changes];
    }
}

- (void)handleDeleteRecursive:(NSMutableDictionary *)target source:(NSDictionary *)source {
    for (NSString *key in source) {
        id newValue = source[key];
        [self handleDelete:target key:key newValue:newValue currentPath:@"" changes:[NSMutableDictionary dictionary] recursiveMerge:^(NSMutableDictionary * _Nonnull target, NSDictionary * _Nullable source, NSString * _Nonnull path, NSMutableDictionary<NSString *,NSDictionary *> * _Nonnull changes) {
            [self handleDeleteRecursive:target source:source];
        }];
    }
}

- (void)deleteArrayElements:(NSMutableDictionary *)parentJson key:(NSString *)key oldArray:(NSMutableArray *)oldArray newArray:(NSArray *)newArray basePath:(NSString *)basePath changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    NSMutableArray *indicesToDelete = [NSMutableArray array];
    // Collect indices to delete
    for (NSInteger i = 0; i < [newArray count]; i++) {
        if ([CTProfileOperationUtils isDeleteMarker:newArray[i]] && i < [oldArray count]) {
            [indicesToDelete addObject:@(i)];
        }
    }
    if ([indicesToDelete count] == 0) return;
    NSArray *oldArrayCopy = [CTArrayMergeUtils copyArray:oldArray];
    NSMutableArray *mutableOldArray = [oldArray mutableCopy];
    BOOL removedAny = NO;
    // Sort indices in descending order to maintain correct indices during deletion
    NSArray *sortedIndices = [indicesToDelete sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        return [obj2 compare:obj1]; // Descending order
    }];
    // Delete in reverse order to maintain correct indices
    for (NSNumber *indexNum in sortedIndices) {
        NSInteger index = [indexNum integerValue];
        id oldElement = [oldArray objectAtIndex:index];
        // Check is needed since BE can only delete leaf nodes
        if (![oldElement isKindOfClass:[NSDictionary class]] && ![oldElement isKindOfClass:[NSArray class]]) {
            [mutableOldArray removeObjectAtIndex:index];
            removedAny = YES;
        }
    }
    // Only report changes if we actually removed something
    if (removedAny) {
        [parentJson setObject:mutableOldArray forKey:key];
        NSDictionary *change = @{
            @"oldValue": oldArrayCopy,
            @"newValue": mutableOldArray
        };
        [changes setObject:change forKey:basePath];
        [self.changeTracker recordChange:basePath oldValue:oldArrayCopy newValue:mutableOldArray changes:changes];
    }
}

- (void)deleteValue:(NSMutableDictionary *)parent key:(NSString *)key value:(id)value path:(NSString *)path changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
        CleverTapLogStaticDebug(@"%@: Profile remove operation failed as value is not leaf node: %@",self, value);
        return;
    }
    [parent removeObjectForKey:key];
    [self.changeTracker recordChange:path oldValue:value newValue:[NSNull null] changes:changes];
}
@end

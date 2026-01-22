//
//  CTProfileChangeTracker.m
//  CleverTapSDK
//
//  Created by Sonal Kachare on 16/12/25.
//

#import <Foundation/Foundation.h>
#import "CTProfileChangeTracker.h"
#import "CTLocalDataStore.h"
#import "CTConstants.h"

#pragma mark - Change Tracker Implementation

@implementation CTProfileChangeTracker

- (void)recordChange:(nonnull NSString *)path oldValue:(nonnull id)oldValue newValue:(nonnull id)newValue changes:(nonnull NSMutableDictionary<NSString *,NSDictionary *> *)changes {
    NSDictionary *change = @{
        @"oldValue": [self processValue:oldValue],
        @"newValue": [self processValue:newValue]
    };
    changes[path] = change;
}

- (void)recordAddition:(id)newValue path:(NSString *)path changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    id processedValue = [self processValue:newValue];

    if ([processedValue isKindOfClass:[NSDictionary class]]) {
        [self recordAllLeafAdditions:processedValue basePath:path changes:changes];
    } else {
        NSDictionary *change = @{
            @"oldValue": [NSNull null],
            @"newValue": processedValue ?: [NSNull null]
        };
        changes[path] = change;
    }
}

- (void)recordAllLeafValues:(NSDictionary *)jsonObject
                       path:(NSString *)path
                    changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    for (NSString *key in jsonObject) {
        id value = jsonObject[key];
        NSString *newPath = [path length] > 0 ? [NSString stringWithFormat:@"%@.%@", path, key] : key;
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            [self recordAllLeafValues:(NSDictionary *)value path:newPath changes:changes];
        } else {
            NSDictionary *change = @{
                @"oldValue": [NSNull null],
                @"newValue": [self processValue:value] ?: [NSNull null]
            };
            changes[newPath] = change;
        }
    }
}

- (void)recordAllLeafDeletions:(NSDictionary *)dict basePath:(NSString *)basePath changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    for (NSString *key in dict) {
        id value = dict[key];
        NSString *currentPath = [self buildPathWithBasePath:basePath key:key];

        if ([value isKindOfClass:[NSDictionary class]]) {
            // Recurse into nested object
            [self recordAllLeafDeletions:value basePath:currentPath changes:changes];
        } else {
            // Leaf node → record deletion
            NSDictionary *change = @{
                @"oldValue": [self processValue:value] ?: [NSNull null],
                @"newValue": [NSNull null]
            };
            changes[currentPath] = change;
        }
    }
}

- (void)recordAllLeafAdditions:(NSDictionary *)dict basePath:(NSString *)basePath changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    for (NSString *key in dict) {
        id value = dict[key];
        NSString *currentPath = [self buildPathWithBasePath:basePath key:key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            // Recurse into nested object
            [self recordAllLeafAdditions:value basePath:currentPath changes:changes];
        } else {
            // Leaf node → record addition
            NSDictionary *change = @{
                @"oldValue": [NSNull null],
                @"newValue": [self processValue:value] ?: [NSNull null],
            };
            changes[currentPath] = change;
        }
    }
}

- (id)processValue:(id)value {
    if (value == nil) {
        return nil;
    }
    return [CTProfileOperationUtils processDatePrefixes:value];
}

- (NSString *)buildPathWithBasePath:(NSString *)basePath key:(NSString *)key {
    if (basePath.length == 0) {
        return key;
    } else {
        return [NSString stringWithFormat:@"%@.%@", basePath, key];
    }
}

@end

#pragma mark - Delete Operation Handler Implementation

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
            @"newValue": oldArray
        };
        [changes setObject:change forKey:basePath];
        [self.changeTracker recordChange:basePath oldValue:oldArrayCopy newValue:oldArray changes:changes];
    }
}

- (void)deleteValue:(NSMutableDictionary *)parent key:(NSString *)key value:(id)value path:(NSString *)path changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
        CleverTapLogStaticDebug(@"%@: Profile remove operation failed as value is not leaf node: %@",
                                self, value);
        return;
    }
    [parent removeObjectForKey:key];
    [self.changeTracker recordChange:path oldValue:value newValue:[NSNull null] changes:changes];
}
@end

#pragma mark - Update Operation Handler Implementation

@interface CTUpdateOperationHandler ()
@property (nonatomic, strong) CTProfileChangeTracker *changeTracker;
@property (nonatomic, strong) CTArrayOperationHandler *arrayHandler;
@end

@implementation CTUpdateOperationHandler

- (instancetype)initWithChangeTracker:(CTProfileChangeTracker *)changeTracker arrayHandler:(CTArrayOperationHandler *)arrayHandler {
    if (self = [super init]) {
        _changeTracker = changeTracker;
        _arrayHandler = arrayHandler;
    }
    return self;
}

- (void)handleOperation:(NSMutableDictionary *)target key:(NSString *)key newValue:(id)newValue currentPath:(NSString *)currentPath changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes operation:(CTProfileOperation)operation recursiveApply:(CTProfileRecursiveBlock)recursiveApply {
    
    if (!target[key]) {
        [self handleMissingKey:target key:key newValue:newValue currentPath:currentPath changes:changes operation:operation];
        return;
    }
    id oldValue = target[key];
    // Special handling for GET operation
    if (operation == CTProfileOperationGet) {
        if ([oldValue isKindOfClass:[NSDictionary class]] && [newValue isKindOfClass:[NSDictionary class]]) {
            recursiveApply((NSMutableDictionary *)oldValue, (NSDictionary *)newValue, currentPath, changes);
        }
        else if ([oldValue isKindOfClass:[NSArray class]] && [newValue isKindOfClass:[NSArray class]]) {
            [self.arrayHandler handleArrayOperation:target key:key  oldArray:(NSMutableArray *)oldValue newArray:(NSArray *)newValue currentPath:currentPath changes:changes operation:operation recursiveTraversal:recursiveApply];
        }
        else {
            [self handleGetOperation:oldValue path:currentPath changes:changes];
        }
        return;
    }
    
    // Handle other operations
    if ([oldValue isKindOfClass:[NSDictionary class]] && [newValue isKindOfClass:[NSDictionary class]]) {
        recursiveApply((NSMutableDictionary *)oldValue, (NSDictionary *)newValue, currentPath, changes);
    }
    else if ([oldValue isKindOfClass:[NSArray class]] && [newValue isKindOfClass:[NSArray class]]) {
        [self.arrayHandler handleArrayOperation:target key:key oldArray:(NSMutableArray *)oldValue newArray:(NSArray *)newValue currentPath:currentPath changes:changes operation:operation recursiveTraversal:recursiveApply];
    }
    else if ([oldValue isKindOfClass:[NSNumber class]] && [newValue isKindOfClass:[NSNumber class]] &&
             (operation == CTProfileOperationIncrement || operation == CTProfileOperationDecrement)) {
        [self handleNumberOperation:target key:key oldValue:(NSNumber *)oldValue newValue:(NSNumber *)newValue path:currentPath changes:changes operation:operation];
    }
    else {
        [self handleValueUpdate:target key:key oldValue:oldValue newValue:newValue path:currentPath changes:changes];
    }
}

- (void)handleMissingKey:(NSMutableDictionary *)target key:(NSString *)key newValue:(id)newValue currentPath:(NSString *)currentPath changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes operation:(CTProfileOperation)operation {
    // Skip GET operations on missing keys
    if (operation == CTProfileOperationGet || operation == CTProfileOperationArrayRemove) {
        return;
    }
    id updatedValue;
    
    switch (operation) {
        case CTProfileOperationDecrement: {
            // For missing keys, DECREMENT means 0 - value = -value
            if (![newValue isKindOfClass:[NSNumber class]]) {
                return;
            }
            updatedValue = [CTNumberOperationUtils negateNumber:newValue];
            break;
        }
        case CTProfileOperationIncrement: {
            // For missing keys, INCREMENT means 0 + value = value
            if (![newValue isKindOfClass:[NSNumber class]]) {
                return;
            }
            updatedValue = newValue;
            break;
        }
        default: updatedValue = newValue;
        break;
    }
    target[key] = updatedValue;
    [self.changeTracker recordAddition:newValue path:currentPath changes:changes];
}

- (void)handleNumberOperation:(NSMutableDictionary *)parent key:(NSString *)key oldValue:(NSNumber *)oldValue newValue:(NSNumber *)newValue path:(NSString *)path changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes operation:(CTProfileOperation)operation {
    
    NSNumber *result;
    if (operation == CTProfileOperationIncrement) {
        result = [CTNumberOperationUtils addNumbers:oldValue number:newValue];
    } else if (operation == CTProfileOperationDecrement) {
        result = [CTNumberOperationUtils subtractNumbers:oldValue number:newValue];
    } else {
        result = oldValue;
    }
    if (![CTJsonComparisonUtils areEqual:oldValue value:result]) {
        parent[key] = result;
        [self.changeTracker recordChange:path oldValue:oldValue newValue:newValue changes:changes];
    }
}

- (void)handleValueUpdate:(NSMutableDictionary *)parent key:(NSString *)key oldValue:(id)oldValue newValue:(id)newValue path:(NSString *)path changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    if (![CTJsonComparisonUtils areEqual:oldValue value:newValue]) {
        parent[key] = newValue;
        [self.changeTracker recordChange:path oldValue:oldValue newValue:newValue changes:changes];
    }
}

- (void)handleGetOperation:(id)oldValue path:(NSString *)path changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    NSDictionary *change = @{
        @"oldValue": oldValue ?: [NSNull null],
        @"newValue": kCLTAP_GET_MARKER
    };
    changes[path] = change;
}

@end

#pragma mark - Array Operation Handler Implementation
@interface CTArrayOperationHandler ()
@property (nonatomic, strong) CTProfileChangeTracker *changeTracker;
@end

@implementation CTArrayOperationHandler

- (instancetype)initWithChangeTracker:(CTProfileChangeTracker *)changeTracker {
    if (self = [super init]) {
        _changeTracker = changeTracker;
    }
    return self;
}

- (void)handleArrayOperation:(NSMutableDictionary *)parentJson key:(NSString *)key oldArray:(NSMutableArray *)oldArray newArray:(NSArray *)newArray currentPath:(NSString *)currentPath changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes operation:(CTProfileOperation)operation recursiveTraversal:(CTProfileRecursiveBlock)recursiveTraversal {
    if ([newArray count] == 0) return;
    switch (operation) {
        case CTProfileOperationAdd:
            [self handleArrayAdd:oldArray newArray:newArray path:currentPath changes:changes];
            break;
        case CTProfileOperationArrayRemove:
            [self handleArrayRemove:parentJson key:key oldArray:oldArray newArray:newArray path:currentPath changes:changes];
            break;
        case CTProfileOperationGet:
            [self getArrayElements:oldArray newArray:newArray basePath:currentPath changes:changes recursiveTraversal:recursiveTraversal];
            break;
        case CTProfileOperationUpdate:
        case CTProfileOperationSet:
        case CTProfileOperationIncrement:
        case CTProfileOperationDecrement:
            if ([CTArrayMergeUtils shouldMergeArrayElements:newArray]) {
                [self processArrayElements:oldArray newArray:newArray basePath:currentPath changes:changes operation:operation recursiveTraversal:recursiveTraversal];
            } else {
                [self handleArrayReplacement:parentJson key:key oldArray:oldArray newArray:newArray path:currentPath changes:changes];
            }
            break;
        default:
            break;
    }
}

- (void)handleArrayAdd:(NSMutableArray *)oldArray
              newArray:(NSArray *)newArray
                  path:(NSString *)path
               changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    
    NSArray *oldArrayCopy = [CTArrayMergeUtils copyArray:oldArray];
    BOOL modified = NO;
    for (id item in newArray) {
        if ([item isKindOfClass:[NSString class]]) {
            [oldArray addObject:item];
            modified = YES;
        }
    }
    if (modified) {
        [self.changeTracker recordChange:path
                                oldValue:oldArrayCopy
                                newValue:oldArray
                                 changes:changes];
        
    }
}

- (void)handleArrayRemove:(NSMutableDictionary *)parentJson key:(NSString *)key oldArray:(NSMutableArray *)oldArray newArray:(NSArray *)newArray path:(NSString *)path changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    NSArray *oldArrayCopy = [CTArrayMergeUtils copyArray:oldArray];
    NSMutableArray *resultArray = [NSMutableArray array];
    BOOL modified = NO;
    
    for (id item in oldArray) {
        if ([item isKindOfClass:[NSString class]] &&
            [CTArrayMergeUtils arrayContainsString:newArray string:(NSString *)item]) {
            modified = YES;
        } else {
            [resultArray addObject:item];
        }
    }
    if (modified) {
        parentJson[key] = resultArray;
        [self.changeTracker recordChange:path oldValue:oldArrayCopy newValue:resultArray changes:changes];
    }
}

- (void)handleArrayReplacement:(NSMutableDictionary *)parentJson key:(NSString *)key oldArray:(NSMutableArray *)oldArray newArray:(NSArray *)newArray path:(NSString *)path changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    
    if (![CTJsonComparisonUtils areEqual:oldArray value:newArray]) {
        parentJson[key] = newArray;
        [self.changeTracker recordChange:path oldValue:oldArray newValue:newArray changes:changes];
    }
}

- (void)processArrayElements:(NSMutableArray *)oldArray newArray:(NSArray *)newArray basePath:(NSString *)basePath changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes operation:(CTProfileOperation)operation recursiveTraversal:(CTProfileRecursiveBlock)recursiveTraversal {
    
    NSArray *oldArrayCopy = [CTArrayMergeUtils copyArray:oldArray];
    BOOL arrayModified = NO;
    NSUInteger arrayLength = MIN(oldArray.count, newArray.count);
    
    for (NSUInteger i = 0; i < arrayLength; i++) {
        id oldElement = oldArray[i];
        id newElement = newArray[i];
        
        if ([oldElement isKindOfClass:[NSMutableDictionary class]] &&
            [newElement isKindOfClass:[NSDictionary class]]) {
            
            NSMutableDictionary *oldDict = (NSMutableDictionary *)oldElement;
            NSMutableDictionary *newDict = [(NSDictionary *)newElement mutableCopy];
            
            NSMutableDictionary<NSString *, NSDictionary *> *elementChanges =
            [NSMutableDictionary dictionary];
            
            recursiveTraversal(oldDict, newDict, @"", elementChanges);
            
            if (elementChanges.count > 0) {
                arrayModified = YES;
            }
        } else if ([oldElement isKindOfClass:[NSNumber class]] &&
                   [newElement isKindOfClass:[NSNumber class]]) {
            
            NSNumber *result = [self applyNumberOperation:(NSNumber *)oldElement
                                                 newValue:(NSNumber *)newElement
                                                operation:operation];
            
            if (![CTJsonComparisonUtils areEqual:oldElement value:result]) {
                oldArray[i] = result;
                arrayModified = YES;
            }
        }
    }
    if (arrayModified) {
        [self.changeTracker recordChange:basePath oldValue:oldArrayCopy newValue:oldArray changes:changes];
    }
}

- (BOOL)handleOutOfBoundsIndex:(NSMutableArray *)oldArray newArray:(NSArray *)newArray index:(NSInteger)index operation:(CTProfileOperation)operation {
    if (operation != CTProfileOperationSet) return NO;
    id newElement = newArray[index];
    while ([oldArray count] <= index) {
        [oldArray addObject:[NSNull null]];
    }
    oldArray[index] = newElement;
    return YES;
}

- (NSNumber *)applyNumberOperation:(NSNumber *)oldValue newValue:(NSNumber *)newValue operation:(CTProfileOperation)operation {
    switch (operation) {
        case CTProfileOperationIncrement:
            return [CTNumberOperationUtils addNumbers:oldValue number:newValue];
        case CTProfileOperationDecrement:
            return [CTNumberOperationUtils subtractNumbers:oldValue number:newValue];
        default:
            return oldValue;
    }
}

- (void)getArrayElements:(NSMutableArray *)oldArray newArray:(NSArray *)newArray basePath:(NSString *)basePath changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes recursiveTraversal:(CTProfileRecursiveBlock)recursiveTraversal {
    for (NSInteger i = 0; i < [newArray count]; i++) {
        if (i >= [oldArray count]) {
            continue;
        }
        id oldElement = oldArray[i];
        id newElement = newArray[i];
        NSString *elementPath = [NSString stringWithFormat:@"%@[%ld]", basePath, (long)i];
        
        if ([oldElement isKindOfClass:[NSDictionary class]] &&
            [newElement isKindOfClass:[NSDictionary class]]) {
            
            recursiveTraversal((NSMutableDictionary *)oldElement, (NSDictionary *)newElement, elementPath, changes);
        } else {
            id processedOldValue = [oldElement isKindOfClass:[NSString class]]
            ? [CTProfileOperationUtils processDatePrefixes:(NSString *)oldElement]
            : oldElement;
            NSDictionary *change = @{
                @"oldValue": processedOldValue ?: [NSNull null],
                @"newValue": kCLTAP_GET_MARKER
            };
            changes[elementPath] = change;
        }
    }
}
@end

#pragma mark - Utility Classes Implementation

@implementation CTProfileOperationUtils

+ (BOOL)isDeleteMarker:(id)value {
    if (![value isKindOfClass:[NSString class]]) return NO;
    return [value isEqualToString:kCLTAP_DELETE_MARKER];
}

+ (id)processDatePrefix:(NSString *)value {
    if (![value isKindOfClass:[NSString class]]) return value;
    
    if ([value hasPrefix:CLTAP_DATE_PREFIX]) {
        NSString *numberString = [value substringFromIndex:[CLTAP_DATE_PREFIX length]];
        return @([numberString longLongValue]);
    }
    return value;
}

+ (NSArray *)processArrayDatePrefixes:(NSArray *)array {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:array.count];
    for (id item in array) {
        [result addObject:[self processDatePrefixes:item]];
    }
    return [result copy];
}

+ (NSDictionary *)processObjectDatePrefixes:(NSDictionary *)obj {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:obj.count];
    for (NSString *key in obj) {
        id value = obj[key];
        result[key] = [self processDatePrefixes:value];
    }
    return [result copy];
}

+ (id)processDatePrefixes:(id)value {
    if ([value isKindOfClass:[NSString class]]) {
        return [self processDatePrefix:(NSString *)value];
    }
    else if ([value isKindOfClass:[NSArray class]]) {
        return [self processArrayDatePrefixes:(NSArray *)value];
    }
    else if ([value isKindOfClass:[NSDictionary class]]) {
        return [self processObjectDatePrefixes:(NSDictionary *)value];
    }
    else {
        return value;
    }
}
@end

@implementation CTArrayMergeUtils

+ (NSArray *)copyArray:(NSArray *)array {
    return [[NSArray alloc] initWithArray:array copyItems:YES];
}

+ (BOOL)hasDeleteMarkerElements:(NSArray *)array {
    for (id element in array) {
        if ([CTProfileOperationUtils isDeleteMarker:element]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)hasJsonObjectElements:(NSArray *)array {
    for (id element in array) {
        if ([element isKindOfClass:[NSDictionary class]]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)shouldMergeArrayElements:(NSArray *)array {
    // Check if array contains objects or numbers that should be merged
    for (id element in array) {
        if ([element isKindOfClass:[NSDictionary class]] ||
            [element isKindOfClass:[NSNumber class]]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)arrayContainsString:(NSArray *)array string:(NSString *)string {
    return [array containsObject:string];
}
@end

@implementation CTNumberOperationUtils

+ (nonnull NSNumber *)addNumbers:(nonnull NSNumber *)a number:(nonnull NSNumber *)b {
    const char *aType = [a objCType];
    const char *bType = [b objCType];
    
    // Check if both are integers
    if (strcmp(aType, @encode(int)) == 0 && strcmp(bType, @encode(int)) == 0) {
        return @([a intValue] + [b intValue]);
    }
    // Check if either is long
    else if (strcmp(aType, @encode(long)) == 0 || strcmp(bType, @encode(long)) == 0 ||
             strcmp(aType, @encode(long long)) == 0 || strcmp(bType, @encode(long long)) == 0) {
        return @([a longLongValue] + [b longLongValue]);
    }
    // Check if either is float
    else if (strcmp(aType, @encode(float)) == 0 || strcmp(bType, @encode(float)) == 0) {
        return @([a floatValue] + [b floatValue]);
    }
    // Default to double
    else {
        return @([a doubleValue] + [b doubleValue]);
    }
}

+ (nonnull NSNumber *)subtractNumbers:(nonnull NSNumber *)a number:(nonnull NSNumber *)b {
    const char *aType = [a objCType];
    const char *bType = [b objCType];
    
    // Check if both are integers
    if (strcmp(aType, @encode(int)) == 0 && strcmp(bType, @encode(int)) == 0) {
        return @([a intValue] - [b intValue]);
    }
    // Check if either is long
    else if (strcmp(aType, @encode(long)) == 0 || strcmp(bType, @encode(long)) == 0 ||
             strcmp(aType, @encode(long long)) == 0 || strcmp(bType, @encode(long long)) == 0) {
        return @([a longLongValue] - [b longLongValue]);
    }
    // Check if either is float
    else if (strcmp(aType, @encode(float)) == 0 || strcmp(bType, @encode(float)) == 0) {
        return @([a floatValue] - [b floatValue]);
    }
    // Default to double
    else {
        return @([a doubleValue] - [b doubleValue]);
    }
}

+ (NSNumber *)negateNumber:(NSNumber *)n {
    // Get the underlying type using objCType
    const char *type = [n objCType];
    
    if (strcmp(type, @encode(int)) == 0 ||
        strcmp(type, @encode(NSInteger)) == 0 ||
        strcmp(type, @encode(short)) == 0 ||
        strcmp(type, @encode(char)) == 0) {
        return @(-[n integerValue]);
    }
    else if (strcmp(type, @encode(long)) == 0 ||
             strcmp(type, @encode(long long)) == 0) {
        return @(-[n longLongValue]);
    }
    else if (strcmp(type, @encode(float)) == 0) {
        return @(-[n floatValue]);
    }
    else if (strcmp(type, @encode(double)) == 0) {
        return @(-[n doubleValue]);
    }
    else {
        // Default case: treat as double
        return @(-[n doubleValue]);
    }
}
@end

@implementation CTJsonComparisonUtils

+ (BOOL)areEqual:(id)value1 value:(id)value2 {
    if (value1 == value2) return YES;
    if (!value1 || !value2) return NO;
    if ([value1 isKindOfClass:[NSString class]] && [value2 isKindOfClass:[NSString class]]) {
        return [(NSString *)value1 isEqualToString:(NSString *)value2];
    }
    if ([value1 isKindOfClass:[NSNumber class]] && [value2 isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value1 isEqualToNumber:(NSNumber *)value2];
    }
    if ([value1 isKindOfClass:[NSArray class]] && [value2 isKindOfClass:[NSArray class]]) {
        return [(NSArray *)value1 isEqualToArray:(NSArray *)value2];
    }
    if ([value1 isKindOfClass:[NSDictionary class]] && [value2 isKindOfClass:[NSDictionary class]]) {
        return [(NSDictionary *)value1 isEqualToDictionary:(NSDictionary *)value2];
    }
    return [value1 isEqual:value2];
}
@end

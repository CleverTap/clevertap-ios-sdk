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

static NSString *const kGetMarker = @"__GET_MARKER__";
static NSString *const kDatePrefix = @"$D_";

#pragma mark - Change Tracker Implementation

@implementation CTProfileChangeTracker

- (void)recordDeletion:(id)value
                  path:(NSString *)path
               changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    NSDictionary *change = @{
        @"oldValue": value ?: [NSNull null],
        @"newValue": [NSNull null]
    };
    changes[path] = change;
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
                @"newValue": value ?: [NSNull null]
            };
            changes[newPath] = change;
        }
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
        NSUInteger beforeCount = [(NSDictionary *)oldValue count];
        // Recurse into nested objects for deletion
        recursiveMerge((NSMutableDictionary *)oldValue, (NSDictionary *)newValue, currentPath, changes);
        // Remove the object if it's now empty
        if ([(NSDictionary *)oldValue count] == 0) {
            [target removeObjectForKey:key];
            didModify = YES;
        }
        else if ([(NSDictionary *)oldValue count] != beforeCount) {
            didModify = YES;
        }
    }
    else if ([oldValue isKindOfClass:[NSArray class]] && [newValue isKindOfClass:[NSArray class]]) {
        NSUInteger beforeCount = [(NSArray *)oldValue count];
        // Handle array element deletions
        [self handleArrayDeletion:target key:key oldArray:(NSMutableArray *)oldValue newArray:(NSArray *)newValue currentPath:currentPath changes:changes];
        if ([(NSArray *)oldValue count] != beforeCount) {
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
        [self deleteArrayElements:oldArray newArray:newArray basePath:currentPath changes:changes];
    }
    else if (hasObjectsToDelete) {
        [self deleteFromArrayElements:oldArray newArray:newArray basePath:currentPath changes:changes];
    }
    else {
        [self deleteValue:parentJson key:key value:oldArray path:currentPath changes:changes];
    }
}

- (void)deleteFromArrayElements:(NSMutableArray *)oldArray newArray:(NSArray *)newArray basePath:(NSString *)basePath changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    NSArray *oldArrayCopy = [CTArrayMergeUtils copyArray:oldArray];
    BOOL arrayModified = NO;
    NSInteger minLength = MIN(oldArray.count, newArray.count);
    for (NSInteger i = minLength - 1; i >= 0; i--) {
        id oldElement = oldArray[i];
        id newElement = newArray[i];
        if (![oldElement isKindOfClass:[NSDictionary class]] || ![newElement isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        // Work on a mutable dictionary
        NSMutableDictionary *oldDict =
        [oldElement isKindOfClass:[NSMutableDictionary class]] ? (NSMutableDictionary *)oldElement : [oldElement mutableCopy];
        
        NSDictionary *newDict = (NSDictionary *)newElement;
        CTDeleteOperationHandler *elementHandler =
        [[CTDeleteOperationHandler alloc] initWithChangeTracker:self.changeTracker];
        
        BOOL elementModified = NO;
        for (NSString *key in newDict) {
            id value = newDict[key];
            // Ideally handleDelete should return whether it mutated `oldDict`
            BOOL didDelete =
            [elementHandler handleDelete:oldDict key:key newValue:value currentPath:@"" changes:nil recursiveMerge:^(NSMutableDictionary *target, NSDictionary *source, NSString *path, NSMutableDictionary *localChanges) {
                if (source) {
                    [elementHandler handleDeleteRecursive:target source:source changes:nil];
                }
            }];
            if (didDelete) {
                elementModified = YES;
            }
        }
        if (!elementModified) {
            continue;
        }
        arrayModified = YES;
        // Remove empty dictionaries
        if (oldDict.count == 0) {
            [oldArray removeObjectAtIndex:i];
        } else {
            // Write back the modified dictionary if needed
            oldArray[i] = oldDict;
        }
    }
    if (arrayModified) {
        NSDictionary *change = @{
            @"oldValue": oldArrayCopy,
            @"newValue": oldArray
        };
        changes[basePath] = change;
    }
}

- (void)handleDeleteRecursive:(NSMutableDictionary *)target source:(NSDictionary *)source changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    for (NSString *key in source) {
        id newValue = source[key];
        [self handleDelete:target key:key newValue:newValue currentPath:@"" changes:changes recursiveMerge:^(NSMutableDictionary *t, NSDictionary *s, NSString *p, NSMutableDictionary *c) {
            if (s) {
                [self handleDeleteRecursive:t source:s changes:[NSMutableDictionary new]];
            }
        }];
    }
}

- (void)deleteArrayElements:(NSMutableArray *)oldArray newArray:(NSArray *)newArray basePath:(NSString *)basePath changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    
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
//        [parentJson setObject:mutableOldArray forKey:key];
        NSDictionary *change = @{
            @"oldValue": oldArrayCopy,
            @"newValue": oldArray
        };
        [changes setObject:change forKey:basePath];
    }
    
}

- (void)deleteValue:(NSMutableDictionary *)parent key:(NSString *)key value:(id)value path:(NSString *)path changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    [self.changeTracker recordDeletion:value path:path changes:changes];
    [parent removeObjectForKey:key];
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
    if (operation == CTProfileOperationGet) {
        return;
    }
    target[key] = newValue;
    if ([newValue isKindOfClass:[NSDictionary class]]) {
        [self.changeTracker recordAllLeafValues:(NSDictionary *)newValue path:currentPath changes:changes];
    } else {
        NSDictionary *change = @{
            @"oldValue": [NSNull null],
            @"newValue": newValue ?: [NSNull null]
        };
        changes[currentPath] = change;
    }
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
        NSDictionary *change = @{
            @"oldValue": oldValue,
            @"newValue": result
        };
        changes[path] = change;
    }
}

- (void)handleValueUpdate:(NSMutableDictionary *)parent key:(NSString *)key oldValue:(id)oldValue newValue:(id)newValue path:(NSString *)path changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    
    id processedOldValue = [oldValue isKindOfClass:[NSString class]]
    ? [CTProfileOperationUtils processDatePrefix:(NSString *)oldValue]
    : oldValue;
    
    id processedNewValue = [newValue isKindOfClass:[NSString class]]
    ? [CTProfileOperationUtils processDatePrefix:(NSString *)newValue]
    : newValue;
    
    if (![CTJsonComparisonUtils areEqual:processedOldValue value:processedNewValue]) {
        parent[key] = processedNewValue;
        NSDictionary *change = @{
            @"oldValue": processedOldValue ?: [NSNull null],
            @"newValue": processedNewValue ?: [NSNull null]
        };
        changes[path] = change;
    }
}

- (void)handleGetOperation:(id)oldValue path:(NSString *)path changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    
    id processedOldValue = [oldValue isKindOfClass:[NSString class]]
    ? [CTProfileOperationUtils processDatePrefix:(NSString *)oldValue]
    : oldValue;
    NSDictionary *change = @{
        @"oldValue": processedOldValue ?: [NSNull null],
        @"newValue": kGetMarker
    };
    changes[path] = change;
}

@end

#pragma mark - Array Operation Handler Implementation

@implementation CTArrayOperationHandler

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
            id processedItem = [CTProfileOperationUtils processDatePrefix:(NSString *)item];
            [oldArray addObject:processedItem];
            modified = YES;
        }
    }
    if (modified) {
        NSDictionary *change = @{
            @"oldValue": oldArrayCopy,
            @"newValue": oldArray
        };
        changes[path] = change;
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
        NSDictionary *change = @{
            @"oldValue": oldArrayCopy,
            @"newValue": resultArray
        };
        changes[path] = change;
    }
}

- (void)handleArrayReplacement:(NSMutableDictionary *)parentJson key:(NSString *)key oldArray:(NSMutableArray *)oldArray newArray:(NSArray *)newArray path:(NSString *)path changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes {
    
    if (![CTJsonComparisonUtils areEqual:oldArray value:newArray]) {
        parentJson[key] = newArray;
        NSDictionary *change = @{
            @"oldValue": oldArray,
            @"newValue": newArray
        };
        changes[path] = change;
    }
}

- (void)processArrayElements:(NSMutableArray *)oldArray newArray:(NSArray *)newArray basePath:(NSString *)basePath changes:(NSMutableDictionary<NSString *, NSDictionary *> *)changes operation:(CTProfileOperation)operation recursiveTraversal:(CTProfileRecursiveBlock)recursiveTraversal {
    
    NSArray *oldArrayCopy = [CTArrayMergeUtils copyArray:oldArray];
    BOOL arrayModified = NO;
    
    for (NSInteger i = 0; i < [newArray count]; i++) {
        if (i >= [oldArray count]) {
            arrayModified = [self handleOutOfBoundsIndex:oldArray newArray:newArray index:i operation:operation] || arrayModified;
            continue;
        }
        id oldElement = oldArray[i];
        id newElement = newArray[i];
        if ([oldElement isKindOfClass:[NSDictionary class]] &&
            [newElement isKindOfClass:[NSDictionary class]]) {
            
            NSMutableDictionary *elementChanges = [NSMutableDictionary dictionary];
            recursiveTraversal((NSMutableDictionary *)oldElement, (NSDictionary *)newElement, @"", elementChanges);
            if ([elementChanges count] > 0) {
                arrayModified = YES;
            }
        }
        else if ([oldElement isKindOfClass:[NSNumber class]] &&
                 [newElement isKindOfClass:[NSNumber class]]) {
            
            NSNumber *result = [self applyNumberOperation:(NSNumber *)oldElement
                                                 newValue:(NSNumber *)newElement
                                                operation:operation];
            
            if (![CTJsonComparisonUtils areEqual:oldElement value:result]) {
                oldArray[i] = result;
                arrayModified = YES;
            }
        }
        else if (operation == CTProfileOperationSet &&
                 ![CTJsonComparisonUtils areEqual:oldElement value:newElement]) {
            oldArray[i] = newElement;
            arrayModified = YES;
        }
    }
    
    if (arrayModified) {
        NSDictionary *change = @{
            @"oldValue": oldArrayCopy,
            @"newValue": oldArray
        };
        changes[basePath] = change;
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
        }
        else {
            id processedOldValue = [oldElement isKindOfClass:[NSString class]]
            ? [CTProfileOperationUtils processDatePrefix:(NSString *)oldElement]
            : oldElement;
            
            NSDictionary *change = @{
                @"oldValue": processedOldValue ?: [NSNull null],
                @"newValue": kGetMarker
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
    
    if ([value hasPrefix:kDatePrefix]) {
        NSString *numberString = [value substringFromIndex:[kDatePrefix length]];
        return @([numberString longLongValue]);
    }
    return value;
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

+ (NSNumber *)addNumbers:(NSNumber *)num1 number:(NSNumber *)num2 {
    // Handle integer and floating point
    if (strcmp([num1 objCType], @encode(double)) == 0 ||
        strcmp([num2 objCType], @encode(double)) == 0 ||
        strcmp([num1 objCType], @encode(float)) == 0 ||
        strcmp([num2 objCType], @encode(float)) == 0) {
        return @([num1 doubleValue] + [num2 doubleValue]);
    } else {
        return @([num1 longLongValue] + [num2 longLongValue]);
    }
}

+ (NSNumber *)subtractNumbers:(NSNumber *)num1 number:(NSNumber *)num2 {
    if (strcmp([num1 objCType], @encode(double)) == 0 ||
        strcmp([num2 objCType], @encode(double)) == 0 ||
        strcmp([num1 objCType], @encode(float)) == 0 ||
        strcmp([num2 objCType], @encode(float)) == 0) {
        return @([num1 doubleValue] - [num2 doubleValue]);
    } else {
        return @([num1 longLongValue] - [num2 longLongValue]);
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

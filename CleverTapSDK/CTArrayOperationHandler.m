//
//  CTArrayOperationHandler.m
//  CleverTapSDK
//
//  Created by Sonal Kachare on 03/02/26.
//

#import "CTArrayOperationHandler.h"
#import "CTProfileOperationUtils.h"
#import "CTConstants.h"

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

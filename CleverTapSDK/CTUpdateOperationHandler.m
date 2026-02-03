//
//  CTUpdateOperationHandler.m
//  CleverTapSDK
//
//  Created by Sonal Kachare on 03/02/26.
//

#import "CTUpdateOperationHandler.h"
#import "CTProfileChangeTracker.h"
#import "CTProfileOperationUtils.h"
#import "CTConstants.h"

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
                target[key] = newValue;
                [self.changeTracker recordAddition:newValue path:currentPath changes:changes];
                return;
            }
            updatedValue = [CTNumberOperationUtils negateNumber:newValue];
            break;
        }
        case CTProfileOperationIncrement: {
            // For missing keys, INCREMENT means 0 + value = value
            if (![newValue isKindOfClass:[NSNumber class]]) {
                target[key] = newValue;
                [self.changeTracker recordAddition:newValue path:currentPath changes:changes];
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
        [self.changeTracker recordChange:path oldValue:oldValue newValue:result changes:changes];
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

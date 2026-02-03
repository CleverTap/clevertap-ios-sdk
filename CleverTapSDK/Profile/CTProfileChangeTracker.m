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
#import "CTProfileOperationUtils.h"

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


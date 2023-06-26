//
//  NSDictionary+Extensions.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 5.06.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "NSDictionary+Extensions.h"

@implementation NSDictionary (Extensions)

- (NSString *)toJsonString {
    if (self == nil) return nil;
    
    NSData *jsonData;
    @try {
        NSError *error;
        NSMutableDictionary *_cleaned = [NSMutableDictionary new];
        
        for (NSString *key in self) {
            id value = self[key];
            if ([value isKindOfClass:[NSDate class]]) {
                continue;
            }
            _cleaned[key] = value;
        }
        
        jsonData = [NSJSONSerialization dataWithJSONObject:_cleaned
                                                   options:0
                                                     error:&error];
        
        return jsonData != nil ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : nil;
        
    } @catch (NSException *e) {
        return nil;
    }
}

- (NSDictionary *)dictionaryWithTransformUsingBlock:(id(^)(id))block {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        // If the value is mutable and modified in the block,
        // this will modify the original dictionary value
        id transformedValue = block(value);
        result[key] = transformedValue;
    }];
    
    return [result copy];
}

- (NSDictionary *)dictionaryRemovingNullValues {
    NSSet *keys = [self keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop){
        return obj && ![obj isEqual:[NSNull null]];
    }];
    return [self dictionaryWithValuesForKeys:[keys allObjects]];
}

@end

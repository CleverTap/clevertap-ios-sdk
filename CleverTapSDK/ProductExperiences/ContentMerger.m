//
//  ContentMerger.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 17/02/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "ContentMerger.h"

@implementation ContentMerger

+ (id)mergeWithVars:(id)vars diff:(id)diff {
    
    // Return the modified value if it is a `primitive`
    if ([diff isKindOfClass:[NSString class]]) {
        return ((NSString*)diff);
    }
    if ([diff isKindOfClass:[NSNumber class]]) {
        return ((NSNumber*)diff);
    }
    if ([diff isKindOfClass:[NSNull class]]) {
        return [NSNull null];
    }
    
    if ([vars isKindOfClass:[NSNumber class]] || [vars isKindOfClass:[NSString class]]) {
        return diff;
    }
    
    //TODO: add merging for array types from LP ContentMerger
    
    NSMutableDictionary *merged = [NSMutableDictionary dictionary];
    if ([vars isKindOfClass:[NSDictionary class]]) {
        merged = vars;
    }
    
    if ([diff isKindOfClass:[NSDictionary class]]) {
        NSDictionary *diffDict = (NSDictionary*)diff;
        [diffDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
                    id defaultValue = merged[key] ?: [NSNull null];
                    merged[key] = [self mergeWithVars:defaultValue diff:value];
        }];
        return merged;
    }
    return [NSNull null];
}

@end

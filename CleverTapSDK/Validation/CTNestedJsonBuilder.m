//
//  CTNestedJsonBuilder.m
//  CleverTapSDK
//
//  Created by Sonal Kachare on 20/01/26.
//

#import "CTNestedJsonBuilder.h"
#import "CTConstants.h"

// PathSegment helper class
@interface CTPathSegment : NSObject
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong, nullable) NSNumber *arrayIndex;

- (instancetype)initWithKey:(NSString *)key arrayIndex:(nullable NSNumber *)arrayIndex;
@end

@implementation CTPathSegment

- (instancetype)initWithKey:(NSString *)key arrayIndex:(nullable NSNumber *)arrayIndex {
    self = [super init];
    if (self) {
        _key = key;
        _arrayIndex = arrayIndex;
    }
    return self;
}

@end

@implementation CTNestedJsonBuilder

static NSRegularExpression *arrayIndexPattern;

+ (void)initialize {
    if (self == [CTNestedJsonBuilder class]) {
        NSError *error = nil;
        arrayIndexPattern = [NSRegularExpression regularExpressionWithPattern:@"\\[(\\d+)\\]" options:0 error:&error];
    }
}

- (nullable NSMutableDictionary *)buildFromPath:(NSString *)path value:(nullable id)value {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    BOOL success = [self setValue:result path:path value:value];
    return success ? result : nil;
}

- (BOOL)setValue:(NSMutableDictionary *)root
            path:(NSString *)path
           value:(nullable id)value {
    NSArray<CTPathSegment *> *segments = [self parsePath:path];
    return [self setValueRecursive:root segments:segments index:0 value:value];
}

- (NSArray<CTPathSegment *> *)parsePath:(NSString *)path {
    NSMutableArray<CTPathSegment *> *segments = [NSMutableArray array];
    NSArray<NSString *> *parts = [path componentsSeparatedByString:@"."];
    
    for (NSString *part in parts) {
        // Find all array indices in this part
        NSMutableArray<NSNumber *> *indices = [NSMutableArray array];
        NSArray<NSTextCheckingResult *> *matches = [arrayIndexPattern matchesInString:part options:0 range:NSMakeRange(0, part.length)];
        
        for (NSTextCheckingResult *match in matches) {
            NSRange indexRange = [match rangeAtIndex:1];
            NSString *indexStr = [part substringWithRange:indexRange];
            NSInteger index = [indexStr integerValue];
            [indices addObject:@(index)];
        }
        if (indices.count > 0) {
            // Extract the base key (part before first [)
            NSRange firstBracketRange = [part rangeOfString:@"["];
            NSString *baseKey = [part substringToIndex:firstBracketRange.location];
            
            // Add base key with first index
            CTPathSegment *segment = [[CTPathSegment alloc] initWithKey:baseKey arrayIndex:indices[0]];
            [segments addObject:segment];
            
            // Add remaining indices as empty-key segments
            for (NSUInteger i = 1; i < indices.count; i++) {
                CTPathSegment *indexSegment = [[CTPathSegment alloc] initWithKey:@"" arrayIndex:indices[i]];
                [segments addObject:indexSegment];
            }
        } else {
            // No array indices, just a regular key
            CTPathSegment *segment = [[CTPathSegment alloc] initWithKey:part arrayIndex:nil];
            [segments addObject:segment];
        }
    }
    
    return segments;
}

- (BOOL)setValueRecursive:(id)current segments:(NSArray<CTPathSegment *> *)segments index:(NSInteger)index value:(nullable id)value {
    if (index >= segments.count) {
        return YES;
    }
    
    CTPathSegment *segment = segments[index];
    BOOL isLastSegment = (index == segments.count - 1);
    
    if ([current isKindOfClass:[NSMutableDictionary class]]) {
        NSMutableDictionary *dict = (NSMutableDictionary *)current;
        
        if (segment.arrayIndex != nil) {
            // This segment represents an array
            NSMutableArray *array = dict[segment.key];
            if (!array) {
                array = [NSMutableArray array];
                dict[segment.key] = array;
            }
            // Ensure array has enough space
            [self ensureArraySize:array size:segment.arrayIndex.integerValue + 1];
            
            if (isLastSegment) {
                // Set the value at the array index
                array[segment.arrayIndex.integerValue] = [self convertValue:value];
            } else {
                // Continue navigation
                CTPathSegment *nextSegment = segments[index + 1];
                if (nextSegment.arrayIndex != nil && nextSegment.key.length == 0) {
                    // Next is consecutive array index (matrix case)
                    NSMutableArray *nested = array[segment.arrayIndex.integerValue];
                    if (![nested isKindOfClass:[NSMutableArray class]]) {
                        nested = [NSMutableArray array];
                        array[segment.arrayIndex.integerValue] = nested;
                    }
                    return [self setValueRecursive:nested segments:segments index:index + 1 value:value];
                } else {
                    // Next is an object
                    NSMutableDictionary *nested = array[segment.arrayIndex.integerValue];
                    if (![nested isKindOfClass:[NSMutableDictionary class]]) {
                        nested = [NSMutableDictionary dictionary];
                        array[segment.arrayIndex.integerValue] = nested;
                    }
                    return [self setValueRecursive:nested segments:segments index:index + 1 value:value];
                }
            }
        } else {
            // This segment represents an object key
            if (isLastSegment) {
                dict[segment.key] = [self convertValue:value];
            } else {
                CTPathSegment *nextSegment = segments[index + 1];
                NSMutableDictionary *nested = dict[segment.key];
                
                if (![nested isKindOfClass:[NSMutableDictionary class]]) {
                    nested = [NSMutableDictionary dictionary];
                    dict[segment.key] = nested;
                }
                return [self setValueRecursive:nested
                                      segments:segments
                                         index:index + 1
                                         value:value];
            }
        }
    } else if ([current isKindOfClass:[NSMutableArray class]]) {
        NSMutableArray *array = (NSMutableArray *)current;
        if (segment.arrayIndex == nil) {
            CleverTapLogStaticInternal(@"CTNestedJsonBuilder: Array requires index notation, got key: %@", segment.key);
            return NO;
        }
        [self ensureArraySize:array size:segment.arrayIndex.integerValue + 1];
        if (isLastSegment) {
            array[segment.arrayIndex.integerValue] = [self convertValue:value];
        } else {
            CTPathSegment *nextSegment = segments[index + 1];
            
            if (nextSegment.arrayIndex != nil && nextSegment.key.length == 0) {
                // Next is consecutive array index
                NSMutableArray *nested = array[segment.arrayIndex.integerValue];
                if (![nested isKindOfClass:[NSMutableArray class]]) {
                    nested = [NSMutableArray array];
                    array[segment.arrayIndex.integerValue] = nested;
                }
                return [self setValueRecursive:nested segments:segments index:index + 1 value:value];
            } else {
                // Next is an object
                NSMutableDictionary *nested = array[segment.arrayIndex.integerValue];
                if (![nested isKindOfClass:[NSMutableDictionary class]]) {
                    nested = [NSMutableDictionary dictionary];
                    array[segment.arrayIndex.integerValue] = nested;
                }
                return [self setValueRecursive:nested segments:segments index:index + 1 value:value];
            }
        }
    }
    return YES;
}

- (void)ensureArraySize:(NSMutableArray *)array size:(NSInteger)size {
    while (array.count < size) {
        [array addObject:[NSNull null]];
    }
}

- (id)convertValue:(nullable id)value {
    if (value == nil) {
        return [NSNull null];
    }
    if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)value;
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        for (id key in dict) {
            result[key] = [self convertValue:dict[key]];
        }
        return result;
    }
        if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = (NSArray *)value;
        NSMutableArray *result = [NSMutableArray array];
        for (id item in array) {
            [result addObject:[self convertValue:item]];
        }
        return result;
    }
    return value;
}

@end

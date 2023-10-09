//
//  NSDictionary+Extensions.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 5.06.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (Extensions)

/**
 * Uses NSJSONSerialization. NSDate values will be removed from the result.
 * @return the NSString JSON representation using UTF8 encoding.
 */
- (NSString * _Nullable)toJsonString;

/**
 * Executes the block on each dictionary value and returns a new NSDictionary.
 * Does not deep copy the current dictionary. If the value is mutable and modified in the block,
 * this will modify the current dictionary value.
 * @param block the block to execute on each value.
 * @return new NSDictionary with the transformed values.
 */
- (NSDictionary *)dictionaryWithTransformUsingBlock:(id(^)(id))block;

/**
 * Removes `NSNull` values and returns a new dictionary. Current dictionary is unmodified.
 * @return new NSDictionary without `NSNull` values.
 */
- (NSDictionary *)dictionaryRemovingNullValues;

@end

NS_ASSUME_NONNULL_END

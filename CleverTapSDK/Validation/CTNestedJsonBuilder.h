//
//  CTNestedJsonBuilder.h
//  CleverTapSDK
//
//  Created by Sonal Kachare on 20/01/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTNestedJsonBuilder : NSObject

/**
 * Builds an NSDictionary from a dot notation path and value.
 *
 * Examples:
 * - "name" -> {"name": value}
 * - "user.age" -> {"user": {"age": value}}
 * - "items[0]" -> {"items": [value]}
 * - "users[0].name" -> {"users": [{"name": value}]}
 * - "profile.scores[2]" -> {"profile": {"scores": [null, null, value]}}
 * - "matrix[0][1]" -> {"matrix": [[null, value]]}
 * - "cube[1][2][3]" -> {"cube": [null, [null, null, [null, null, null, value]]]}
 *
 * @param path dot notation path (e.g., "user.profile.age" or "items[0].name" or "matrix[0][1]")
 * @param value value to set at the path
 * @return NSMutableDictionary with the nested structure, or nil if error occurs
 */
- (nullable NSMutableDictionary *)buildFromPath:(NSString *)path value:(nullable id)value;

@end

NS_ASSUME_NONNULL_END

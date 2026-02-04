//
//  CTDataFlattener.h
//  CleverTapSDK
//
//  Created by Sonal Kachare on 21/01/26.
//  Copyright © 2026 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CTDataFlattener : NSObject

/**
 * Flattens a nested NSDictionary into a single-level NSDictionary with dot-notation keys
 * @param json The NSDictionary to flatten
 * @return Flattened dictionary with dot-notation keys
 */
+ (NSDictionary<NSString *, id> *)flatten:(NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END

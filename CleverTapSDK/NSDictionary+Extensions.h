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

- (NSString *)toJsonString;
- (NSDictionary *)dictionaryWithTransformUsingBlock:(id(^)(id))block;
- (NSDictionary *)dictionaryWithRemoveNullValues;

@end

NS_ASSUME_NONNULL_END

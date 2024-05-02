//
//  CTInAppTemplateBuilder.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTCustomTemplateBuilder.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTInAppTemplateBuilder : CTCustomTemplateBuilder

- (instancetype)init;
- (void)addArgument:(nonnull NSString *)name withDictionary:(nonnull NSDictionary *)defaultValue
NS_SWIFT_NAME(addArgument(_:dictionary:));
- (void)addActionArgument:(NSString *)name;

@end

NS_ASSUME_NONNULL_END

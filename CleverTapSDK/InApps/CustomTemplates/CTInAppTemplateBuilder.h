//
//  CTInAppTemplateBuilder.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTAppFunctionBuilder.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTInAppTemplateBuilder : CTAppFunctionBuilder

- (void)addArgument:(NSString *)name withDictionary:(NSDictionary *)defaultValue;
- (void)addActionArgument:(NSString *)name;

@end

NS_ASSUME_NONNULL_END

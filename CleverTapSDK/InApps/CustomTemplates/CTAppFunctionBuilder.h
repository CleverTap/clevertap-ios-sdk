//
//  CTAppFunctionBuilder.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTCustomTemplateBuilder.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTAppFunctionBuilder : CTCustomTemplateBuilder

- (instancetype)initWithIsVisual:(BOOL)isVisual;

@end

NS_ASSUME_NONNULL_END

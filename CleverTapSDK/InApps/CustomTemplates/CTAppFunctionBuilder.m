//
//  CTAppFunctionBuilder.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTAppFunctionBuilder.h"
#import "CTTemplateArgument.h"
#import "CTCustomTemplateBuilder-Internal.h"
#import "CTCustomTemplate-Internal.h"

@implementation CTAppFunctionBuilder

- (nonnull instancetype)initWithIsVisual:(BOOL)isVisual {
    return [self initWithIsVisual:isVisual isSystemDefined:NO];
}

- (nonnull instancetype)initWithIsVisual:(BOOL)isVisual
                         isSystemDefined:(BOOL)isSystemDefined {
    return [super initWithType:FUNCTION_TYPE isVisual:isVisual isSystemDefined:isSystemDefined];
}

@end

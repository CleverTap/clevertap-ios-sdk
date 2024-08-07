//
//  CTInAppTemplateBuilder.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTInAppTemplateBuilder.h"
#import "CTCustomTemplateBuilder-Internal.h"

@implementation CTInAppTemplateBuilder

- (instancetype)init {
    NSSet *nullableTypes = [NSSet setWithObjects:@(CTTemplateArgumentTypeAction), nil];
    self = [super initWithType:TEMPLATE_TYPE isVisual:YES nullableArgumentTypes:nullableTypes];
    return self;
}

- (void)addActionArgument:(nonnull NSString *)name {
    [self addArgumentWithName:name type:CTTemplateArgumentTypeAction defaultValue:nil];
}

@end

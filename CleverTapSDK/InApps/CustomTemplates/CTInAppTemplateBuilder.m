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
    self = [super initWithType:TEMPLATE_TYPE isVisual:YES allowHierarchicalNames:YES nullableArgumentTypes:nullableTypes];
    return self;
}

- (void)addActionArgument:(nonnull NSString *)name {
    [self addArgumentWithName:name type:CTTemplateArgumentTypeAction defaultValue:nil];
}

- (void)addArgument:(nonnull NSString *)name withDictionary:(nonnull NSDictionary *)defaultValue {
    if (defaultValue == nil || [defaultValue count] == 0) {
        @throw([NSException
                exceptionWithName:@"CleverTap Error"
                reason:[NSString stringWithFormat:@"CleverTap: Default value cannot be nil or empty."]
                userInfo:nil]);
    }
    
    [self flatten:defaultValue name:name];
}

- (void)flatten:(NSDictionary *)map name:(NSString *)name {
    [map enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
        NSString *argName = [NSString stringWithFormat:@"%@.%@", name, key];
        if ([value isKindOfClass:[NSString class]]) {
            [self addArgument:argName withString:value];
        } else if ([value isKindOfClass:[NSNumber class]]) {
            [self addArgument:argName withNumber:value];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            [self flatten:value name:argName];
        }
    }];
}

@end

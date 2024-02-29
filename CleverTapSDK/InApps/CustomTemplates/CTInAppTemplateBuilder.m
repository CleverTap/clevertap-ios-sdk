//
//  CTInAppTemplateBuilder.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTInAppTemplateBuilder.h"
#import "CTAppFunctionBuilder-Internal.h"

@implementation CTInAppTemplateBuilder

- (instancetype)init {
    self = [super init];
    if (self) {
        self.templateType = @"template";
    }
    return self;
}

- (void)addActionArgument:(nonnull NSString *)name {
    [self addArgumentWithName:name type:@"action" defaultValue:nil];
}

- (void)addArgument:(nonnull NSString *)name withDictionary:(nonnull NSDictionary *)defaultValue {
    [self addArgumentWithName:name type:@"group" defaultValue:defaultValue];
}

@end

//
//  CTAppFunctionBuilder.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTAppFunctionBuilder.h"
#import "CTAppFunctionBuilder-Internal.h"
#import "CTTemplateArgument.h"
#import "CTCustomTemplate-Internal.h"

@implementation CTAppFunctionBuilder

- (instancetype)init {
    self = [super init];
    if (self) {
        _argumentNames = [NSMutableSet set];
        _fileArgumentNames = [NSMutableSet set];
        _arguments = [NSMutableArray new];
        _templateType = @"function";
    }
    return self;
}

- (void)addArgumentWithName:(NSString *)name type:(NSString *)type defaultValue:(id)defaultValue {
    if (!name || [name isEqualToString:@""]) {
        @throw([NSException
                exceptionWithName:@"CleverTap Error"
                reason:[NSString stringWithFormat:@"CleverTap: Argument Name cannot be null or empty."]
                userInfo:nil]);
    }
    
    if ([name hasPrefix:@"."] || [name hasSuffix:@"."]) {
        @throw([NSException
                exceptionWithName:@"CleverTap Error"
                reason:[NSString stringWithFormat:@"CleverTap: Argument Name cannot start or end with dot \".\" ."]
                userInfo:nil]);
    }
    
    // Validate name, object, and other conditions
    if ([self.argumentNames containsObject:name]) {
        @throw([NSException
                exceptionWithName:@"CleverTap Error"
                reason:[NSString stringWithFormat:@"CleverTap: Argument with the same name already defined."]
                userInfo:nil]);
    }
    
    [self.argumentNames addObject:name];
    if ([type isEqualToString:@"file"]) {
        [self.fileArgumentNames addObject:name];
    }
    
    CTTemplateArgument *arg = [[CTTemplateArgument alloc] initWithName:name type:type defaultValue:defaultValue];
    [self.arguments addObject:arg];
}

- (void)addArgument:(NSString *)name withBool:(BOOL)defaultValue {
    [self addArgumentWithName:name type:@"boolean" defaultValue:[NSNumber numberWithBool:defaultValue]];
}

- (void)addArgument:(NSString *)name withString:(NSString *)defaultValue {
    [self addArgumentWithName:name type:@"string" defaultValue:defaultValue];
}

- (void)addArgument:(NSString *)name withNumber:(nonnull NSNumber *)defaultValue {
    [self addArgumentWithName:name type:@"number" defaultValue:defaultValue];
}

- (void)addFileArgument:(NSString *)name {
    [self addArgumentWithName:name type:@"file" defaultValue:nil];
}

- (void)setName:(NSString *)name {
    _name = name;
}

- (void)setOnPresentWithPresenter:(id<CTTemplatePresenter>)presenter {
    self.presenter = presenter;
}

- (CTCustomTemplate *)build {
    if (!self.name || [self.name isEqualToString:@""]) {
        @throw([NSException
                exceptionWithName:@"CleverTap Error"
                reason:[NSString stringWithFormat:@"CleverTap: Name cannot be null or empty. Use setName to set it."]
                userInfo:nil]);
    }
    
    if ([self.name hasPrefix:@"."] || [self.name hasSuffix:@"."]) {
        @throw([NSException
                exceptionWithName:@"CleverTap Error"
                reason:[NSString stringWithFormat:@"CleverTap: Name cannot start or end with dot \".\" ."]
                userInfo:nil]);
    }
    
    if (!self.presenter) {
        @throw([NSException
                exceptionWithName:@"CleverTap Error"
                reason:[NSString stringWithFormat:@"CleverTap: Presenter cannot be null. Use setOnPresentWithPresenter to set it."]
                userInfo:nil]);
    }

    return [[CTCustomTemplate alloc] initWithTemplateName:self.name
                                             templateType:self.templateType
                                                arguments:self.arguments presenter:self.presenter fileArgumentNames:self.fileArgumentNames];
}

@end

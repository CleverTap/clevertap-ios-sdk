//
//  CTCustomTemplateBuilder.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 6.03.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTCustomTemplateBuilder.h"
#import "CTCustomTemplateBuilder-Internal.h"
#import "CTCustomTemplate-Internal.h"
#import "CTTemplatePresenter.h"

@implementation CTCustomTemplateBuilder

- (instancetype)initWithType:(nonnull NSString *)type isVisual:(BOOL)isVisual allowHierarchicalNames:(BOOL)allowHierarchicalNames {
    return [self initWithType:type isVisual:isVisual allowHierarchicalNames:allowHierarchicalNames nullableArgumentTypes:[NSSet setWithObject:@(CTTemplateArgumentTypeFile)]];
}

- (instancetype)initWithType:(nonnull NSString *)type isVisual:(BOOL)isVisual allowHierarchicalNames:(BOOL)allowHierarchicalNames nullableArgumentTypes:(NSSet *)nullableArgumentTypes {
    self = [super init];
    if (self) {
        _templateType = [type copy];
        _isVisual = isVisual;
        _allowHierarchicalNames = allowHierarchicalNames;
        
        _nullableArgumentTypes = [NSSet setWithObject:@(CTTemplateArgumentTypeFile)];
        if (nullableArgumentTypes && [nullableArgumentTypes count] > 0) {
            _nullableArgumentTypes = [_nullableArgumentTypes setByAddingObjectsFromSet:nullableArgumentTypes];
        }
        _argumentNames = [NSMutableSet set];
        _parentArgumentNames = [NSMutableSet set];
        _arguments = [NSMutableArray array];
    }
    return self;
}

- (void)addArgumentWithName:(NSString *)name type:(CTTemplateArgumentType)type defaultValue:(id)defaultValue {
    NSAssert(![defaultValue isKindOfClass:[NSDictionary class]], @"Argument 'defaultValue' cannot be of type NSDictionary.");

    if (!name || [name isEqualToString:@""]) {
        @throw([NSException
                exceptionWithName:@"CleverTap Error"
                reason:@"CleverTap: Argument Name cannot be null or empty."
                userInfo:nil]);
    }
    
    if ([name hasPrefix:@"."] || [name hasSuffix:@"."] || [name containsString:@".."]) {
        @throw([NSException
                exceptionWithName:@"CleverTap Error"
                reason:@"CleverTap: Argument Name cannot start or end with dot \".\" or contain consecutive dots \"..\"."
                userInfo:nil]);
    }
    
    if (!self.allowHierarchicalNames && [name containsString:@"."]) {
        @throw([NSException
                exceptionWithName:@"CleverTap Error"
                reason:@"CleverTap: Argument Name cannot contain a dot \".\" ."
                userInfo:nil]);
    }
    
    if ([self.argumentNames containsObject:name]) {
        @throw([NSException
                exceptionWithName:@"CleverTap Error"
                reason:[NSString stringWithFormat:@"CleverTap: Argument with the name \"%@\" already defined.", name]
                userInfo:nil]);
    }

    if (![self.nullableArgumentTypes containsObject:@(type)] &&
        (defaultValue == nil || [defaultValue isEqual:[NSNull null]])) {
        @throw([NSException
                exceptionWithName:@"CleverTap Error"
                reason:[NSString stringWithFormat:@"CleverTap: Default value cannot be nil."]
                userInfo:nil]);
    }
    
    if (self.allowHierarchicalNames) {
        [self validateParentNames:name];
    }

    CTTemplateArgument *arg = [[CTTemplateArgument alloc] initWithName:name type:type defaultValue:defaultValue];
    [self.arguments addObject:arg];
    [self.argumentNames addObject:name];
}

- (void)validateParentNames:(NSString *)name {
    NSArray *nameComponents = [name componentsSeparatedByString:@"."];

    NSMutableString *parentName = [NSMutableString string];
    for (int i = 0; i < nameComponents.count - 1; i++) {
        if (i > 0) {
            [parentName appendString:@"."];
        }
        NSString *component = nameComponents[i];
        [parentName appendString:component];
        
        if ([self.argumentNames containsObject:parentName]) {
            @throw([NSException
                    exceptionWithName:@"CleverTap Error"
                    reason:[NSString stringWithFormat:@"CleverTap: Argument with the name \"%@\" already defined.", parentName]
                    userInfo:nil]);
        }
        [self.parentArgumentNames addObject:[parentName copy]];
    }
    
    if ([self.parentArgumentNames containsObject:name]) {
        @throw([NSException
                exceptionWithName:@"CleverTap Error"
                reason:[NSString stringWithFormat:@"CleverTap: Argument with the name \"%@\" already defined.", name]
                userInfo:nil]);
    }
}

- (void)addArgument:(NSString *)name withBool:(BOOL)defaultValue {
    [self addArgumentWithName:name type:CTTemplateArgumentTypeBool defaultValue:[NSNumber numberWithBool:defaultValue]];
}

- (void)addArgument:(NSString *)name withString:(NSString *)defaultValue {
    [self addArgumentWithName:name type:CTTemplateArgumentTypeString defaultValue:defaultValue];
}

- (void)addArgument:(NSString *)name withNumber:(NSNumber *)defaultValue {
    [self addArgumentWithName:name type:CTTemplateArgumentTypeNumber defaultValue:defaultValue];
}

- (void)addFileArgument:(NSString *)name {
    [self addArgumentWithName:name type:CTTemplateArgumentTypeFile defaultValue:nil];
}

- (void)setName:(NSString *)name {
    if (_name) {
            @throw([NSException
                    exceptionWithName:@"CleverTap Error"
                    reason:@"CleverTap: Name is already set."
                    userInfo:nil]);
    }
    
    if (name == nil || [name isEqualToString:@""]) {
            @throw([NSException
                    exceptionWithName:@"CleverTap Error"
                    reason:@"CleverTap: Name cannot be null or empty."
                    userInfo:nil]);
    }
    
    _name = name;
}

- (void)setPresenter:(id<CTTemplatePresenter>)presenter {
    _presenter = presenter;
}

- (CTCustomTemplate *)build {
    if (!self.name || [self.name isEqualToString:@""]) {
        @throw([NSException
                exceptionWithName:@"CleverTap Error"
                reason:[NSString stringWithFormat:@"CleverTap: Name cannot be null or empty. Use setName to set it."]
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
                                                 isVisual:self.isVisual
                                                arguments:self.arguments
                                                presenter:self.presenter];
}

@end

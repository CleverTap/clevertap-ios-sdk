//
//  CTJsonTemplateProducer.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 13.09.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTJsonTemplateProducer.h"
#import "CTCustomTemplateBuilder.h"
#import "CTInAppTemplateBuilder.h"
#import "CTAppFunctionBuilder.h"
#import "CTTemplateArgument.h"
#import "CTConstants.h"

@interface CTJsonTemplateProducer ()

@property (nonatomic, strong) NSString *jsonTemplatesDefinition;
@property (nonatomic, strong) id<CTTemplatePresenter> templatePresenter;
@property (nonatomic, strong) id<CTTemplatePresenter> functionPresenter;

@end

@implementation CTJsonTemplateProducer

- (nonnull instancetype)initWithJson:(nonnull NSString *)jsonTemplatesDefinition
                                      templatePresenter:(nonnull id<CTTemplatePresenter>)templatePresenter
                                      functionPresenter:(nonnull id<CTTemplatePresenter>)functionPresenter {
    if (self = [super init]) {
        self.jsonTemplatesDefinition = jsonTemplatesDefinition;
        self.templatePresenter = templatePresenter;
        self.functionPresenter = functionPresenter;
    }
    return self;
}

- (NSSet<CTCustomTemplate *> * _Nonnull)defineTemplates:(CleverTapInstanceConfig * _Nonnull)instanceConfig {
    if (!self.jsonTemplatesDefinition || [self.jsonTemplatesDefinition length] == 0) {
        @throw([NSException
                exceptionWithName:CLTAP_CUSTOM_TEMPLATE_EXCEPTION
                reason:@"CleverTap: JSON template definitions cannot be nil or empty."
                userInfo:nil]);
    }
    
    NSData *jsonData = [self.jsonTemplatesDefinition dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *jsonDefinitions = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if (error) {
        @throw([NSException
                exceptionWithName:CLTAP_CUSTOM_TEMPLATE_EXCEPTION
                reason:[NSString stringWithFormat:@"CleverTap: Error parsing JSON template definitions: %@.", error.localizedDescription]
                userInfo:nil]);
    }
    
    NSMutableSet *templates = [NSMutableSet set];
    for (NSString *key in jsonDefinitions) {
        NSDictionary *item = jsonDefinitions[key];
        NSString *type = item[@"type"];
        NSDictionary *arguments = item[@"arguments"];
        
        CTCustomTemplateBuilder *builder;
        if ([type isEqualToString:TEMPLATE_TYPE]) {
            if (!self.templatePresenter) {
                @throw([NSException
                        exceptionWithName:CLTAP_CUSTOM_TEMPLATE_EXCEPTION
                        reason:@"CleverTap: JSON definition contains a template definition and a template presenter is required."
                        userInfo:nil]);
            }
            
            builder = [CTInAppTemplateBuilder new];
            [builder setPresenter:self.templatePresenter];
        } else if ([type isEqualToString:FUNCTION_TYPE]) {
            if (!self.functionPresenter) {
                @throw([NSException
                        exceptionWithName:CLTAP_CUSTOM_TEMPLATE_EXCEPTION
                        reason:@"CleverTap: JSON definition contains a function definition and a function presenter is required."
                        userInfo:nil]);
            }
            
            BOOL isVisual = NO;
            if (item[@"isVisual"]) {
                isVisual = [item[@"isVisual"] boolValue];
            }
            builder = [[CTAppFunctionBuilder alloc] initWithIsVisual:isVisual];
            [builder setPresenter:self.functionPresenter];
        } else {
            @throw([NSException
                    exceptionWithName:CLTAP_CUSTOM_TEMPLATE_EXCEPTION
                    reason:[NSString stringWithFormat:@"Unknown template type: %@ for template: %@.", type, key]
                    userInfo:nil]);
        }
        [builder setName:key];
        
        [self addJsonArguments:arguments toBuilder:builder];
        
        CTCustomTemplate *customTemplate = [builder build];
        [templates addObject:customTemplate];
    }
    return templates;
}

- (void)addJsonArguments:(NSDictionary *)arguments toBuilder:(CTCustomTemplateBuilder *)builder {
    for (NSString *argKey in arguments) {
        NSDictionary *arg = arguments[argKey];
        NSString *argType = arg[@"type"];
        id value = arg[@"value"];
        
        if ([argType isEqualToString:@"object"]) {
            NSDictionary *dictValue = [self objectArgumentJsonToDictionary:value];
            [builder addArgument:argKey withDictionary:dictValue];
            continue;
        }
        
        if ([argType isEqualToString:[CTTemplateArgument templateArgumentTypeToString:CTTemplateArgumentTypeString]]) {
            NSString *stringValue = value;
            [builder addArgument:argKey withString:stringValue];
        } else if ([argType isEqualToString:[CTTemplateArgument templateArgumentTypeToString:CTTemplateArgumentTypeNumber]]) {
            NSNumber *numberValue = value;
            [builder addArgument:argKey withNumber:numberValue];
        } else if ([argType isEqualToString:[CTTemplateArgument templateArgumentTypeToString:CTTemplateArgumentTypeBool]]) {
            BOOL boolValue = [value boolValue];
            [builder addArgument:argKey withBool:boolValue];
        } else if ([argType isEqualToString:[CTTemplateArgument templateArgumentTypeToString:CTTemplateArgumentTypeFile]]) {
            if (value) {
                @throw([NSException
                        exceptionWithName:CLTAP_CUSTOM_TEMPLATE_EXCEPTION
                        reason:[NSString stringWithFormat:@"CleverTap: File arguments should not specify a value. Remove value from argument: %@.", argKey]
                        userInfo:nil]);
            }
            [builder addFileArgument:argKey];
        } else if ([argType isEqualToString:[CTTemplateArgument templateArgumentTypeToString:CTTemplateArgumentTypeAction]]) {
            if (value) {
                @throw([NSException
                        exceptionWithName:CLTAP_CUSTOM_TEMPLATE_EXCEPTION
                        reason:[NSString stringWithFormat:@"CleverTap: Action arguments should not specify a value. Remove value from argument: %@.", argKey]
                        userInfo:nil]);
            }
            
            if (![builder isKindOfClass:CTInAppTemplateBuilder.class]) {
                @throw([NSException
                        exceptionWithName:CLTAP_CUSTOM_TEMPLATE_EXCEPTION
                        reason:[NSString stringWithFormat:@"Function templates cannot have action arguments. Remove argument: %@.", argKey]
                        userInfo:nil]);
            }
            [(CTInAppTemplateBuilder *)builder addActionArgument:argKey];
        } else {
            @throw([NSException
                    exceptionWithName:CLTAP_CUSTOM_TEMPLATE_EXCEPTION
                    reason:[NSString stringWithFormat:@"Unknown argument type: %@ for argument: %@.", argType, argKey]
                    userInfo:nil]);
        }
    }
}

- (NSDictionary *)objectArgumentJsonToDictionary:(NSDictionary *)objectArgumentJson {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    NSSet *supportedNestedTypes = [NSSet setWithArray:@[
        [CTTemplateArgument templateArgumentTypeToString:CTTemplateArgumentTypeBool],
        [CTTemplateArgument templateArgumentTypeToString:CTTemplateArgumentTypeString],
        [CTTemplateArgument templateArgumentTypeToString:CTTemplateArgumentTypeNumber]
    ]];
                                   
    for (id argName in objectArgumentJson) {
        NSDictionary *argJson = objectArgumentJson[argName];
        NSString *argType = argJson[@"type"];
        if ([argType isEqualToString:@"object"]) {
            NSDictionary *value = argJson[@"value"];
            dictionary[argName] = [self objectArgumentJsonToDictionary:value];
            continue;
        }
        
        if (![supportedNestedTypes containsObject:argType]) {
            NSString *reason =
            [NSString stringWithFormat:@"CleverTap: Not supported argument type: %@, for argument: %@. %@. %@",
             argType,
             argName,
             @"Nesting of file and action arguments within objects is not supported",
             @"To define nested file and actions use dot '.' notation in the argument name"];
            @throw([NSException
                    exceptionWithName:CLTAP_CUSTOM_TEMPLATE_EXCEPTION
                    reason:reason
                    userInfo:nil]);
        }
        
        dictionary[argName] = argJson[@"value"];
    }
    return dictionary;
}

@end

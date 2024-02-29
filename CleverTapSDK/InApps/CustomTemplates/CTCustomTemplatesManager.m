//
//  CTCustomTemplatesManager.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 28.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTCustomTemplatesManager.h"
#import "CTCustomTemplate-Internal.h"
#import "CTTemplateArgument.h"
#import "CTConstants.h"

@interface CTCustomTemplatesManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, CTCustomTemplate *> *templates;

@end

@implementation CTCustomTemplatesManager

static NSMutableArray<id<CTTemplateProducer>> *templateProducers;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        templateProducers = [NSMutableArray array];
    });
}

+ (void)registerTemplateProducer:(nonnull id<CTTemplateProducer>)producer {
    [templateProducers addObject:producer];
}

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)instanceConfig {
    self = [super init];
    if (self) {
        self.templates = [NSMutableDictionary dictionary];
        for (id producer in templateProducers) {
            NSSet *customTemplates = [producer defineTemplates:instanceConfig];
            for (CTCustomTemplate *template in customTemplates) {
                if (!self.templates[template.name]) {
                    self.templates[template.name] = template;
                } else {
                    CleverTapLogInfo(instanceConfig.logLevel, @"%@: Template with name: %@ is already defined.", self, template.name);
                }
            }
        }
    }
    return self;
}

- (void)sync {
    
}

- (NSDictionary*)syncPayload {
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    payload[@"type"] = @"templatePayload";
    
    NSMutableDictionary *definitions = [NSMutableDictionary dictionary];
    [self.templates enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString * _Nonnull key, CTCustomTemplate * _Nonnull template, BOOL * _Nonnull stop) {
        NSMutableDictionary *templateData = [NSMutableDictionary dictionary];
        templateData[@"type"] = template.templateType;
        
        // Flatten all arguments
        NSMutableDictionary *varsData = [NSMutableDictionary dictionary];
        for (CTTemplateArgument *arg in template.arguments) {
            NSMutableDictionary *varData = [NSMutableDictionary dictionary];
            if ([arg.type isEqualToString:CT_KIND_DICTIONARY]) {
                NSDictionary *flattenedMap = [self flatten:arg.defaultValue varName:arg.name];
                [varsData addEntriesFromDictionary:flattenedMap];
            }
            else {
                if ([arg.type isEqualToString:CT_KIND_INT] || [arg.type isEqualToString:CT_KIND_FLOAT]) {
                    varData[CT_PE_VAR_TYPE] = CT_PE_NUMBER_TYPE;
                }
                else if ([arg.type isEqualToString:CT_KIND_BOOLEAN]) {
                    varData[CT_PE_VAR_TYPE] = CT_PE_BOOL_TYPE;
                }
                else {
                    varData[CT_PE_VAR_TYPE] = arg.type;
                }
                varData[CT_PE_DEFAULT_VALUE] = arg.defaultValue;
                varsData[arg.name] = varData;
            }
        }

        // Sort the argument names alphabetically
        NSArray *sortedKeys = [varsData.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        // Set the order of each argument
        NSMutableSet *ordered = [NSMutableSet set];
        int order = 0;
        for (CTTemplateArgument *arg in template.arguments) {
            if ([arg.type isEqualToString:CT_KIND_DICTIONARY]) {
                NSString *prefix = [NSString stringWithFormat:@"%@.", arg.name];
                [ordered addObject:prefix];
                for (NSString *key in sortedKeys) {
                    if ([key hasPrefix:prefix]) {
                        // Ensure the dictionary is mutable
                        if (![varsData[key] isKindOfClass:[NSMutableDictionary class]]) {
                            varsData[key] = [NSMutableDictionary dictionaryWithDictionary:varsData[key]];
                        }
                        // Set the order of the argument
                        varsData[key][@"order"] = @(order);
                        order++;
                    }
                }
            } else if (![arg.name containsString:@"."]) {
                varsData[arg.name][@"order"] = @(order);
                order++;
            }
        }
        
        templateData[@"vars"] = varsData;
        definitions[template.name] = templateData;
    }];
    payload[@"definitions"] = definitions;
    
    return payload;
}

- (NSDictionary*)flatten:(NSDictionary*)map varName:(NSString*)varName {
    NSMutableDictionary *varsPayload = [NSMutableDictionary dictionary];
    
    [map enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
        if ([value isKindOfClass:[NSString class]] ||
            [value isKindOfClass:[NSNumber class]]) {
            NSString *flatKey = [NSString stringWithFormat:@"%@.%@", varName, key];
            varsPayload[flatKey] = @{ CT_PE_DEFAULT_VALUE: value };
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            NSString *flatKey = [NSString stringWithFormat:@"%@.%@", varName, key];
            NSDictionary* flattenedMap = [self flatten:value varName:flatKey];
            [varsPayload addEntriesFromDictionary:flattenedMap];
        }
    }];
    
    return varsPayload;
}

- (BOOL)existsTemplateWithName:(nonnull NSString *)name {
    return self.templates[name];
}

@end

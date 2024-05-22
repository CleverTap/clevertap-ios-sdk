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
#import "CTInAppNotification.h"
#import "CTTemplateContext-Internal.h"

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

+ (void)clearTemplateProducers {
    [templateProducers removeAllObjects];
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
                    @throw([NSException
                            exceptionWithName:@"CleverTap Error"
                            reason:[NSString stringWithFormat:@"CleverTap: Template with name: %@ is already defined.", template.name]
                            userInfo:nil]);
                }
            }
        }
    }
    return self;
}

- (BOOL)isRegisteredTemplateWithName:(nonnull NSString *)name {
    return self.templates[name];
}

- (void)presentNotification:(CTInAppNotification *)notification withDelegate:(id<CTInAppNotificationDisplayDelegate>)delegate {
    CTCustomTemplate *template = self.templates[notification.customTemplateInAppData.templateName];
    if (!template) {
        CleverTapLogStaticDebug("%@: Template with name:%@ not registered.", self, notification.customTemplateInAppData.templateName);
        return;
    }
    
    CTTemplateContext *context = [[CTTemplateContext alloc] initWithTemplate:template andNotification:notification];
    context.delegate = delegate;
    [template.presenter onPresent:context];
}

- (NSDictionary*)syncPayload {
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    payload[@"type"] = @"templatePayload";
    
    NSMutableDictionary *definitions = [NSMutableDictionary dictionary];
    NSDictionary *templates = [self templates];
    [templates enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString * _Nonnull templateKey, CTCustomTemplate * _Nonnull template, BOOL * _Nonnull stop) {
        NSMutableDictionary *templateData = [NSMutableDictionary dictionary];
        templateData[@"type"] = template.templateType;

        NSMutableDictionary *groupedMap = [NSMutableDictionary dictionary];
        for (CTTemplateArgument *arg in template.arguments) {
            NSArray *components = [arg.name componentsSeparatedByString:@"."];
            NSString *firstComponent = components[0];
            NSMutableArray *groupedArguments = groupedMap[firstComponent];
            if (!groupedArguments) {
                groupedArguments = [NSMutableArray array];
                groupedMap[firstComponent] = groupedArguments;
            }
            [groupedArguments addObject:arg];
        }
        
        // Set the order of each argument
        NSMutableSet *ordered = [NSMutableSet set];
        int order = 0;
        NSMutableDictionary *arguments = [NSMutableDictionary dictionaryWithCapacity:template.arguments.count];
        for (CTTemplateArgument *arg in template.arguments) {
            if (![arg.name containsString:@"."]) {
                NSMutableDictionary *argument = [self argumentPayload:arg order:order];
                arguments[arg.name] = argument;
                order++;
            } else {
                NSString *prefix = [arg.name componentsSeparatedByString:@"."][0];
                if (![ordered containsObject:prefix]) {
                    [ordered addObject:prefix];
                    NSArray *groupedArguments = groupedMap[prefix];
                    // Sort strings with dots by their first component and add them to the sorted array
                    NSArray *sortedArgs = [groupedArguments sortedArrayUsingComparator:^NSComparisonResult(CTTemplateArgument *arg1, CTTemplateArgument *arg2) {
                        return [arg1.name localizedCaseInsensitiveCompare:arg2.name];
                    }];
                    for (CTTemplateArgument *arg in sortedArgs) {
                        NSMutableDictionary *argument = [self argumentPayload:arg order:order];
                        arguments[arg.name] = argument;
                        order++;
                    }
                }
            }
        }
        
        templateData[@"vars"] = arguments;
        definitions[template.name] = templateData;
    }];
    payload[@"definitions"] = definitions;
    
    return payload;
}

- (NSMutableDictionary *)argumentPayload:(CTTemplateArgument *)arg order:(int)order {
    NSMutableDictionary *argument = [NSMutableDictionary new];
    id defaultValue = arg.defaultValue;
    if (defaultValue) {
        argument[@"defaultValue"] = defaultValue;
    }
    NSString *type = [CTTemplateArgument templateArgumentTypeString:arg.type];
    if (type) {
        argument[@"type"] = type;
    }
    argument[@"order"] = @(order);
    return argument;
}

@end

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

@interface CTCustomTemplatesManager () <CTTemplateContextDismissDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString *, CTCustomTemplate *> *templates;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CTTemplateContext *> *activeContexts;

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
        self.activeContexts = [NSMutableDictionary dictionary];
        self.templates = [NSMutableDictionary dictionary];
        for (id producer in templateProducers) {
            NSSet *customTemplates = [producer defineTemplates:instanceConfig];
            for (CTCustomTemplate *template in customTemplates) {
                if (!self.templates[template.name]) {
                    self.templates[template.name] = template;
                } else {
                    @throw([NSException
                            exceptionWithName:CLTAP_CUSTOM_TEMPLATE_EXCEPTION
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

- (BOOL)isVisualTemplateWithName:(nonnull NSString *)name {
    return self.templates[name].isVisual;
}

- (CTTemplateContext *)activeContextForTemplate:(NSString *)templateName {
    return self.activeContexts[templateName];
}

- (void)onDismissContext:(CTTemplateContext *)context {
    [self.activeContexts removeObjectForKey:context.templateName];
}

- (BOOL)presentNotification:(CTInAppNotification *)notification 
               withDelegate:(id<CTInAppNotificationDisplayDelegate>)delegate
          andFileDownloader:(CTFileDownloader *)fileDownloader {
    CTCustomTemplate *template = self.templates[notification.customTemplateInAppData.templateName];
    if (!template) {
        CleverTapLogStaticDebug("%@: Template with name: %@ not registered.", self, notification.customTemplateInAppData.templateName);
        return NO;
    }

    CTTemplateContext *context = [self createTemplateContext:template
                                            withNotification:notification
                                                    delegate:delegate
                                           andFileDownloader:fileDownloader];
    self.activeContexts[template.name] = context;
    [template.presenter onPresent:context];
    return YES;
}

- (CTTemplateContext *)createTemplateContext:(CTCustomTemplate *)template
                            withNotification:(CTInAppNotification *)notification
                                    delegate:(id<CTInAppNotificationDisplayDelegate>)delegate
                           andFileDownloader:(CTFileDownloader *)fileDownloader {
    CTTemplateContext *context = [[CTTemplateContext alloc] initWithTemplate:template notification:notification andFileDownloader:fileDownloader];
    [context setNotificationDelegate:delegate];
    [context setDismissDelegate:self];
    return context;
}

- (void)closeNotification:(CTInAppNotification *)notification {
    NSString *templateName = notification.customTemplateInAppData.templateName;
    if (!templateName) {
        CleverTapLogStaticDebug("%@: No template name set in the notification template data.", [self class]);
        return;
    }
    
    CTCustomTemplate *template = self.templates[templateName];
    if (!template) {
        CleverTapLogStaticDebug("%@: Template with name: %@ not registered.", [self class], templateName);
        return;
    }
    
    CTTemplateContext *context = [self activeContextForTemplate:templateName];
    if (!context) {
        CleverTapLogStaticDebug("%@: Cannot find active context for template: %@.", [self class], templateName);
        return;
    }
    
    if (template.presenter) {
        [template.presenter onCloseClicked:context];
    }
}

- (NSSet<NSString *> *)fileArgsURLsForInAppData:(CTCustomTemplateInAppData *)inAppData {
    NSMutableSet<NSString *> *urls = [NSMutableSet set];
    if (!inAppData) {
        return urls;
    }
    
    CTCustomTemplate *template = self.templates[inAppData.templateName];
    if (!template) {
        return urls;
    }
    
    for (CTTemplateArgument *arg in template.arguments) {
        if (arg.type == CTTemplateArgumentTypeFile) {
            id value = inAppData.args[arg.name];
            if (value && [value isKindOfClass:[NSString class]]) {
                [urls addObject:value];
            }
        }
        if (arg.type == CTTemplateArgumentTypeAction) {
            id value = inAppData.args[arg.name];
            if (value && [value isKindOfClass:[NSDictionary class]]) {
                CTCustomTemplateInAppData *actionData = [CTCustomTemplateInAppData createWithJSON:value];
                if (actionData) {
                    NSSet<NSString *> *actionUrls = [self fileArgsURLsForInAppData:actionData];
                    [urls unionSet:actionUrls];
                }
            }
        }
    }
    return urls;
}

- (NSSet<NSString *> *)fileArgsURLs:(NSDictionary *)inAppJSON {
    CTCustomTemplateInAppData *inAppData = [CTCustomTemplateInAppData createWithJSON:inAppJSON];
    return [self fileArgsURLsForInAppData:inAppData];
}

- (NSDictionary*)syncPayload {
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    payload[@"type"] = @"templatePayload";
    
    NSMutableDictionary *definitions = [NSMutableDictionary dictionary];
    NSDictionary *templates = [self templates];
    [templates enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull templateKey, CTCustomTemplate * _Nonnull template, BOOL * _Nonnull stop) {
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
    NSString *type = [CTTemplateArgument templateArgumentTypeToString:arg.type];
    if (type) {
        argument[@"type"] = type;
    }
    argument[@"order"] = @(order);
    return argument;
}

@end

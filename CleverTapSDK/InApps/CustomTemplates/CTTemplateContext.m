//
//  CTTemplateContext.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.02.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTTemplateContext.h"
#import "CTTemplateContext-Internal.h"
#import "CTTemplateArgument.h"
#import "CTCustomTemplate-Internal.h"
#import "CTNotificationAction.h"
#import "CTConstants.h"
#import "CTCustomTemplateBuilder.h"

@interface CTTemplateContext ()

@property (nonatomic) CTCustomTemplate *template;
@property (nonatomic) CTInAppNotification *notification;
@property (nonatomic, strong) NSDictionary *argumentValues;
@property (nonatomic) id<CTInAppNotificationDisplayDelegate> notificationDelegate;
@property (nonatomic) id<CTTemplateContextDismissDelegate> dismissDelegate;
@property (nonatomic) BOOL isAction;
@property (nonatomic) CTFileDownloader *fileDownloader;

@end

@implementation CTTemplateContext

@synthesize argumentValues = _argumentValues;

- (instancetype)initWithTemplate:(CTCustomTemplate *)customTemplate
                    notification:(CTInAppNotification *)notification
               andFileDownloader:(CTFileDownloader *)fileDownloader {
    if (self = [super init]) {
        self.notification = notification;
        self.template = customTemplate;
        self.isAction = notification.customTemplateInAppData.isAction;
        self.fileDownloader = fileDownloader;
    }
    return self;
}

- (NSString *)templateName {
    return self.template.name;
}

- (NSString *)stringNamed:(NSString *)name {
    return self.argumentValues[name];
}

- (NSNumber *)numberNamed:(NSString *)name {
    return self.argumentValues[name];
}

- (int)charNamed:(NSString *)name {
    return [[self numberNamed:name] charValue];
}

- (int)intNamed:(NSString *)name {
    return [[self numberNamed:name] intValue];
}

- (double)doubleNamed:(NSString *)name {
    return [[self numberNamed:name] doubleValue];
}

- (float)floatNamed:(NSString *)name {
    return [[self numberNamed:name] floatValue];
}

- (long)longNamed:(NSString *)name {
    return [[self numberNamed:name] longValue];
}

- (long long)longLongNamed:(NSString *)name {
    return [[self numberNamed:name] longLongValue];
}

- (BOOL)boolNamed:(NSString *)name {
    return [self.argumentValues[name] boolValue];
}

- (NSDictionary *)dictionaryNamed:(NSString *)name {
    NSString *namePrefix = [NSString stringWithFormat:@"%@.", name];
    NSArray *matchingKeys = [self.argumentValues.allKeys filteredArrayUsingPredicate:
                             [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject hasPrefix:namePrefix];
    }]];
    
    if ([matchingKeys count] == 0) {
        return nil;
    }
    
    NSDictionary<NSString *, id> *matchedDictionary = [self.argumentValues dictionaryWithValuesForKeys:matchingKeys];
    NSMutableDictionary<NSString *, id> *result = [NSMutableDictionary dictionary];
    for (NSString *key in matchedDictionary) {
        NSString *subKey = [key substringWithRange:NSMakeRange(namePrefix.length, key.length - namePrefix.length)];
        NSArray<NSString *> *keyParts = [subKey componentsSeparatedByString:@"."];
        id value = matchedDictionary[key];
        
        // If value is an action (CTNotificationAction *) return the template name or action type
        id keyValue;
        if ([value isKindOfClass:[CTNotificationAction class]]) {
            CTNotificationAction *action = value;
            keyValue = action.customTemplateInAppData.templateName ?: [CTInAppUtils inAppActionTypeString:action.type] ?: @"";
        } else {
            keyValue = value;
        }
        
        /* 
         a.b.c = 1
         a.b.d = 2
         a.b.e.f = 3
         [dictionaryNamed:a] -> keys = [b.c, b.d, b.e.f]
         result = {
            b {
                c: 1,
                d: 2,
                e: {
                    f: 3
                }
            }
         }
         */
        NSMutableDictionary<NSString *, id> *currentMap = result;
        for (NSUInteger i = 0; i < keyParts.count; i++) {
            NSString *keyPart = keyParts[i];
            if (i == keyParts.count - 1) {
                currentMap[keyPart] = keyValue;
            } else {
                NSMutableDictionary<NSString *, id> *innerMap = currentMap[keyPart];
                if (!innerMap) {
                    innerMap = [NSMutableDictionary dictionary];
                    currentMap[keyPart] = innerMap;
                }
                
                currentMap = innerMap;
            }
        }
    }
    
    return [result copy];
}

- (NSString *)fileNamed:(NSString *)name {
    return self.argumentValues[name];
}

- (void)presented {
    if (self.isAction) {
        return;
    }
    
    if (self.notificationDelegate) {
        [self.notificationDelegate notificationDidShow:self.notification];
    } else {
        CleverTapLogStaticDebug(@"%@: Cannot set template as presented.", [self class])
    }
}

- (void)triggerActionNamed:(NSString *)name {
    if ([self.template.templateType isEqualToString:FUNCTION_TYPE]) {
        return;
    }

    id action = self.argumentValues[name];
    if (![action isKindOfClass:[CTNotificationAction class]]) {
        CleverTapLogStaticDebug(@"%@: No argument of type action with name %@ for template %@.",
                                [self class], name, self.templateName);
        return;
    }
    
    if (self.notificationDelegate) {
        CTNotificationAction *notificationAction = action;
        NSString *campaignId = self.notification.campaignId ? self.notification.campaignId : @"";
        NSString *cta = notificationAction.customTemplateInAppData.templateName ? notificationAction.customTemplateInAppData.templateName : name;
        NSDictionary *extras = @{CLTAP_NOTIFICATION_ID_TAG:campaignId, CLTAP_PROP_WZRK_CTA: cta};
        [self.notificationDelegate handleNotificationAction:notificationAction forNotification:self.notification withExtras:extras];
    }
}

- (void)dismissed {
    if (self.dismissDelegate) {
        [self.dismissDelegate onDismissContext:self];
        self.dismissDelegate = nil;
    }
    
    // If the context is an action and visual:false,
    // it does not go through the in-app queue, so the dismiss is NOOP.
    // If the context is not an action, then it goes through the in-app queue no matter
    // the visual property i.e standalone function
    if (self.isAction && !self.template.isVisual) {
        return;
    }
    
    if (self.notificationDelegate) {
        [self.notificationDelegate notificationDidDismiss:self.notification fromViewController:nil];
        self.notificationDelegate = nil;
    } else {
        CleverTapLogStaticDebug(@"%@: Cannot set template as dismissed.", [self class])
    }
}

- (NSDictionary *)argumentValues {
    if (_argumentValues) {
        return _argumentValues;
    }
    _argumentValues = [self mergeArguments];
    return _argumentValues;
}

- (NSDictionary *)mergeArguments {
    NSMutableDictionary *merged = [NSMutableDictionary new];
    for (CTTemplateArgument *arg in self.template.arguments) {
        merged[arg.name] = arg.defaultValue;
        id override = [self valueForArgument:arg];
        if (override) {
            merged[arg.name] = override;
        }
    }
    
    return [merged copy];
}

- (id)valueForArgument:(CTTemplateArgument *)arg {
    NSDictionary *overrides = self.notification.customTemplateInAppData.args;
    id override = overrides[arg.name];
    if (override) {
        switch (arg.type) {
            case CTTemplateArgumentTypeString:
                if ([override isKindOfClass:[NSString class]]) {
                    return override;
                }
                break;
            case CTTemplateArgumentTypeNumber:
            case CTTemplateArgumentTypeBool:
                if ([override isKindOfClass:[NSNumber class]]) {
                    return override;
                }
                break;
            case CTTemplateArgumentTypeFile:
                if ([override isKindOfClass:[NSString class]]) {
                    return [self.fileDownloader fileDownloadPath:override];
                }
                break;
            case CTTemplateArgumentTypeAction: {
                CTNotificationAction *action = [[CTNotificationAction alloc] initWithJSON:override[CLTAP_INAPP_ACTIONS]];
                if (action && !action.error) {
                    return action;
                } else if (action.error) {
                    CleverTapLogStaticDebug(@"%@: Error creating action for argument: %@. Error: %@", [self class], arg.name, action.error);
                }
                break;
            }
            default:
                break;
        }
    }
    return nil;
}

- (NSString *)debugDescription {
    NSMutableArray<NSString *> *argsDescription = [NSMutableArray array];
    for (NSString *key in self.argumentValues) {
        NSString *value;
        if ([self.argumentValues[key] isKindOfClass:[CTNotificationAction class]]) {
            CTNotificationAction *action = self.argumentValues[key];
            NSString *name = action.customTemplateInAppData.templateName ? action.customTemplateInAppData.templateName : @"";
            value = [NSString stringWithFormat:@"Action: %@", name];
        } else {
            value = [self.argumentValues[key] debugDescription];
        }
        [argsDescription addObject:[NSString stringWithFormat:@"%@: %@", key, value]];
    }
    NSString *argsString = @"{\n}";
    if (argsDescription.count > 0) {
        argsString = [NSString stringWithFormat:@"{\n%@\n}", [argsDescription componentsJoinedByString:@",\n"]];
    }
    return [NSString stringWithFormat:@"<%@: %p> templateName: %@, args: %@",
            [self class],
            self,
            self.templateName,
            argsString];
}

@end

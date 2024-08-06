//
//  CTCustomTemplateInAppData.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 9.05.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import "CTCustomTemplateInAppData.h"
#import "CTConstants.h"
#import "CTInAppUtils.h"

@interface CTCustomTemplateInAppData()

@property (nonatomic, copy, readwrite) NSString *templateName;
@property (nonatomic, copy, readwrite) NSString *templateId;
@property (nonatomic, copy, readwrite) NSString *templateDescription;
@property (nonatomic, strong, readwrite) NSDictionary *args;

@property (nonatomic, strong, readwrite) NSDictionary *json;

@end

@implementation CTCustomTemplateInAppData

- (nonnull instancetype)initWithJSON:(nonnull NSDictionary *)json {
    if (self = [super init]) {
        @try {
            self.json = json;
            self.templateName = json[CLTAP_INAPP_TEMPLATE_NAME];
            self.templateId = json[CLTAP_INAPP_TEMPLATE_ID];
            self.templateDescription = json[CLTAP_INAPP_TEMPLATE_DESCRIPTION];
            id isAction = json[@"is_action"];
            
            if (isAction && [isAction isKindOfClass:[NSNumber class]]) {
                self.isAction = [isAction boolValue];
            }
            
            id vars = json[CLTAP_INAPP_VARS];
            if ([vars isKindOfClass:[NSDictionary class]]) {
                self.args = vars;
            }
        } @catch (NSException *e) {
            CleverTapLogStaticInfo(@"Cannot initialize %@ with json:%@. Error: %@.", self.class, json, [e debugDescription]);
        }
    }
    return self;
}

+ (instancetype)createWithJSON:(nonnull NSDictionary *)json {
    NSString *inAppType = json[CLTAP_INAPP_TYPE];
    if ([CTInAppUtils inAppTypeFromString:inAppType] == CTInAppTypeCustom) {
        return [[CTCustomTemplateInAppData alloc] initWithJSON:json];
    }
    return nil;
}

- (void)setIsAction:(BOOL)isAction {
    _isAction = isAction;
    NSMutableDictionary *jsonMutable = [self.json mutableCopy];
    jsonMutable[@"is_action"] = @(isAction);
    self.json = jsonMutable;
}

- (id)copyWithZone:(NSZone *)zone {
    CTCustomTemplateInAppData *copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        copy->_templateName = [_templateName copyWithZone:zone];
        copy->_templateId = [_templateId copyWithZone:zone];
        copy->_templateDescription = [_templateDescription copyWithZone:zone];
        copy->_args = [[NSDictionary allocWithZone:zone] initWithDictionary:self.args copyItems:YES];
        copy->_json = [[NSDictionary allocWithZone:zone] initWithDictionary:self.json copyItems:YES];
        copy->_isAction = _isAction;
    }
    return copy;
}

@end

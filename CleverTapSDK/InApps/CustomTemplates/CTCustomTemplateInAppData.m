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

@end

@implementation CTCustomTemplateInAppData

- (nonnull instancetype)initWithJSON:(nonnull NSDictionary *)json {
    if (self = [super init]) {
        @try {
            self.templateName = json[CLTAP_INAPP_TEMPLATE_NAME];
            self.templateId = json[CLTAP_INAPP_TEMPLATE_ID];
            self.templateDescription = json[CLTAP_INAPP_TEMPLATE_DESCRIPTION];
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

@end

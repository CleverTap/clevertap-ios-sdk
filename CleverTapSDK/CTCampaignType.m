//
//  CTCampaignType.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 22.11.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTCampaignType.h"

@implementation CTCampaignTypeHelper

+ (NSInteger)campaignTypeOrdinal:(NSString *)name {
    NSDictionary<NSString *, NSNumber *> *mapping = @{
            @"android": @(CTCampaignTypeAndroid),
            @"ios": @(CTCampaignTypeiOS),
            @"email": @(CTCampaignTypeEmail),
            @"windows": @(CTCampaignTypeWindows),
            @"fb": @(CTCampaignTypeFB),
            @"sms": @(CTCampaignTypeSMS),
            @"webhook": @(CTCampaignTypeWebhook),
            @"chrome": @(CTCampaignTypeChrome),
            @"googleadwords": @(CTCampaignTypeGoogleAdWords),
            @"inapp": @(CTCampaignTypeInApp),
            @"web": @(CTCampaignTypeWeb),
            @"push": @(CTCampaignTypePush),
            @"notificationInbox_android": @(CTCampaignTypeNotificationInboxAndroid),
            @"notificationInbox_ios": @(CTCampaignTypeNotificationInboxiOS),
            @"notificationInbox": @(CTCampaignTypeNotificationInbox),
            @"whatsapp": @(CTCampaignTypeWhatsApp),
            @"partner": @(CTCampaignTypePartner),
            @"nativedisplay": @(CTCampaignTypeNativeDisplay),
            @"firefox": @(CTCampaignTypeFirefox),
            @"safari": @(CTCampaignTypeSafari),
            @"kaios": @(CTCampaignTypeKaiOS),
            @"webnativedisplay": @(CTCampaignTypeWebNativeDisplay),
            @"webinbox": @(CTCampaignTypeWebInbox)
        };
    
    if (mapping[name]) {
        return [mapping[name] integerValue];
    }
    return -1;
}

@end

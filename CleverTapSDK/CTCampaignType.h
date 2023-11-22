//
//  CTCampaignType.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 22.11.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CTCampaignType) {
    CTCampaignTypeAndroid,
    CTCampaignTypeiOS,
    CTCampaignTypeEmail,
    CTCampaignTypeWindows,
    CTCampaignTypeFB,
    CTCampaignTypeSMS,
    CTCampaignTypeWebhook,
    CTCampaignTypeChrome,
    CTCampaignTypeGoogleAdWords,
    CTCampaignTypeInApp,
    CTCampaignTypeWeb,
    CTCampaignTypePush,
    CTCampaignTypeNotificationInboxAndroid,
    CTCampaignTypeNotificationInboxiOS,
    CTCampaignTypeNotificationInbox,
    CTCampaignTypeWhatsApp,
    CTCampaignTypePartner,
    CTCampaignTypeNativeDisplay,
    CTCampaignTypeFirefox,
    CTCampaignTypeSafari,
    CTCampaignTypeKaiOS,
    CTCampaignTypeWebNativeDisplay,
    CTCampaignTypeWebInbox
};

@interface CTCampaignTypeHelper : NSObject

+ (NSInteger)campaignTypeOrdinal:(NSString *)name;

@end
NS_ASSUME_NONNULL_END

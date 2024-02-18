//
//  CTLimitsMatcher.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 2.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTLimitsMatcher.h"

@implementation CTLimitsMatcher

- (BOOL)matchWhenLimits:(NSArray *)whenLimits forCampaignId:(NSString *)campaignId withImpressionManager:(CTImpressionManager *)impressionManager andTriggerManager:(CTInAppTriggerManager *)triggerManager {
    if (![campaignId isKindOfClass:[NSString class]] || [campaignId length] == 0) {
        return NO;
    }
    
    for (NSDictionary *limitJSON in whenLimits) {
        CTLimitAdapter *limitAdapter = [[CTLimitAdapter alloc] initWithJSON:limitJSON];
        if ([limitAdapter isEmpty]) {
            continue;
        }
        BOOL matched = [self matchLimit:limitAdapter forCampaignId:campaignId withImpressionManager:impressionManager andTriggerManager:triggerManager];
        if (!matched) {
            return NO;
        }
    }
    return YES;
}


- (BOOL)matchLimit:(CTLimitAdapter *)limit
     forCampaignId:(NSString *)campaignId
withImpressionManager:(CTImpressionManager *)impressionManager
 andTriggerManager:(CTInAppTriggerManager *)triggerManager {
    
    switch ([limit limitType]) {
        case CTLimitTypeSession:
            if ([impressionManager perSession:campaignId] < limit.limit) {
                return YES;
            }
            break;
        case CTLimitTypeSeconds:
            if ([impressionManager perSecond:campaignId seconds:limit.frequency] < limit.limit) {
                return YES;
            }
            break;
        case CTLimitTypeMinutes:
            if ([impressionManager perMinute:campaignId minutes:limit.frequency] < limit.limit) {
                return YES;
            }
            break;
        case CTLimitTypeHours:
            if ([impressionManager perHour:campaignId hours:limit.frequency] < limit.limit) {
                return YES;
            }
            break;
        case CTLimitTypeDays:
            if ([impressionManager perDay:campaignId days:limit.frequency] < limit.limit) {
                return YES;
            }
            break;
        case CTLimitTypeWeeks:
            if ([impressionManager perWeek:campaignId weeks:limit.frequency] < limit.limit) {
                return YES;
            }
            break;
        case CTLimitTypeEver:
            if ([impressionManager getImpressions:campaignId].count < limit.limit) {
                return YES;
            }
            break;
        case CTLimitTypeOnEvery: {
            NSInteger triggerCount = [triggerManager getTriggers:campaignId];
            if (triggerCount % limit.limit == 0) {
                return YES;
            }
            break;
        }
        case CTLimitTypeOnExactly: {
            NSInteger triggerCount = [triggerManager getTriggers:campaignId];
            if (triggerCount == limit.limit) {
                return YES;
            }
            break;
        }
        default:
            break;
    }
    
    return NO;
}

@end

//
//  CTLimitsMatcher.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 2.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTLimitsMatcher.h"

@implementation CTLimitsMatcher

- (BOOL)matchWhenLimits:(NSArray *)whenLimits forCampaignId:(NSString *)campaignId withImpressionManager:(CTImpressionManager *)manager {
    
    for (NSDictionary *limitJSON in whenLimits) {
        CTLimitAdapter *limitAdapter = [[CTLimitAdapter alloc] initWithJSON:limitJSON];
        BOOL matched = [self matchLimit:limitAdapter forCampaignId:campaignId withImpressionManager:manager];
        if (!matched) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)matchLimit:(CTLimitAdapter *)limit forCampaignId:(NSString *)campaignId withImpressionManager:(CTImpressionManager *)manager {
    
    switch ([limit limitType]) {
        case CTLimitTypeSession:
            if ([manager perSession:campaignId] < limit.limit) {
                return YES;
            }
            break;
        case CTLimitTypeSeconds:
            if ([manager perSecond:campaignId seconds:limit.frequency] < limit.limit) {
                return YES;
            }
            break;
        case CTLimitTypeMinutes:
            if ([manager perMinute:campaignId minutes:limit.frequency] < limit.limit) {
                return YES;
            }
            break;
        case CTLimitTypeHours:
            if ([manager perHour:campaignId hours:limit.frequency] < limit.limit) {
                return YES;
            }
            break;
        case CTLimitTypeDays:
            if ([manager perDay:campaignId days:limit.frequency] < limit.limit) {
                return YES;
            }
            break;
        case CTLimitTypeWeeks:
            if ([manager perWeek:campaignId weeks:limit.frequency] < limit.limit) {
                return YES;
            }
            break;
        case CTLimitTypeEver:
            if ([manager getImpressions:campaignId].count < limit.limit) {
                return YES;
            }
            break;
        case CTLimitTypeOnEvery: {
            NSInteger triggerCount = [manager getImpressions:campaignId].count;
            // TODO: VERIFY IF WE NEED TO ADD 1 TO TRIGGER COUNT, IF THE IMPRESSION HAS BEEN ALREADY RECORDED FROM ELSEWHERE
//            NSInteger currentTriggerCount = triggerCount + 1;
//            if (currentTriggerCount % limit.limit) {
            if (triggerCount % limit.limit == 0) {
                return YES;
            }
            break;
        }
        case CTLimitTypeOnExactly: {
            NSInteger triggerCount = [manager getImpressions:campaignId].count;
            // TODO: VERIFY IF WE NEED TO ADD 1 TO TRIGGER COUNT, IF THE IMPRESSION HAS BEEN ALREADY RECORDED FROM ELSEWHERE
//            NSInteger currentTriggerCount = triggerCount + 1;
//            if (currentTriggerCount == limit.limit) {
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

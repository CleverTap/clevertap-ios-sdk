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
            // TODO: implement all remaining cases
        default:
            break;
    }
    
    return NO;
}

@end

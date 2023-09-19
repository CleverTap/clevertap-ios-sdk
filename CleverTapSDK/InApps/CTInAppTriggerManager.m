//
//  CTInAppTriggerManager.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 12.09.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTInAppTriggerManager.h"
#import "CTPreferences.h"

@implementation CTInAppTriggerManager

- (NSUInteger)getTriggers:(NSString *)campaignId {
    NSUInteger savedTriggers = [CTPreferences getIntForKey:[self getTriggersKey:campaignId] withResetValue:0];
    
    return savedTriggers;
}

- (void)incrementTrigger:(NSString *)campaignId {
    NSUInteger savedTriggers = [self getTriggers:campaignId];
    savedTriggers++;
    [CTPreferences putInt:savedTriggers forKey:[self getTriggersKey:campaignId]];
}

- (NSString *)getTriggersKey:(NSString *)campaignId {
    return [NSString stringWithFormat:@"%@_%@", @"_triggers", campaignId];
}

- (void)removeTriggers:(NSString *)campaignId {
    [CTPreferences removeObjectForKey:[self getTriggersKey:campaignId]];
}

@end

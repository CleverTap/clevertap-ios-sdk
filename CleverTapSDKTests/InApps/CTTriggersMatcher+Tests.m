//
//  CTTriggersMatcher+Tests.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 17.11.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTTriggersMatcher+Tests.h"
#import "CTConstants.h"

@implementation CTTriggersMatcher(Tests)

- (BOOL)matchEventWhenTriggers:(NSArray *)whenTriggers eventName:(NSString *)eventName eventProperties:(NSDictionary *)eventProperties {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:eventName eventProperties:eventProperties andLocation:kCLLocationCoordinate2DInvalid];

    return [self matchEventWhenTriggers:whenTriggers event:event];
}

- (BOOL)matchChargedEventWhenTriggers:(NSArray *)whenTriggers details:(NSDictionary *)details items:(NSArray<NSDictionary *> *)items {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_CHARGED_EVENT eventProperties:details location:kCLLocationCoordinate2DInvalid andItems:items];

    return [self matchEventWhenTriggers:whenTriggers event:event];
}

@end

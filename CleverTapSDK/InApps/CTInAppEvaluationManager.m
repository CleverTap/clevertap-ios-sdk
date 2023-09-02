//
//  CTInAppEvaluationManager.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 31.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTInAppEvaluationManager.h"
#import "CTConstants.h"
#import "CTEventAdapter.h"

@interface CTInAppEvaluationManager()

- (void)evaluateServerSide:(CTEventAdapter *)event;
- (void)evaluateClientSide:(CTEventAdapter *)event;
- (NSArray *)evaluate:(CTEventAdapter *)event withInApps:(NSArray *)inApps;

@end

@implementation CTInAppEvaluationManager

- (void)evaluateOnEvent:(NSString *)eventName withProps:(NSDictionary *)properties {
    if (![eventName isEqualToString:CLTAP_APP_LAUNCHED_EVENT]) {
        CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:eventName eventProperties:properties];
        [self evaluateServerSide:event];
        [self evaluateClientSide:event];
    }
}

- (void)evaluateOnChargedEvent:(NSDictionary *)chargeDetails andItems:(NSArray *)items {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:@"Charged" eventProperties:chargeDetails andItems:items];
    [self evaluateServerSide:event];
    [self evaluateClientSide:event];
}

- (void)evaluateOnAppLaunchedClientSide {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_APP_LAUNCHED_EVENT eventProperties:@{}];
    [self evaluateClientSide:event];
}

- (void)evaluateOnAppLaunchedServerSide:(NSArray *)appLaunchedNotifs {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_APP_LAUNCHED_EVENT eventProperties:@{}];
    [self evaluate:event withInApps:appLaunchedNotifs];
    // TODO: handle supressed inapps
    // TODO: eligibleInapps.sort().first().display();
}

- (void)evaluateClientSide:(CTEventAdapter *)event {
    // [self evaluate:event withInApps:[store clientSideNotifs]];
    // TODO: add to meta inapp_evals : eligibleInapps.addToMeta();
}

- (void)evaluateServerSide:(CTEventAdapter *)event {
    // [self evaluate:event withInApps:[store serverSideNotifs]];
    // TODO: handle supressed inapps
    // TODO: calculate TTL field and put it in the json based on ttlOffset parameter
    // TODO: eligibleInapps.sort().first().display();
}

- (NSArray *)evaluate:(CTEventAdapter *)event withInApps:(NSArray *)inApps {
    return @[]; // returns eligible inapps
}

@end

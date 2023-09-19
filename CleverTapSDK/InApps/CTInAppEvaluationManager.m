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

// TODO: Can we use NSMutableSet?
@property (nonatomic, strong) NSMutableArray *evaluatedServerSideInAppIds;
@property (nonatomic, strong) NSMutableArray *suppressedClientSideInApps;
@property BOOL hasAppLaunchedFailed;

@end

@implementation CTInAppEvaluationManager

// TODO: init
// TODO: set delegate

- (instancetype)initWithCleverTap:(CleverTap *)instance {
    if (self = [super init]) {
        [instance setBatchSentDelegate:self];
        self.evaluatedServerSideInAppIds = [NSMutableArray new];
        self.suppressedClientSideInApps = [NSMutableArray new];
    }
    return self;
}

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
    NSMutableArray *eligibleInApps = [[self evaluate:event withInApps:appLaunchedNotifs] mutableCopy];
    [self sortByPriority:eligibleInApps];
    if (eligibleInApps.count > 0) {
        // TODO: handle supressed inapps
        // TODO: eligibleInapps.sort().first().display();
    }
}

- (void)evaluateClientSide:(CTEventAdapter *)event {
    // [self evaluate:event withInApps:[store clientSideNotifs]];
    NSMutableArray *eligibleInApps = [[self evaluate:event withInApps:@[]] mutableCopy];
    [self sortByPriority:eligibleInApps];
    if (eligibleInApps.count > 0) {
        NSMutableDictionary *inApp = eligibleInApps[0];
        if ([self shouldSuppress:inApp]) {
            [self suppress:inApp];
            return;
        }
        [self updateTTL:inApp];
        
        // TODO: eligibleInapps.sort().first().display();
    }
}

- (void)evaluateServerSide:(CTEventAdapter *)event {
    // [self evaluate:event withInApps:[store serverSideNotifs]];
    // TODO: add to meta inapp_evals : eligibleInapps.addToMeta();
    NSArray *eligibleInApps = [self evaluate:event withInApps:@[]];
    [self addToMeta:eligibleInApps];
}

- (NSArray *)evaluate:(CTEventAdapter *)event withInApps:(NSArray *)inApps {
    // TODO: whenTriggers
    // TODO: record trigger
    // TODO: whenLimits
    return @[]; // returns eligible inapps
}

- (void)onBatchSent:(NSArray *)batchWithHeader withSuccess:(BOOL)success {
    if (success) {
        NSDictionary *header = batchWithHeader[0];
        [self removeSentEvaluatedServerSideInAppIds:header];
        [self removeSentSuppressedClientSideInApps:header];
    }
}

- (void)onAppLaunchedWithSuccess:(BOOL)success {
    // Handle multiple failures where request is retried
    if (!self.hasAppLaunchedFailed) {
        [self evaluateOnAppLaunchedClientSide];
    }
    self.hasAppLaunchedFailed = !success;
}

- (void)removeSentEvaluatedServerSideInAppIds:(NSDictionary *)header {
    NSArray *inapps_eval = header[@"inapps_eval"];
    if (inapps_eval) {
        [self.evaluatedServerSideInAppIds removeObjectsInRange:NSMakeRange(0, inapps_eval.count-1)];
    }
}

- (void)removeSentSuppressedClientSideInApps:(NSDictionary *)header {
    NSArray *suppresed_inapps = header[@"suppresed_inapps"];
    if (suppresed_inapps) {
        [self.suppressedClientSideInApps removeObjectsInRange:NSMakeRange(0, suppresed_inapps.count-1)];
    }
}

- (void)addToMeta:(NSArray<NSDictionary *> *)inApps {
    for (NSDictionary *inApp in inApps) {
        NSString *campaignId = inApp[@"ti"];
        if (campaignId) {
            [self.evaluatedServerSideInAppIds addObject:campaignId];
        }
    }
}

- (BOOL)shouldSuppress:(NSDictionary *)inApp {
    return [inApp[@"suppressed"] boolValue];
}

- (void)suppress:(NSDictionary *)inApp {
    NSString *ti = inApp[@"ti"];
    NSString *wzrk_id = [self generateWzrkId:ti];
    NSString *pivot = inApp[@"wzrk_pivot"] ? inApp[@"wzrk_pivot"] : @"wzrk_default";
    NSNumber *cgId = inApp[@"wzrk_cgId"];

    [self.suppressedClientSideInApps addObject:@{
        @"wzrk_id": wzrk_id,
        @"wzrk_pivot": pivot,
        @"wzrk_cgId": cgId
    }];
}

- (void)sortByPriority:(NSMutableArray *)inApps {
    NSNumber *(^priority)(NSDictionary *) = ^NSNumber *(NSDictionary *inApp) {
        NSNumber *priority = inApp[@"priority"];
        if (priority) {
            return priority;
        }
        return @(1);
    };
    
    NSNumber *(^ti)(NSDictionary *) = ^NSNumber *(NSDictionary *inApp) {
        NSNumber *ti = inApp[@"ti"];
        if (ti) {
            return ti;
        }
        return [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    };
    
    // Sort by priority descending since 100 is highest priority and 1 is lowest
    NSSortDescriptor* sortByPriorityDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:NO comparator:^NSComparisonResult(NSDictionary *inAppA, NSDictionary *inAppB) {
        NSNumber *priorityA = priority(inAppA);
        NSNumber *priorityB = priority(inAppB);
        NSComparisonResult comparison = [priorityA compare:priorityB];
        return  comparison;
    }];
    
    // Sort by the earliest created, ascending order of the timestamps
    NSSortDescriptor* sortByTimestampDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES comparator:^NSComparisonResult(NSDictionary *inAppA, NSDictionary *inAppB) {
        // If priority is the same, display the earliest created
        return [ti(inAppA) compare:ti(inAppB)];
    }];

    // Sort by priority then by timestamp if priority is same
    [inApps sortUsingDescriptors:@[sortByPriorityDescriptor, sortByTimestampDescriptor]];
}

- (NSString *)generateWzrkId:(NSString *)ti {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *date = [dateFormatter stringFromDate:[NSDate date]];
    NSString *wzrk_id = [NSString stringWithFormat:@"%@_%@", ti, date];
    return wzrk_id;
}

- (void)updateTTL:(NSMutableDictionary *)inApp {
    NSNumber *offset = inApp[@"wzrk_ttl_offset"];
    if (offset) {
        NSInteger now = [[NSDate date] timeIntervalSince1970];
        NSInteger ttl = now + [offset longValue];
        [inApp setObject:[NSNumber numberWithLong:ttl] forKey:@"wzrk_ttl"];
    } else {
        // Remove TTL, since it cannot be calculated based on the TTL offset
        // The deafult TTL will be set in CTInAppNotification
        [inApp removeObjectForKey:@"wzrk_ttl"];
    }
}

@end

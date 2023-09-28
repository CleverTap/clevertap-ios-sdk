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
#import "CTInAppStore.h"
#import "CTTriggersMatcher.h"
#import "CTLimitsMatcher.h"
#import "CTInAppTriggerManager.h"

@interface CTInAppEvaluationManager()

- (void)evaluateServerSide:(CTEventAdapter *)event;
- (void)evaluateClientSide:(CTEventAdapter *)event;
- (NSMutableArray *)evaluate:(CTEventAdapter *)event withInApps:(NSArray *)inApps;

@property (nonatomic, strong) NSMutableArray *evaluatedServerSideInAppIds;
@property (nonatomic, strong) NSMutableArray *suppressedClientSideInApps;
@property BOOL hasAppLaunchedFailed;

@property (nonatomic, strong) CTInAppStore *inAppStore;
@property (nonatomic, strong) CleverTap *instance;
@property (nonatomic, strong) CTTriggersMatcher *triggersMatcher;
@property (nonatomic, strong) CTLimitsMatcher *limitsMatcher;
@property (nonatomic, strong) CTInAppTriggerManager *triggerManager;
@property (nonatomic, strong) CTImpressionManager *impressionManager;

@end

@implementation CTInAppEvaluationManager

// TODO: init

static void *deviceIdContext = &deviceIdContext;
static void *sessionIdContext = &sessionIdContext;

- (instancetype)initWithCleverTap:(CleverTap *)instance deviceInfo:(CTDeviceInfo *)deviceInfo {
    if (self = [super init]) {
        self.instance = instance;
        [self.instance setBatchSentDelegate:self];
        self.evaluatedServerSideInAppIds = [NSMutableArray new];
        self.suppressedClientSideInApps = [NSMutableArray new];
        
        self.inAppStore = [[CTInAppStore alloc]initWithConfig:instance.config deviceInfo:deviceInfo];
        self.triggersMatcher = [CTTriggersMatcher new];
        self.limitsMatcher = [CTLimitsMatcher new];
        self.triggerManager = [CTInAppTriggerManager new];
        self.impressionManager = [CTImpressionManager new];
        
        // TODO: decide whether to use KVO to observe deviceId and session changes
        [self.instance addObserver:self forKeyPath:@"deviceInfo.deviceId" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:deviceIdContext];
        [self.instance addObserver:self forKeyPath:@"sessionId" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:sessionIdContext];
    }
    return self;
}

- (void)dealloc
{
    [self.instance removeObserver:self forKeyPath:@"deviceInfo.deviceId" context:deviceIdContext];
    [self.instance removeObserver:self forKeyPath:@"sessionId" context:sessionIdContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == deviceIdContext && [keyPath isEqualToString:@"deviceInfo.deviceId"]) {
        NSLog(@"[KVO] deviceId updated: %@", change);
    } else if (context == sessionIdContext) {
        if ([change[NSKeyValueChangeNewKey] isEqual:@0]) {
            // reset session
            NSLog(@"[KVO] sessionId set to 0: %@", change);
        }
    }
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
    NSMutableArray *eligibleInApps = [self evaluate:event withInApps:appLaunchedNotifs];
    [self sortByPriority:eligibleInApps];
    if (eligibleInApps.count > 0) {
        // TODO: handle supressed inapps
        // TODO: eligibleInapps.sort().first().display();
    }
}

- (void)evaluateClientSide:(CTEventAdapter *)event {
    NSMutableArray *eligibleInApps = [self evaluate:event withInApps:self.inAppStore.clientSideInApps];
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
    // TODO: add to meta inapp_evals : eligibleInapps.addToMeta();
    NSArray *eligibleInApps = [self evaluate:event withInApps:self.inAppStore.serverSideInApps];
    [self addToMeta:eligibleInApps];
}

- (NSMutableArray *)evaluate:(CTEventAdapter *)event withInApps:(NSArray *)inApps {
    NSMutableArray *eligibleInApps = [NSMutableArray new];
    for (NSDictionary *inApp in inApps) {
        NSString *campaignId = inApp[@"ti"];
        // Match trigger
        NSArray *whenTriggers = inApp[@"whenTriggers"];
        BOOL matchesTrigger = [self.triggersMatcher matchEventWhenTriggers:whenTriggers event:event];
        if (!matchesTrigger) continue;
        
        // In-app matches the trigger, increment trigger count
        [self.triggerManager incrementTrigger:campaignId];
        
        // Match limits
        NSArray *whenLimits = inApp[@"whenLimits"];
        BOOL matchesLimits = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:campaignId withImpressionManager:self.impressionManager];
        if (matchesLimits) {
            [eligibleInApps addObject:inApp];
        }
    }
    
    return eligibleInApps;
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

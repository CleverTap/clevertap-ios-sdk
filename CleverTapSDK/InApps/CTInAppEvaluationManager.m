//
//  CTInAppEvaluationManager.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 31.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "CTInAppEvaluationManager.h"
#import "CTConstants.h"
#import "CTEventAdapter.h"
#import "CTInAppStore.h"
#import "CTTriggersMatcher.h"
#import "CTLimitsMatcher.h"
#import "CTInAppTriggerManager.h"
#import "CTInAppDisplayManager.h"
#import "CTInAppNotification.h"
#import "CTUtils.h"
#import "CTPreferences.h"
#if __has_include(<CleverTapSDK/CleverTapSDK-Swift.h>)
#import <CleverTapSDK/CleverTapSDK-Swift.h>
#else
#import "CleverTapSDK-Swift.h"
#endif

/*!
 Deferred app-launch state for one `/a1` response and the content fetch it spawned.

 File-private: the window is an implementation detail of how this manager defers an evaluation,
 not a collaborator anything else needs to see.
 */
@interface CTInAppArbitrationCycle : NSObject

/// Winners buffered so far — one per response handled while the window was open.
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *candidates;

/// Campaign ids the content fetch said it would return. Diagnostics only.
@property (nonatomic, copy) NSArray<NSString *> *expectedTargetIds;

/*!
 Selection rules for the in-apps the content fetch will return, as synthetic payloads.

 Empty when the backend has not sent enough to predict with, in which case the window simply
 waits for the real response instead.
 */
@property (nonatomic, copy) NSArray<NSDictionary *> *syntheticCandidates;

/// Set on close, so a late completion and the timeout cannot both arbitrate.
@property (nonatomic, assign) BOOL closed;

/*!
 The in-app actually shown for this launch, once one has been.

 Kept only to detect a mispredicted fast path: if a real content candidate later arrives that
 would have outranked this, the synthetic rules disagreed with the delivered payload.
 */
@property (nonatomic, copy) NSDictionary *shownCandidate;

@end

@implementation CTInAppArbitrationCycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _candidates = [NSMutableArray array];
    }
    return self;
}

@end

/*!
 A trigger counter that reports a fixed number above the live one, without writing anything.

 Needed because the real evaluation increments a campaign's trigger count *before* limits are
 checked, so `onEvery` / `onExactly` compare against N+1. A dry run must not persist that
 increment, but reading the raw N would flip those limits' result — silently mispredicting
 exactly the campaigns that use trigger-based limits. Offsetting the read reproduces what the
 real path would see while leaving storage untouched.
 */
@interface CTOffsetTriggerCounter : NSObject <CTTriggerCounting>
- (instancetype)initWithCounter:(id<CTTriggerCounting>)counter offset:(NSUInteger)offset;
@end

@implementation CTOffsetTriggerCounter {
    id<CTTriggerCounting> _counter;
    NSUInteger _offset;
}

- (instancetype)initWithCounter:(id<CTTriggerCounting>)counter offset:(NSUInteger)offset {
    self = [super init];
    if (self) {
        _counter = counter;
        _offset = offset;
    }
    return self;
}

- (NSUInteger)getTriggers:(NSString *)campaignId {
    return [_counter getTriggers:campaignId] + _offset;
}

@end

@interface CTInAppEvaluationManager()

@property (nonatomic, strong) NSMutableArray *evaluatedServerSideInAppIds;
@property (nonatomic, strong) NSMutableArray *suppressedClientSideInApps;
@property (nonatomic, strong) NSMutableArray *evaluatedServerSideInAppIdsForProfile;
@property (nonatomic, strong) NSMutableArray *suppressedClientSideInAppsForProfile;
@property BOOL hasAppLaunchedFailed;
@property (nonatomic, strong) NSDictionary *appLaunchedProperties;

@property (nonatomic, strong) CTImpressionManager *impressionManager;
@property (nonatomic, strong) CTInAppDisplayManager *inAppDisplayManager;

@property (nonatomic, strong) CTTriggersMatcher *triggersMatcher;
@property (nonatomic, strong) CTLimitsMatcher *limitsMatcher;
@property (nonatomic, strong) CTInAppTriggerManager *triggerManager;
@property (nonatomic, strong) CTInAppStore *inAppStore;
@property (nonatomic, strong) NSString *accountId;
@property (nonatomic, strong) NSString *deviceId;

- (void)evaluateServerSide:(NSArray<CTEventAdapter *> *)events withQueueType:(CTQueueType)queueType;
- (void)evaluateClientSide:(NSArray<CTEventAdapter *> *)events;
- (NSMutableArray *)evaluate:(CTEventAdapter *)event withInApps:(NSArray *)inApps;

/// Guards `appLaunchedArbitrationCycle`. Mutated from the network thread, the content fetch
/// queue and the timeout, so every access is synchronized on this.
@property (nonatomic, strong) NSObject *arbitrationLock;

/// The open arbitration window, or nil when in-apps display immediately as before.
@property (nonatomic, strong) CTInAppArbitrationCycle *appLaunchedArbitrationCycle;

@end

@implementation CTInAppEvaluationManager

- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId
                  delegateManager:(CTMultiDelegateManager *)delegateManager
                impressionManager:(CTImpressionManager *)impressionManager
              inAppDisplayManager:(CTInAppDisplayManager *)inAppDisplayManager
                       inAppStore:(CTInAppStore *)inAppStore
              inAppTriggerManager:(CTInAppTriggerManager *)inAppTriggerManager
                   localDataStore:(CTLocalDataStore *)dataStore {
    if (self = [super init]) {
        self.accountId = accountId;
        self.deviceId = deviceId;
        self.impressionManager = impressionManager;
        self.inAppDisplayManager = inAppDisplayManager;

        self.arbitrationLock = [NSObject new];
        self.appLaunchedArbitrationTimeout = CLTAP_INAPP_ARBITRATION_TIMEOUT_SECONDS;

        self.evaluatedServerSideInAppIds = [NSMutableArray new];
        NSArray *savedEvaluatedServerSideInAppIds = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_INAPP_SS_EVAL_STORAGE_KEY]];
        if (savedEvaluatedServerSideInAppIds) {
            self.evaluatedServerSideInAppIds = [savedEvaluatedServerSideInAppIds mutableCopy];
        }
        
        self.suppressedClientSideInApps = [NSMutableArray new];
        NSArray *savedSuppressedClientSideInApps = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_INAPP_SUPPRESSED_STORAGE_KEY]];
        if (savedSuppressedClientSideInApps) {
            self.suppressedClientSideInApps = [savedSuppressedClientSideInApps mutableCopy];
        }
        
        self.evaluatedServerSideInAppIdsForProfile = [NSMutableArray new];
        NSArray *savedEvaluatedServerSideInAppIdsForProfile = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_INAPP_SS_EVAL_STORAGE_KEY_PROFILE]];
        if (savedEvaluatedServerSideInAppIdsForProfile) {
            self.evaluatedServerSideInAppIdsForProfile = [savedEvaluatedServerSideInAppIdsForProfile mutableCopy];
        }
        
        self.suppressedClientSideInAppsForProfile = [NSMutableArray new];
        NSArray *savedSuppressedClientSideInAppsForProfile = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:CLTAP_INAPP_SUPPRESSED_STORAGE_KEY_PROFILE]];
        if (savedSuppressedClientSideInAppsForProfile) {
            self.suppressedClientSideInAppsForProfile = [savedSuppressedClientSideInAppsForProfile mutableCopy];
        }
        
        self.inAppStore = inAppStore;
        self.triggersMatcher = [[CTTriggersMatcher alloc] initWithDataStore:dataStore];
        self.limitsMatcher = [CTLimitsMatcher new];
        self.triggerManager = inAppTriggerManager;
        
        [delegateManager addBatchSentDelegate:self];
        [delegateManager addAttachToHeaderDelegate:self];
    }
    return self;
}

- (void)evaluateOnEvent:(NSString *)eventName withProps:(NSDictionary *)properties {
    if ([eventName isEqualToString:CLTAP_APP_LAUNCHED_EVENT]) {
        self.appLaunchedProperties = properties ? properties : @{};
        return;
    }
    
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:eventName eventProperties:properties andLocation:self.location];
    NSArray *eventList = @[event];
    [self evaluateServerSide:eventList withQueueType:CTQueueTypeEvents];
    [self evaluateServerSideInAction:eventList withQueueType:CTQueueTypeEvents];
    [self evaluateClientSide:eventList];
    [self evaluateDelayedClientSide:eventList];
}

-(void)evaluateOnUserAttributeChange:(NSDictionary<NSString *, NSDictionary *> *)profile {
    NSDictionary *appFields = self.appLaunchedProperties;
    NSDictionary<NSString *, NSDictionary<NSString *, id> *> *nestedMap = [self toNestedMap:profile];
    NSMutableArray<CTEventAdapter *> *eventAdapterList = [NSMutableArray array];
    [nestedMap enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        if ([CLTAP_SKIP_KEYS_USER_ATTRIBUTE_EVALUATION containsObject: key]) {
            return;
        }
        NSString *eventName = [key stringByAppendingString:CLTAP_USER_ATTRIBUTE_CHANGE];
        NSMutableDictionary *eventProperties = [NSMutableDictionary dictionaryWithDictionary:value];
        [eventProperties addEntriesFromDictionary:appFields];
        CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:eventName profileAttrName:key eventProperties: eventProperties andLocation:self.location];
        [eventAdapterList addObject:event];
    }];
    [self evaluateServerSide:eventAdapterList withQueueType:CTQueueTypeProfile];
    [self evaluateServerSideInAction:eventAdapterList withQueueType:CTQueueTypeProfile];
    [self evaluateClientSide:eventAdapterList];
    [self evaluateDelayedClientSide:eventAdapterList];
}

- (NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)toNestedMap:(NSDictionary<NSString *, NSDictionary *> *)profileChanges {
    NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *result =
        [NSMutableDictionary dictionaryWithCapacity:profileChanges.count];
    
    [profileChanges enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *change, BOOL *stop) {
        result[key] = @{
            @"oldValue": change[@"oldValue"] ?: [NSNull null],
            @"newValue": change[@"newValue"] ?: [NSNull null]
        };
    }];
    return [result copy];
}

- (void)evaluateOnChargedEvent:(NSDictionary *)chargeDetails andItems:(NSArray *)items {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_CHARGED_EVENT eventProperties:chargeDetails location:self.location andItems:items];
    NSArray *eventList = @[event];
    CTQueueType queueType = CTQueueTypeEvents;
    [self evaluateServerSide:eventList withQueueType:queueType];
    [self evaluateServerSideInAction:eventList withQueueType:queueType];
    [self evaluateClientSide:eventList];
    [self evaluateDelayedClientSide:eventList];
}

- (void)evaluateOnAppLaunchedClientSide {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_APP_LAUNCHED_EVENT eventProperties:self.appLaunchedProperties andLocation:self.location];
    NSArray *eventList = @[event];
    [self evaluateClientSide:eventList];
    [self evaluateDelayedClientSide:eventList];
}

- (void)evaluateOnAppLaunchedServerSide:(NSArray *)appLaunchedNotifs {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_APP_LAUNCHED_EVENT eventProperties:self.appLaunchedProperties andLocation:self.location];
    NSMutableArray *eligibleInApps = [self evaluate:event withInApps:appLaunchedNotifs];
    // Server-side evaluations do **NOT** update TTL
    NSArray<NSDictionary *> *ssInApps = [self selectAndProcessEligibleInApps: eligibleInApps withStrategy:[ImmediateInAppSelectionStrategy shared] withTTL: false];
    // If the content fetch cannot outrank this winner, there is nothing to wait for.
    if ([self appLaunchedFastPathBeatsContentFetch:ssInApps forEvent:event]) {
        [self.inAppDisplayManager _addInAppNotificationsToQueue:ssInApps];
        return;
    }

    // While a window is open this winner competes against the content fetch result instead of
    // displaying now. See openAppLaunchedArbitrationWithTargetIds:syntheticCandidates:.
    if ([self bufferAppLaunchedCandidatesIfArbitrating:ssInApps]) {
        return;
    }
    [self.inAppDisplayManager _addInAppNotificationsToQueue:ssInApps];
}

/*!
 Decide whether the app-launch winner can be shown now instead of waiting for the content fetch.

 Only possible when the content fetch told us the selection rules of everything it will return
 (see `CTContentFetchItem.syntheticInAppPayload`). Without them this returns NO and the window
 waits, which is the behaviour when the backend sends no rules at all.

 The synthetic candidates are evaluated as a **dry run** — they must not record trigger counts,
 because the real payload is evaluated again when `/content` arrives.

 @return YES when the caller should display `appLaunchedWinners` immediately. The window is
 marked closed in that case, so the content response is dropped rather than shown as a second
 in-app.
 */
- (BOOL)appLaunchedFastPathBeatsContentFetch:(NSArray<NSDictionary *> *)appLaunchedWinners
                                    forEvent:(CTEventAdapter *)event {
    NSArray<NSDictionary *> *synthetics = nil;
    @synchronized (self.arbitrationLock) {
        CTInAppArbitrationCycle *cycle = self.appLaunchedArbitrationCycle;
        if (!cycle || cycle.closed || cycle.syntheticCandidates.count == 0) {
            return NO;
        }
        synthetics = cycle.syntheticCandidates;
    }

    // Nothing to show now, so the content result is the only possibility — wait for it.
    if (appLaunchedWinners.count == 0) {
        return NO;
    }

    NSMutableArray *eligibleSynthetics = [self evaluate:event withInApps:synthetics recordTriggers:NO];
    if (eligibleSynthetics.count == 0) {
        CleverTapLogStaticDebug(@"No content fetch candidate can qualify, showing App Launched in-app without waiting");
        [self markAppLaunchedArbitrationShown:appLaunchedWinners.firstObject];
        return YES;
    }

    // Same comparator as the real selection, but resolve the winner inline rather than through
    // selectAndProcessEligibleInApps: — that reports suppressions to the server, and these
    // candidates have not been delivered.
    NSMutableArray *merged = [appLaunchedWinners mutableCopy];
    [merged addObjectsFromArray:eligibleSynthetics];
    [self sortByPriority:merged];

    NSDictionary *predicted = nil;
    for (NSDictionary *candidate in merged) {
        if (![self shouldSuppress:candidate]) {
            predicted = candidate;
            break;
        }
    }

    if (!predicted || [predicted[CLTAP_INAPP_SYNTHETIC_CANDIDATE] boolValue]) {
        // A content candidate is predicted to win, so waiting for the real payload is worthwhile.
        CleverTapLogStaticDebug(@"Content fetch candidate %@ predicted to outrank App Launched in-app, waiting",
                                predicted ? [CTInAppNotification inAppId:predicted] : @"none");
        return NO;
    }

    CleverTapLogStaticDebug(@"App Launched in-app %@ outranks every content fetch candidate, showing without waiting",
                            [CTInAppNotification inAppId:predicted]);
    [self markAppLaunchedArbitrationShown:appLaunchedWinners.firstObject];
    return YES;
}

/*!
 Record that an in-app has been shown for this launch without going through the buffered path.

 Leaves the cycle in place but closed, so a content response arriving afterwards is suppressed
 rather than displayed as a second in-app.
 */
- (void)markAppLaunchedArbitrationShown:(NSDictionary *)shown {
    @synchronized (self.arbitrationLock) {
        CTInAppArbitrationCycle *cycle = self.appLaunchedArbitrationCycle;
        if (!cycle || cycle.closed) {
            return;
        }
        cycle.closed = YES;
        cycle.shownCandidate = shown;
    }
}

#pragma mark - App Launched arbitration

- (void)openAppLaunchedArbitrationWithTargetIds:(NSArray<NSString *> *)targetIds
                            syntheticCandidates:(NSArray<NSDictionary *> *)syntheticCandidates {
    CTInAppArbitrationCycle *cycle = [[CTInAppArbitrationCycle alloc] init];
    cycle.expectedTargetIds = [targetIds copy];
    cycle.syntheticCandidates = [syntheticCandidates copy];

    @synchronized (self.arbitrationLock) {
        if (self.appLaunchedArbitrationCycle && !self.appLaunchedArbitrationCycle.closed) {
            // A window is already open for a previous response. Leave it in place — closing it
            // here would display its winner and then immediately open a second window, which is
            // the multi-response behaviour we are trying to remove.
            CleverTapLogStaticDebug(@"App Launched arbitration already open, not opening another");
            return;
        }
        self.appLaunchedArbitrationCycle = cycle;
    }

    CleverTapLogStaticDebug(@"Opened App Launched arbitration, expecting %lu content target(s): %@",
                            (unsigned long)targetIds.count, targetIds);

    // Backstop only. The content fetch completion normally closes the window well before this.
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.appLaunchedArbitrationTimeout * NSEC_PER_SEC)),
                   dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        // Only time out the window this timer was scheduled for — a later one must not be cut short.
        BOOL isStillCurrent = NO;
        @synchronized (strongSelf.arbitrationLock) {
            isStillCurrent = (strongSelf.appLaunchedArbitrationCycle == cycle && !cycle.closed);
        }
        if (isStillCurrent) {
            CleverTapLogStaticDebug(@"App Launched arbitration timed out after %.1fs, showing best candidate so far",
                                    strongSelf.appLaunchedArbitrationTimeout);
            [strongSelf closeAppLaunchedArbitration];
        }
    });
}

- (void)appLaunchedArbitrationContentFetchDidComplete {
    // Show the merged winner unless the timeout already did.
    [self closeAppLaunchedArbitration];

    // Nothing further can arrive for this launch, so stop suppressing and return to normal.
    @synchronized (self.arbitrationLock) {
        self.appLaunchedArbitrationCycle = nil;
    }
}

- (void)closeAppLaunchedArbitration {
    NSArray<NSDictionary *> *candidates = nil;

    @synchronized (self.arbitrationLock) {
        CTInAppArbitrationCycle *cycle = self.appLaunchedArbitrationCycle;
        if (!cycle || cycle.closed) {
            // No window, or the completion and the timeout raced and the other one won.
            return;
        }
        cycle.closed = YES;
        candidates = [cycle.candidates copy];
        // Deliberately not cleared here. The cycle stays in place, closed, so that a content
        // response arriving after a timeout is suppressed rather than displayed as a second
        // in-app. It is cleared by appLaunchedArbitrationContentFetchDidComplete.
    }

    if (candidates.count == 0) {
        CleverTapLogStaticDebug(@"Closed App Launched arbitration with no eligible candidates");
        return;
    }

    // One merged selection across every buffered winner, so exactly one in-app is shown for the
    // launch. Reuses the normal path so the sort, suppression and reporting stay identical.
    NSMutableArray *merged = [[self class] withoutSyntheticCandidates:candidates];
    NSArray<NSDictionary *> *winner = [self selectAndProcessEligibleInApps:merged
                                                              withStrategy:[ImmediateInAppSelectionStrategy shared]
                                                                   withTTL:false];
    CleverTapLogStaticDebug(@"Closed App Launched arbitration, %lu candidate(s) merged, showing %@",
                            (unsigned long)candidates.count,
                            winner.firstObject ? [CTInAppNotification inAppId:winner.firstObject] : @"none");

    // Recorded so a candidate arriving after this close can be compared against what was shown.
    @synchronized (self.arbitrationLock) {
        if (self.appLaunchedArbitrationCycle) {
            self.appLaunchedArbitrationCycle.shownCandidate = winner.firstObject;
        }
    }

    [self.inAppDisplayManager _addInAppNotificationsToQueue:winner];
}

/*!
 Buffer a response's winner if a window is open, or drop it if the launch's slot is already spent.

 @return YES when the caller must not queue the in-apps for display.
 */
- (BOOL)bufferAppLaunchedCandidatesIfArbitrating:(NSArray<NSDictionary *> *)inApps {
    @synchronized (self.arbitrationLock) {
        CTInAppArbitrationCycle *cycle = self.appLaunchedArbitrationCycle;
        if (!cycle) {
            return NO;
        }

        if (cycle.closed) {
            // An in-app has already been shown for this launch — either the fast path showed one
            // without waiting, or the window timed out. This response lost: displaying it now
            // would give the user two in-apps, the bug the window exists to prevent. Drop it.
            if (inApps.count > 0) {
                CleverTapLogStaticDebug(@"Dropping %lu late App Launched candidate(s), arbitration already closed",
                                        (unsigned long)inApps.count);
                [self logIfMispredicted:inApps.firstObject against:cycle.shownCandidate];
            }
            return YES;
        }

        // An empty selection still counts as handled — nothing was eligible in this response, and
        // falling through would call the display queue with an empty array.
        NSArray<NSDictionary *> *displayable = [[self class] withoutSyntheticCandidates:inApps];
        if (displayable.count > 0) {
            [cycle.candidates addObjectsFromArray:displayable];
            CleverTapLogStaticDebug(@"Buffered %lu App Launched candidate(s) for arbitration, %lu total",
                                    (unsigned long)displayable.count, (unsigned long)cycle.candidates.count);
        }
        return YES;
    }
}

/*!
 Warn when a dropped content candidate would have outranked the in-app already shown.

 Only reachable via the fast path, and only if the selection rules in the `content_fetch` item
 disagreed with the payload `/content` actually delivered — a backend contract violation. The
 user has already been shown the wrong in-app by this point, so this is a diagnostic rather than
 something recoverable.
 */
- (void)logIfMispredicted:(NSDictionary *)dropped against:(NSDictionary *)shown {
    if (!dropped || !shown) {
        return;
    }

    NSMutableArray *pair = [@[dropped, shown] mutableCopy];
    [self sortByPriority:pair];
    if (pair.firstObject == dropped) {
        CleverTapLogStaticDebug(@"Content fetch candidate %@ outranks the already-shown %@ — the "
                                "selection rules sent with content_fetch disagree with the delivered payload",
                                [CTInAppNotification inAppId:dropped], [CTInAppNotification inAppId:shown]);
    }
}

/*!
 Strip payloads built for speculative evaluation only.

 A synthetic candidate carries selection rules but no content, so displaying one would render an
 empty in-app. They should never reach here — this is a boundary check on the display path, not
 flow control, so anything filtered out is logged as a programming error.
 */
+ (NSMutableArray<NSDictionary *> *)withoutSyntheticCandidates:(NSArray<NSDictionary *> *)inApps {
    NSMutableArray<NSDictionary *> *displayable = [NSMutableArray arrayWithCapacity:inApps.count];
    for (NSDictionary *inApp in inApps) {
        if ([inApp[CLTAP_INAPP_SYNTHETIC_CANDIDATE] boolValue]) {
            CleverTapLogStaticDebug(@"Refusing to display synthetic candidate %@ — it has no content",
                                    [CTInAppNotification inAppId:inApp]);
            continue;
        }
        [displayable addObject:inApp];
    }
    return displayable;
}

- (void)evaluateOnAppLaunchedDelayedServerSide:(NSArray<NSDictionary *> *)appLaunchedNotifs {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_APP_LAUNCHED_EVENT eventProperties:self.appLaunchedProperties andLocation:self.location];
    NSMutableArray *eligibleInApps = [self evaluate:event withInApps:appLaunchedNotifs];
    NSArray *ssInApps = [self selectAndProcessEligibleInApps: eligibleInApps withStrategy:[DelayedInAppSelectionStrategy shared] withTTL: true];
    // Create mutable array with mutable dictionaries (deep copy)
    NSMutableArray<NSMutableDictionary *> *ssInAppsCopy = [NSMutableArray array];
    for (NSDictionary *inApp in ssInApps) {
        [ssInAppsCopy addObject:[inApp mutableCopy]];
    }
    [self.inAppDisplayManager scheduleDelayedInAppsForAllModes:ssInAppsCopy];
}

- (void)evaluateOnAppLaunchedInActionServerSide:(NSArray *)appLaunchedNotifs {
    CTEventAdapter *event = [[CTEventAdapter alloc] initWithEventName:CLTAP_APP_LAUNCHED_EVENT eventProperties:self.appLaunchedProperties andLocation:self.location];
    NSMutableArray *eligibleInApps = [self evaluate:event withInApps:appLaunchedNotifs];
    // Server-side evaluations do **NOT** update TTL
    NSArray<NSDictionary *> *ssInApps = [self selectAndProcessEligibleInApps: eligibleInApps withStrategy:ImmediateInAppSelectionStrategy.shared withTTL: false];
    NSMutableArray<NSMutableDictionary *> *ssInAppsCopy = [ssInApps mutableCopy];
    [self.inAppDisplayManager scheduleInActionInApps: ssInAppsCopy];
}

- (void)evaluateClientSide:(NSArray<CTEventAdapter *> *)events {
    NSMutableArray<NSDictionary *> *eligibleInApps = [NSMutableArray array];
    for (CTEventAdapter *event in events) {
        id oldValue = [event.eventProperties objectForKey:CLTAP_KEY_OLD_VALUE];
        id newValue = [event.eventProperties objectForKey:CLTAP_KEY_NEW_VALUE];
        if (event.profileAttrName != nil && newValue == oldValue) {
            continue;
        }
        [eligibleInApps addObjectsFromArray:[self evaluate:event withInApps:self.inAppStore.clientSideInApps]];
    }
    // Client-side evaluations **DO** update TTL
    NSArray<NSDictionary *> *ssInApps = [self selectAndProcessEligibleInApps: eligibleInApps withStrategy:[ImmediateInAppSelectionStrategy shared] withTTL: true];
    [self.inAppDisplayManager _addInAppNotificationsToQueue:ssInApps];
}

- (NSArray<NSDictionary *> *)selectAndProcessEligibleInApps:(NSMutableArray *)eligibleInApps withStrategy:(id<InAppSelectionStrategy>)strategy withTTL:(BOOL)shouldUpdateTTLForThisContext {
    [self sortByPriority:eligibleInApps];
    //Track suppression updates
    __block BOOL updated = NO;
    NSArray<NSDictionary *> *selectedInApps = [strategy selectInApps:eligibleInApps suppressionHandler:^BOOL(NSDictionary *inApp) {
        BOOL isSuppressed = [self shouldSuppress:inApp];
        if (isSuppressed) {
            updated = YES;
            [self suppress:inApp];
        }
        return isSuppressed;
    }];
    //Strategy-specific TTL update (only if context allows)
    if(shouldUpdateTTLForThisContext && [strategy shouldUpdateTTL]) {
        for (NSDictionary *inApp in selectedInApps) {
            NSMutableDictionary  *mutableInApp = [inApp mutableCopy];
            [self.inAppStore updateTTL:mutableInApp];
        }
    }
    return selectedInApps;
}

- (void)evaluateDelayedClientSide:(NSArray<CTEventAdapter *> *)events {
    NSMutableArray<NSDictionary *> *eligibleInApps = [NSMutableArray array];
    for (CTEventAdapter *event in events) {
        id oldValue = [event.eventProperties objectForKey:CLTAP_KEY_OLD_VALUE];
        id newValue = [event.eventProperties objectForKey:CLTAP_KEY_NEW_VALUE];
        if (event.profileAttrName != nil && newValue == oldValue) {
            continue;
        }
        [eligibleInApps addObjectsFromArray:[self evaluate:event withInApps:self.inAppStore.delayedClientSideInApps]];
    }
    if (eligibleInApps.count <= 0) {
        return;
    }
    // Client-side evaluations **DO** update TTL
    NSArray<NSDictionary *> *ssInApps = [self selectAndProcessEligibleInApps: eligibleInApps withStrategy:[DelayedInAppSelectionStrategy shared] withTTL: true];
    [_inAppDisplayManager scheduleDelayedInAppsForAllModes:ssInApps];
}

- (void)evaluateServerSide:(NSArray<CTEventAdapter *> *)events withQueueType:(CTQueueType)queueType{
    NSMutableArray<NSDictionary *> *eligibleInApps = [NSMutableArray array];
    for (CTEventAdapter *event in events) {
        [eligibleInApps addObjectsFromArray:[self evaluate:event withInApps:self.inAppStore.serverSideInApps]];
    }
    BOOL updated = NO;
    for (NSDictionary *inApp in eligibleInApps) {
        NSString *campaignId = [CTInAppNotification inAppId:inApp];
        if (campaignId) {
            NSNumber *cid = [CTUtils numberFromString:campaignId];
            if (cid) {
                updated = YES;
                if (queueType == CTQueueTypeEvents){
                    [self.evaluatedServerSideInAppIds addObject:cid];
                }
                else if (queueType == CTQueueTypeProfile){
                    [self.evaluatedServerSideInAppIdsForProfile addObject:cid];
                }
            }
        }
    }
    if (updated) {
        if (queueType == CTQueueTypeEvents){
            [self saveEvaluatedServerSideInAppIds];
        }
        else if (queueType == CTQueueTypeProfile){
            [self saveEvaluatedServerSideInAppIdsForProfile];
        }
    }
}

- (void)evaluateServerSideInAction:(NSArray<CTEventAdapter *> *)events withQueueType:(CTQueueType)queueType {
    NSMutableArray<NSDictionary *> *eligibleInApps = [NSMutableArray array];
    for (CTEventAdapter *event in events) {
        [eligibleInApps addObjectsFromArray:[self evaluate:event withInApps:self.inAppStore.serverSideInActionMetaData]];
    }
    BOOL updated = NO;
    for (NSDictionary *inApp in eligibleInApps) {
        NSString *campaignId = [CTInAppNotification inAppId:inApp];
        if (campaignId) {
            NSNumber *cid = [CTUtils numberFromString:campaignId];
            if (cid) {
                updated = YES;
                if (queueType == CTQueueTypeEvents){
                    [self.evaluatedServerSideInAppIds addObject:cid];
                }
                else if (queueType == CTQueueTypeProfile){
                    [self.evaluatedServerSideInAppIdsForProfile addObject:cid];
                }
            }
        }
    }
    if (updated) {
        if (queueType == CTQueueTypeEvents){
            [self saveEvaluatedServerSideInAppIds];
        }
        else if (queueType == CTQueueTypeProfile){
            [self saveEvaluatedServerSideInAppIdsForProfile];
        }
    }
    [_inAppDisplayManager scheduleInActionInApps: eligibleInApps];
}

- (NSMutableArray *)evaluate:(CTEventAdapter *)event withInApps:(NSArray *)inApps {
    return [self evaluate:event withInApps:inApps recordTriggers:YES];
}

/*!
 Evaluate in-apps against an event, optionally without recording trigger counts.

 @param recordTriggers `YES` for a real evaluation. `NO` for a dry run — used to predict whether
 a candidate would qualify without mutating persisted state, so the same campaign can be
 evaluated for real later without its trigger count being counted twice.

 A dry run is not simply "skip the increment". The real path increments *before* checking limits,
 so `onEvery` / `onExactly` compare against N+1; reading the raw N would flip their result. The
 offsetting counter reproduces that view without writing it.
 */
- (NSMutableArray *)evaluate:(CTEventAdapter *)event
                  withInApps:(NSArray *)inApps
              recordTriggers:(BOOL)recordTriggers {
    NSMutableArray *eligibleInApps = [NSMutableArray new];
    id<CTTriggerCounting> triggerCounter = recordTriggers
        ? self.triggerManager
        : [[CTOffsetTriggerCounter alloc] initWithCounter:self.triggerManager offset:1];

    for (NSDictionary *inApp in inApps) {
        NSString *campaignId = [CTInAppNotification inAppId:inApp];
        if (!campaignId) {
            continue;
        }
        if (![self.inAppDisplayManager isTemplateRegistered:inApp]) {
            continue;
        }
        
        // Match trigger
        NSArray *whenTriggers = inApp[CLTAP_INAPP_TRIGGERS];
        BOOL matchesTrigger = [self.triggersMatcher matchEventWhenTriggers:whenTriggers event:event];
        if (!matchesTrigger) continue;
        CleverTapLogStaticDebug(@"Triggers matched for event %@ against inApp %@",[event eventName], campaignId);
        
        // In-app matches the trigger, increment trigger count
        if (recordTriggers) {
            [self.triggerManager incrementTrigger:campaignId];
        }

        // Match limits
        NSArray *frequencyLimits = inApp[CLTAP_INAPP_FC_LIMITS];
        NSArray *occurrenceLimits = inApp[CLTAP_INAPP_OCCURRENCE_LIMITS];
        NSMutableArray *whenLimits = [[NSMutableArray alloc] init];
        [whenLimits addObjectsFromArray:frequencyLimits];
        [whenLimits addObjectsFromArray:occurrenceLimits];
        BOOL matchesLimits = [self.limitsMatcher matchWhenLimits:whenLimits forCampaignId:campaignId
                                           withImpressionManager:self.impressionManager andTriggerManager:triggerCounter];
        if (matchesLimits) {
            CleverTapLogStaticDebug(@"Limits matched for event %@ against inApp %@",[event eventName], campaignId);
            [eligibleInApps addObject:inApp];
        }
    }
    
    return eligibleInApps;
}

- (void)onBatchSent:(NSArray *)batchWithHeader withSuccess:(BOOL)success withQueueType:(CTQueueType)queueType{
    if (success) {
        NSDictionary *header = batchWithHeader[0];
        if (queueType == CTQueueTypeEvents) {
            // For combined queues, clean up both events and profile arrays proportionally
            [self removeSentEvaluatedServerSideInAppIdsForCombined:header];
            [self removeSentSuppressedClientSideInAppsForCombined:header];
        }
    }
}

- (void)onAppLaunchedWithSuccess:(BOOL)success {
    // Handle multiple failures when request is retried
    if (!self.hasAppLaunchedFailed) {
        [self evaluateOnAppLaunchedClientSide];
    }
    self.hasAppLaunchedFailed = !success;
}

- (void)removeSentEvaluatedServerSideInAppIdsForCombined:(NSDictionary *)header {
    NSArray *inapps_eval = header[CLTAP_INAPP_SS_EVAL_META_KEY];
    if (inapps_eval && [inapps_eval count] > 0) {
        // Remove from events array first, then profiles
        NSUInteger eventsCount = [self.evaluatedServerSideInAppIds count];
        NSUInteger profilesCount = [self.evaluatedServerSideInAppIdsForProfile count];
        NSUInteger totalToRemove = [inapps_eval count];
        
        // Remove from events array
        NSUInteger removeFromEvents = MIN(eventsCount, totalToRemove);
        if (removeFromEvents > 0) {
            [self.evaluatedServerSideInAppIds removeObjectsInRange:NSMakeRange(0, removeFromEvents)];
            [self saveEvaluatedServerSideInAppIds];
            totalToRemove -= removeFromEvents;
        }
        
        // Remove remaining from profiles array
        if (totalToRemove > 0) {
            NSUInteger removeFromProfiles = MIN(profilesCount, totalToRemove);
            if (removeFromProfiles > 0) {
                [self.evaluatedServerSideInAppIdsForProfile removeObjectsInRange:NSMakeRange(0, removeFromProfiles)];
                [self saveEvaluatedServerSideInAppIdsForProfile];
            }
        }
    }
}

- (void)removeSentSuppressedClientSideInAppsForCombined:(NSDictionary *)header {
    NSArray *suppressed_inapps = header[CLTAP_INAPP_SUPPRESSED_META_KEY];
    if (suppressed_inapps && [suppressed_inapps count] > 0) {
        // Remove from events array first, then profiles
        NSUInteger eventsCount = [self.suppressedClientSideInApps count];
        NSUInteger profilesCount = [self.suppressedClientSideInAppsForProfile count];
        NSUInteger totalToRemove = [suppressed_inapps count];
        
        // Remove from events array
        NSUInteger removeFromEvents = MIN(eventsCount, totalToRemove);
        if (removeFromEvents > 0) {
            [self.suppressedClientSideInApps removeObjectsInRange:NSMakeRange(0, removeFromEvents)];
            [self saveSuppressedClientSideInApps];
            totalToRemove -= removeFromEvents;
        }
        
        // Remove remaining from profiles array
        if (totalToRemove > 0) {
            NSUInteger removeFromProfiles = MIN(profilesCount, totalToRemove);
            if (removeFromProfiles > 0) {
                [self.suppressedClientSideInAppsForProfile removeObjectsInRange:NSMakeRange(0, removeFromProfiles)];
                [self saveSuppressedClientSideInAppsForProfile];
            }
        }
    }
}

- (BOOL)shouldSuppress:(NSDictionary *)inApp {
    return [inApp[CLTAP_INAPP_IS_SUPPRESSED] boolValue];
}

- (void)suppress:(NSDictionary *)inApp {
    NSString *ti = [CTInAppNotification inAppId:inApp];
    if (!ti) return;
    NSString *wzrk_id = [self generateWzrkId:ti];
    NSString *pivot = inApp[CLTAP_NOTIFICATION_PIVOT] ? inApp[CLTAP_NOTIFICATION_PIVOT] : CLTAP_NOTIFICATION_PIVOT_DEFAULT;
    NSNumber *cgId = inApp[CLTAP_NOTIFICATION_CONTROL_GROUP_ID];
    
    NSMutableDictionary *suppressedInAppMeta = [NSMutableDictionary new];
    suppressedInAppMeta[CLTAP_NOTIFICATION_ID_TAG] = wzrk_id;
    suppressedInAppMeta[CLTAP_NOTIFICATION_PIVOT] = pivot;
    if (cgId) {
        suppressedInAppMeta[CLTAP_NOTIFICATION_CONTROL_GROUP_ID] = cgId;
    }
    [self.suppressedClientSideInApps addObject:suppressedInAppMeta];
    [self saveSuppressedClientSideInApps];
}

- (void)sortByPriority:(NSMutableArray *)inApps {
    NSNumber *(^delay)(NSDictionary *) = ^NSNumber *(NSDictionary *inApp) {
        NSNumber *d = inApp[CLTAP_DELAY_AFTER_TRIGGER];
        if (d != nil) return d;
        return @(0); // default to 0 if missing
    };
    
    NSNumber *(^priority)(NSDictionary *) = ^NSNumber *(NSDictionary *inApp) {
        NSNumber *priority = inApp[CLTAP_INAPP_PRIORITY];
        if (priority != nil) {
            return priority;
        }
        return @(1);
    };
    
    NSNumber *(^ti)(NSDictionary *) = ^NSNumber *(NSDictionary *inApp) {
        id ti = inApp[CLTAP_INAPP_ID];
        if (ti && [ti isKindOfClass:[NSNumber class]]) {
            return ti;
        } else if (ti && [ti isKindOfClass:[NSString class]]) {
            ti = [CTUtils numberFromString:ti];
            if (ti) return ti;
        }
        return [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    };
    
    // Sort by delay ascending
    NSSortDescriptor *sortByDelayDescriptor =
    [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES comparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [delay(a) compare:delay(b)];
    }];
    
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
    
    // Sort by delay theny by priority if delay is same
    //then by timestamp if priority is same
    [inApps sortUsingDescriptors:@[sortByDelayDescriptor, sortByPriorityDescriptor, sortByTimestampDescriptor]];
}

- (NSString *)generateWzrkId:(NSString *)ti {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:CLTAP_DATE_FORMAT];
    NSString *date = [dateFormatter stringFromDate:[NSDate date]];
    NSString *wzrk_id = [NSString stringWithFormat:@"%@_%@", ti, date];
    return wzrk_id;
}

- (BatchHeaderKeyPathValues)onBatchHeaderCreationForQueue:(CTQueueType)queueType {
    // Evaluation is done for events and profiles,
    // send the evaluated and suppressed ids in that queue header
    if (queueType != CTQueueTypeEvents && queueType != CTQueueTypeProfile) {
        return [NSMutableDictionary new];
    }
    
    NSMutableDictionary *header = [NSMutableDictionary new];
    
    // For combined queues, merge both events and profile arrays
    if (queueType == CTQueueTypeEvents) {
        // Combine evaluated IDs from both events and profiles
        NSMutableArray *combinedEvaluatedIds = [NSMutableArray array];
        if ([self.evaluatedServerSideInAppIds count] > 0) {
            [combinedEvaluatedIds addObjectsFromArray:self.evaluatedServerSideInAppIds];
        }
        if ([self.evaluatedServerSideInAppIdsForProfile count] > 0) {
            [combinedEvaluatedIds addObjectsFromArray:self.evaluatedServerSideInAppIdsForProfile];
        }
        if ([combinedEvaluatedIds count] > 0) {
            header[CLTAP_INAPP_SS_EVAL_META_KEY] = combinedEvaluatedIds;
        }
        
        // Combine suppressed IDs from both events and profiles
        NSMutableArray *combinedSuppressedIds = [NSMutableArray array];
        if ([self.suppressedClientSideInApps count] > 0) {
            [combinedSuppressedIds addObjectsFromArray:self.suppressedClientSideInApps];
        }
        if ([self.suppressedClientSideInAppsForProfile count] > 0) {
            [combinedSuppressedIds addObjectsFromArray:self.suppressedClientSideInAppsForProfile];
        }
        if ([combinedSuppressedIds count] > 0) {
            header[CLTAP_INAPP_SUPPRESSED_META_KEY] = combinedSuppressedIds;
        }
    }
    return header;
}

- (void)saveEvaluatedServerSideInAppIds {
    [CTPreferences putObject:self.evaluatedServerSideInAppIds forKey:[self storageKeyWithSuffix:CLTAP_INAPP_SS_EVAL_STORAGE_KEY]];
}

- (void)saveSuppressedClientSideInApps {
    [CTPreferences putObject:self.suppressedClientSideInApps forKey:[self storageKeyWithSuffix:CLTAP_INAPP_SUPPRESSED_STORAGE_KEY]];
}

- (void)saveEvaluatedServerSideInAppIdsForProfile {
    [CTPreferences putObject:self.evaluatedServerSideInAppIdsForProfile forKey:[self storageKeyWithSuffix:CLTAP_INAPP_SS_EVAL_STORAGE_KEY_PROFILE]];
}

- (void)saveSuppressedClientSideInAppsForProfile {
    [CTPreferences putObject:self.suppressedClientSideInAppsForProfile forKey:[self storageKeyWithSuffix:CLTAP_INAPP_SUPPRESSED_STORAGE_KEY_PROFILE]];
}

- (NSString *)storageKeyWithSuffix:(NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@:%@", self.accountId, suffix, self.deviceId];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@:%@:%@", self.class, self.accountId, self.deviceId];
}

@end

#import "CTInAppDelayManager.h"
#import "CTInAppTimer.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTInAppNotification.h"

@interface CTInAppDelayManager ()

@property (nonatomic, strong) CTDispatchQueueManager *dispatchQueue;
@property (nonatomic, strong) CTInAppStore *inAppStore;
@property (atomic, strong) CleverTapInstanceConfig *config;

@property (nonatomic, strong) NSMutableDictionary<NSString *, CTInAppTimer *> *activeTimers;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *pendingInApps;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *readyQueue; // Queue for ready in-apps
@property (nonatomic, assign) BOOL isPaused;
@property (nonatomic, assign) BOOL isProcessingQueue;
@end

@implementation CTInAppDelayManager

#pragma mark - Initialization
- (instancetype)initWithDispatchQueue:(CTDispatchQueueManager *)dispatchQueue inAppStore:(CTInAppStore *)inAppStore withConfig:(CleverTapInstanceConfig *)config {
    
    if (self = [super init]) {
        _dispatchQueue = dispatchQueue;
        _inAppStore = inAppStore;
        _config = config;
        _activeTimers = [NSMutableDictionary dictionary];
        _pendingInApps = [NSMutableDictionary dictionary];
        _scheduledCampaigns = [NSMutableSet set];
        _readyQueue = [NSMutableArray array];
        _isPaused = NO;
        _isProcessingQueue = NO;
        
        [self registerForNotifications];
    }
    return self;
}

- (void)dealloc {
    [self cancelAllDelayedInApps];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notification Observers

- (void)registerForNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                              name:UIApplicationDidEnterBackgroundNotification
                            object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillEnterForeground:)
                              name:UIApplicationWillEnterForegroundNotification
                            object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillTerminate:)
                              name:UIApplicationWillTerminateNotification
                            object:nil];
}

#pragma mark - Application Lifecycle

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    CleverTapLogInternal(self.config.logLevel, @"%@: App entering background, pausing all delayed in-app timers", self);
//    [self pauseAllTimers];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    CleverTapLogInternal(self.config.logLevel, @"%@: App entering foreground, resuming all delayed in-app timers", self);
//    [self resumeAllTimers];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    CleverTapLogInternal(self.config.logLevel, @"%@: App terminating, cancelling all delayed in-apps", self);
    [self cancelAllDelayedInApps];
}

#pragma mark - Timer Management

- (void)pauseAllTimers {
    @synchronized(self) {
        if (_isPaused) return;
        
        _isPaused = YES;
        for (NSString *campaignId in self.activeTimers) {
            CTInAppTimer *timer = self.activeTimers[campaignId];
            [timer pause];
            CleverTapLogDebug(self.config.logLevel, @"%@: Paused timer for campaign: %@", self, campaignId);
        }
    }
}

- (void)resumeAllTimers {
    @synchronized(self) {
        if (!_isPaused) return;
        
        _isPaused = NO;
        for (NSString *campaignId in self.activeTimers) {
            CTInAppTimer *timer = self.activeTimers[campaignId];
            [timer resume];
            CleverTapLogDebug(self.config.logLevel, @"%@: Resumed timer for campaign: %@", self, campaignId);
        }
    }
}

#pragma mark - Scheduling

- (void)scheduleDelayedInApp:(NSDictionary *)inApp {
    if (!inApp) return;
    
    NSString *campaignId = [CTInAppNotification inAppId:inApp];
    if (!campaignId) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Campaign id not found", self);
        return;
    }
    NSInteger delaySeconds = [self.inAppStore parseDelayFromJson:inApp];
    @synchronized(self) {
        // Check for duplicate campaigns with same delay (optional)
        if ([self shouldPreventDuplicateScheduling:campaignId withDelay:delaySeconds]) {
            CleverTapLogDebug(self.config.logLevel, @"%@: Campaign %@ with delay %ld already scheduled, skipping duplicate", self, campaignId, (long)delaySeconds);
            return;
        }
        // Store the in-app for later
        self.pendingInApps[campaignId] = inApp;
        [self.scheduledCampaigns addObject:campaignId];
        
        // Create and start timer
        __weak typeof(self) weakSelf = self;
        CTInAppTimer *timer = [[CTInAppTimer alloc] initWithDelay:delaySeconds completion:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf handleTimerFired:campaignId];
            }
        }];
        self.activeTimers[campaignId] = timer;
        [timer start];
        CleverTapLogDebug(self.config.logLevel, @"%@: Scheduled campaign %@ with delay %ld seconds, priority %@", self, campaignId, (long)delaySeconds, inApp[CLTAP_INAPP_PRIORITY] ?: @1);
    }
}


- (void)scheduleMultipleDelayedInApps:(NSArray<NSDictionary *> *)inApps {
    if (!inApps || inApps.count == 0) return;
    
    CleverTapLogDebug(self.config.logLevel, @"%@: Preparing to schedule %lu delayed in-apps", self, (unsigned long)inApps.count);
    
    // Sort in-apps before scheduling
    NSArray *sortedInApps = [self sortInAppsForScheduling:inApps];
    
    // Schedule all in-apps (they will run in parallel with their respective timers)
    for (NSDictionary *inApp in sortedInApps) {
        [self scheduleDelayedInApp:inApp];
    }
}

//Helper method to prevent duplicate scheduling
- (BOOL)shouldPreventDuplicateScheduling:(NSString *)campaignId withDelay:(NSInteger)delay {
    for (NSString *uniqueKey in self.pendingInApps) {
        NSDictionary *existingInApp = self.pendingInApps[uniqueKey];
        NSString *existingCampaignId = [CTInAppNotification inAppId:existingInApp];
        if ([existingCampaignId isEqualToString:campaignId]) {
            CTInAppTimer *timer = self.activeTimers[uniqueKey];
            // Only prevent if the existing one has significant time remaining
            if (timer && timer.remainingTime > 1.0) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)handleTimerFired:(NSString *)uniqueKey {
    @synchronized(self) {
        NSDictionary *inApp = self.pendingInApps[uniqueKey];
        if (inApp) {
            [self.readyQueue addObject:inApp];
            CleverTapLogDebug(self.config.logLevel, @"%@: In-app %@ added to ready queue", self, uniqueKey);
            
            [self processReadyQueue];
        }
        // Cleanup
        [self.activeTimers removeObjectForKey:uniqueKey];
        [self.pendingInApps removeObjectForKey:uniqueKey];
        [self.scheduledCampaigns removeObject:uniqueKey];
    }
}

#pragma mark - Queue Processing

- (void)processReadyQueue {
    @synchronized(self) {
        if (self.isProcessingQueue || self.readyQueue.count == 0) {
            return;
        }
        self.isProcessingQueue = YES;
        // Process multiple in-apps based on configuration
        NSInteger maxParallelInApps = [self getMaxParallelInApps];
        NSMutableArray *inAppsToProcess = [NSMutableArray array];
        
        for (NSInteger i = 0; i < MIN(maxParallelInApps, self.readyQueue.count); i++) {
            [inAppsToProcess addObject:self.readyQueue[i]];
        }
        // Remove processed in-apps from queue
        [self.readyQueue removeObjectsInArray:inAppsToProcess];
        self.isProcessingQueue = NO;
        
        // Send ready in-apps to delegate
        for (NSDictionary *inApp in inAppsToProcess) {
            [self.delegate delayedInAppReady:inApp];
        }
        
        CleverTapLogDebug(self.config.logLevel, @"%@: Processed %lu in-apps, %lu remaining in queue",
                         self, (unsigned long)inAppsToProcess.count, (unsigned long)self.readyQueue.count);
    }
}

- (NSInteger)getMaxParallelInApps {
    //TODO: This needs to be configured based on requirements
    return 3;
}

- (NSArray *)sortInAppsForScheduling:(NSArray *)inApps {
    if (!inApps || inApps.count <= 1) return inApps;
    
    NSMutableArray *mutableInApps = [inApps mutableCopy];
    
    // Sort by multiple criteria
    [mutableInApps sortUsingComparator:^NSComparisonResult(NSDictionary *inApp1, NSDictionary *inApp2) {
        // First sort by priority (higher priority first)
        NSNumber *priority1 = inApp1[CLTAP_INAPP_PRIORITY] ?: @1;
        NSNumber *priority2 = inApp2[CLTAP_INAPP_PRIORITY] ?: @1;
        
        NSComparisonResult priorityComparison = [priority2 compare:priority1]; // Descending
        
        // Then sort by delay (shorter delays first to show important messages sooner)
        NSInteger delay1 = [self.inAppStore parseDelayFromJson:inApp1];
        NSInteger delay2 = [self.inAppStore parseDelayFromJson:inApp2];
        
        if (delay1 != delay2) {
            return [@(delay1) compare:@(delay2)]; // Ascending
        } else {
            return priorityComparison;
        }
    }];
    
    return [mutableInApps copy];
}

#pragma mark - Priority Selection

- (NSNumber *)getTimestamp:(NSDictionary *)inApp {
    id ti = inApp[CLTAP_INAPP_ID];
    if (ti && [ti isKindOfClass:[NSNumber class]]) {
        return ti;
    } else if (ti && [ti isKindOfClass:[NSString class]]) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        NSNumber *number = [formatter numberFromString:ti];
        if (number) return number;
    }
    return @([[NSDate date] timeIntervalSince1970]);
}

#pragma mark - Cancellation

- (void)cancelDelayedInApp:(NSString *)uniqueKey {
    if (!uniqueKey) return;
    
    @synchronized(self) {
        CTInAppTimer *timer = self.activeTimers[uniqueKey];
        if (timer) {
            [timer cancel];
            [self.activeTimers removeObjectForKey:uniqueKey];
            [self.pendingInApps removeObjectForKey:uniqueKey];
            [self.scheduledCampaigns removeObject:uniqueKey];
            
            CleverTapLogDebug(self.config.logLevel, @"%@: Cancelled delayed in-app: %@", self, uniqueKey);
            [self.delegate delayedInAppCancelled:uniqueKey];
        }
    }
}

- (void)cancelAllDelayedInApps {
    @synchronized(self) {
        NSArray *uniqueKeys = [self.activeTimers allKeys];
        for (NSString *uniqueKey in uniqueKeys) {
            [self cancelDelayedInApp:uniqueKey];
        }
        
        // Also clear ready queue
        [self.readyQueue removeAllObjects];
        
        CleverTapLogDebug(self.config.logLevel, @"%@: Cancelled all %lu delayed in-apps",
                         self, (unsigned long)uniqueKeys.count);
    }
}
@end

#import "CTInAppDelayManager.h"
#import "CTInAppTimer.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CTInAppNotification.h"
#import "CTUIUtils.h"

@interface CTTimerInfo : NSObject
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, assign) NSTimeInterval originalDelay;
@property (nonatomic, strong) NSDictionary *inAppData;
@end

@implementation CTTimerInfo
@end

@interface CTInAppDelayManager ()

@property (nonatomic, strong) CTDispatchQueueManager *dispatchQueue;
@property (nonatomic, strong) CTInAppStore *inAppStore;
@property (atomic, strong) CleverTapInstanceConfig *config;

@property (nonatomic, strong) NSMutableDictionary<NSString *, CTInAppTimer *> *activeTimers;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CTTimerInfo *> *timerInfoMap;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *readyQueue;
@property (nonatomic, strong) dispatch_queue_t timerQueue;

// State flags
@property (nonatomic, assign) BOOL isProcessingQueue;

@end

@implementation CTInAppDelayManager

#pragma mark - Initialization
- (instancetype)initWithDispatchQueue:(CTDispatchQueueManager *)dispatchQueue
                           inAppStore:(CTInAppStore *)inAppStore
                           withConfig:(CleverTapInstanceConfig *)config {
    
    if (self = [super init]) {
        _dispatchQueue = dispatchQueue;
        _inAppStore = inAppStore;
        _config = config;
        _activeTimers = [NSMutableDictionary dictionary];
        _timerInfoMap = [NSMutableDictionary dictionary];
        _scheduledCampaigns = [NSMutableSet set];
        _readyQueue = [NSMutableArray array];
        _isProcessingQueue = NO;
        _timerQueue = dispatch_queue_create("com.clevertap.timerQueue", DISPATCH_QUEUE_SERIAL);
        
        [self registerForNotifications];
    }
    return self;
}

- (void)dealloc {
    // Use sync to ensure cleanup completes before dealloc
    if (_timerQueue) {
        dispatch_sync(_timerQueue, ^{
            [self cancelAllDelayedInAppsInternal];
        });
    }
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
    [self onAppDidEnterBackground];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    CleverTapLogInternal(self.config.logLevel, @"%@: App entering foreground, checking and resuming timers", self);
    [self onAppWillEnterForeground];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    CleverTapLogInternal(self.config.logLevel, @"%@: App terminating, cancelling all delayed in-apps", self);
    [self cancelAllDelayedInApps];
}

#pragma mark - Timer Management

- (void)onAppDidEnterBackground {
    dispatch_async(self.timerQueue, ^{
        // Just pause all active timers - no saving needed since we track start time
        for (NSString *campaignId in self.activeTimers) {
            CTInAppTimer *timer = self.activeTimers[campaignId];
            [timer cancel];
            
            CTTimerInfo *info = self.timerInfoMap[campaignId];
            NSTimeInterval elapsedSoFar = [[NSDate date] timeIntervalSinceDate:info.startTime];
            NSTimeInterval remainingTime = info.originalDelay - elapsedSoFar;
            
            CleverTapLogDebug(self.config.logLevel, @"%@: Timer cancelled %@ - elapsed: %.1fs, remaining: %.1fs", self, campaignId, elapsedSoFar, MAX(0, remainingTime));
        }
    });
}

- (void)onAppWillEnterForeground {
    dispatch_async(self.timerQueue, ^{
        NSDate *now = [NSDate date];
        
        // Check if app was terminated (timers exist but no info)
        if (self.timerInfoMap.count == 0 && self.activeTimers.count > 0) {
            CleverTapLogInternal(self.config.logLevel,
                                 @"%@: App was terminated - timer states lost, clearing all", self);
            [self cancelAllDelayedInAppsInternal];
            return;
        }
        
        NSMutableArray *expiredCampaigns = [NSMutableArray array];
        NSMutableDictionary *campaignsToResume = [NSMutableDictionary dictionary];
        
        // Check each timer based on actual elapsed time since start
        for (NSString *campaignId in [self.timerInfoMap copy]) {
            CTTimerInfo *info = self.timerInfoMap[campaignId];
            
            // Calculate total elapsed time since timer was first started
            NSTimeInterval totalElapsed = [now timeIntervalSinceDate:info.startTime];
            
            if (totalElapsed >= info.originalDelay) {
                // Timer expired while app was in background
                [expiredCampaigns addObject:campaignId];
                
                CleverTapLogInternal(self.config.logLevel,
                                     @"%@: Timer %@ expired (elapsed: %.1fs >= delay: %.1fs) - discarding",
                                     self, campaignId, totalElapsed, info.originalDelay);
            } else {
                // Timer still has time remaining
                NSTimeInterval remainingTime = info.originalDelay - totalElapsed;
                campaignsToResume[campaignId] = @(remainingTime);
                
                CleverTapLogDebug(self.config.logLevel,
                                  @"%@: Timer %@ still active - %.1fs remaining (elapsed: %.1fs of %.1fs)",
                                  self, campaignId, remainingTime, totalElapsed, info.originalDelay);
            }
        }
        
        // Remove expired timers
        for (NSString *campaignId in expiredCampaigns) {
            [self removeTimer:campaignId notifyDelegate:YES];
            [self.inAppStore dequeueDelayedInAppWithCampaignId:campaignId];
        }
        
        // Recreate active timers with correct remaining time
        for (NSString *campaignId in campaignsToResume) {
            NSTimeInterval remainingTime = [campaignsToResume[campaignId] doubleValue];
            
            // Cancel old timer if it exists
            CTInAppTimer *oldTimer = self.activeTimers[campaignId];
            if (oldTimer) {
                [oldTimer cancel];
            }
            
            // Create new timer with actual remaining time
            __weak typeof(self) weakSelf = self;
            CTInAppTimer *newTimer = [[CTInAppTimer alloc] initWithDelay:remainingTime
                                                              completion:^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                dispatch_async(strongSelf.timerQueue, ^{
                    [strongSelf handleTimerFired:campaignId];
                });
            }];
            
            self.activeTimers[campaignId] = newTimer;
            [newTimer start];
            
            CleverTapLogDebug(self.config.logLevel,
                              @"%@: Resumed timer %@ with %.1fs remaining",
                              self, campaignId, remainingTime);
        }
    });
}

- (void)notifyDelegateCancelled:(NSString *)campaignId {
    if (!self.delegate) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(delayedInAppCancelled:)]) {
                    [self.delegate delayedInAppCancelled:campaignId];
        }
    });
}

- (void)notifyDelegateReady:(NSDictionary *)inApp {
    if (!self.delegate) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(delayedInAppReady:)]) {
                    [self.delegate delayedInAppReady:inApp];
        }
    });
}

#pragma mark - Scheduling

- (void)scheduleDelayedInAppInternal:(NSDictionary *)inApp {
    if (!inApp) return;
    
    NSString *campaignId = inApp[CLTAP_NOTIFICATION_ID_TAG];
    if (!campaignId) {
        CleverTapLogDebug(self.config.logLevel, @"%@: Campaign id not found", self);
        return;
    }
    
    NSInteger delaySeconds = [self.inAppStore parseDelayFromJson:inApp];
    
    // Check if already scheduled
    if (self.timerInfoMap[campaignId]) {
        CTTimerInfo *existingInfo = self.timerInfoMap[campaignId];
        NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:existingInfo.startTime];
        NSTimeInterval remaining = existingInfo.originalDelay - elapsed;
        
        if (remaining > 1.0) {
            CleverTapLogDebug(self.config.logLevel,
                              @"%@: Campaign %@ already scheduled with %.1fs remaining, skipping",
                              self, campaignId, remaining);
            return;
        }
    }
    
    // Create timer info with just the essentials
    CTTimerInfo *info = [[CTTimerInfo alloc] init];
    info.startTime = [NSDate date];
    info.originalDelay = delaySeconds;
    info.inAppData = inApp;
    
    // Store timer info
    self.timerInfoMap[campaignId] = info;
    [self.scheduledCampaigns addObject:campaignId];
    
    // Create and start timer
    __weak typeof(self) weakSelf = self;
    CTInAppTimer *timer = [[CTInAppTimer alloc] initWithDelay:delaySeconds completion:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            dispatch_async(strongSelf.timerQueue, ^{
                [strongSelf handleTimerFired:campaignId];
            });
        }
    }];
    
    self.activeTimers[campaignId] = timer;
    [timer start];
    
    CleverTapLogDebug(self.config.logLevel,
                      @"%@: Scheduled campaign %@ with %ld second delay at %@",
                      self, campaignId, (long)delaySeconds, info.startTime);
}

- (void)scheduleDelayedInApps:(NSArray<NSDictionary *> *)inApps {
    if (!inApps || inApps.count == 0) return;
    
    CleverTapLogDebug(self.config.logLevel,
                      @"%@: Scheduling %lu delayed in-apps",
                      self, (unsigned long)inApps.count);
    
    // Sort by priority and delay
    NSArray *sortedInApps = [self sortInAppsForScheduling:inApps];
    
    // Schedule each in-app
    dispatch_async(self.timerQueue, ^{
        for (NSDictionary *inApp in sortedInApps) {
            [self scheduleDelayedInAppInternal:inApp];
        }
    });
}

#pragma mark - Timer Completion

- (void)handleInvalidTimer:(NSString *)campaignId info:(CTTimerInfo *)info {
    if (!info) {
        CleverTapLogDebug(self.config.logLevel,
                          @"%@: Timer fired but no info found for %@",
                          self, campaignId);
    } else {
        CleverTapLogDebug(self.config.logLevel,
                          @"%@: Timer %@ has no in-app data",
                          self, campaignId);
        [self removeTimer:campaignId notifyDelegate:YES];
        [self.inAppStore dequeueDelayedInAppWithCampaignId:campaignId];
    }
}

- (void)handleTimerFired:(NSString *)campaignId {
    CTTimerInfo *info = self.timerInfoMap[campaignId];
    if (!info || !info.inAppData) {
        [self handleInvalidTimer:campaignId info:info];
        return;
    }
    
    // Check if app is in foreground
    dispatch_async(dispatch_get_main_queue(), ^{
        UIApplicationState appState = [[CTUIUtils getSharedApplication] applicationState];
        
        if (appState == UIApplicationStateActive) {
            // App is in foreground, add to ready queue
            [self.readyQueue addObject:info.inAppData];
            
            CleverTapLogDebug(self.config.logLevel, @"Timer %@ completed - queueing for display (queue size: %lu)", campaignId, (unsigned long)self.readyQueue.count);
            
            [self processReadyQueue];
        } else {
            // App is in background, discard the in-app
            CleverTapLogDebug(self.config.logLevel,@"Timer %@ fired in background (state: %ld) - discarding", campaignId, (long)appState);
            
            [self notifyDelegateCancelled:campaignId];
        }
    });
    
    // Clean up
    [self removeTimer:campaignId notifyDelegate:NO];
}

#pragma mark - Queue Processing

- (void)processReadyQueue {
    if (self.isProcessingQueue || self.readyQueue.count == 0) {
        return;
    }
    
    self.isProcessingQueue = YES;
    
    // Process in-apps based on configuration
    NSInteger maxParallelInApps = CLTAP_MAX_DELAYED_INAPPS;
    NSMutableArray *inAppsToProcess = [NSMutableArray array];
    
    for (NSInteger i = 0; i < MIN(maxParallelInApps, self.readyQueue.count); i++) {
        [inAppsToProcess addObject:self.readyQueue[i]];
    }
    
    // Remove processed in-apps from queue
    [self.readyQueue removeObjectsInArray:inAppsToProcess];
    self.isProcessingQueue = NO;
    
    // Send ready in-apps to delegate
    for (NSDictionary *inApp in inAppsToProcess) {
        [self notifyDelegateReady:inApp];
    }
    
    CleverTapLogDebug(self.config.logLevel,
                      @"%@: Processed %lu in-apps, %lu remaining in queue",
                      self, (unsigned long)inAppsToProcess.count,
                      (unsigned long)self.readyQueue.count);
}

- (NSInteger)getMaxParallelInApps {
    // TODO: This needs to be configured based on requirements
    return 20;
}

#pragma mark - Helper Methods

- (void)removeTimer:(NSString *)campaignId notifyDelegate:(BOOL)notify {
    CTInAppTimer *timer = self.activeTimers[campaignId];
    if (timer) {
        [timer cancel];
    }
    
    [self.activeTimers removeObjectForKey:campaignId];
    [self.timerInfoMap removeObjectForKey:campaignId];
    [self.scheduledCampaigns removeObject:campaignId];
    
    if (notify) {
        [self notifyDelegateCancelled:campaignId];
    }
}

- (NSArray *)sortInAppsForScheduling:(NSArray *)inApps {
    if (!inApps || inApps.count <= 1) return inApps;
    
    NSMutableArray *mutableInApps = [inApps mutableCopy];
    
    [mutableInApps sortUsingComparator:^NSComparisonResult(NSDictionary *inApp1, NSDictionary *inApp2) {
        // Sort by priority first (higher priority first)
        NSNumber *priority1 = inApp1[CLTAP_INAPP_PRIORITY] ?: @1;
        NSNumber *priority2 = inApp2[CLTAP_INAPP_PRIORITY] ?: @1;
        
        NSComparisonResult priorityComparison = [priority2 compare:priority1];
        if (priorityComparison != NSOrderedSame) {
            return priorityComparison;
        }
        
        // Then by delay (shorter delays first)
        NSInteger delay1 = [self.inAppStore parseDelayFromJson:inApp1];
        NSInteger delay2 = [self.inAppStore parseDelayFromJson:inApp2];
        
        return [@(delay1) compare:@(delay2)];
    }];
    
    return [mutableInApps copy];
}

#pragma mark - Cancellation

- (void)cancelDelayedInApp:(NSString *)campaignId {
    if (!campaignId) return;
    
    dispatch_async(self.timerQueue, ^{
        [self removeTimer:campaignId notifyDelegate:YES];
        
        CleverTapLogDebug(self.config.logLevel,
                          @"%@: Cancelled delayed in-app: %@",
                          self, campaignId);
    });
}

- (void)cancelAllDelayedInApps {
    dispatch_async(self.timerQueue, ^{
        [self cancelAllDelayedInAppsInternal];
    });
}

- (void)cancelAllDelayedInAppsInternal {
    NSArray *campaignIds = [self.timerInfoMap allKeys];
    
    for (NSString *campaignId in campaignIds) {
        [self removeTimer:campaignId notifyDelegate:YES];
    }
    
    [self.readyQueue removeAllObjects];
    
    CleverTapLogDebug(self.config.logLevel,
                      @"%@: Cancelled all %lu delayed in-apps",
                      self, (unsigned long)campaignIds.count);
}
@end

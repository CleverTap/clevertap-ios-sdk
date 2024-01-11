//
//  CTSessionManager.m
//  CleverTapSDK
//
//  Created by Akash Malhotra on 12/10/23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTSessionManager.h"
#import "CTUIUtils.h"
#import "CTPreferences.h"
#import "CTValidator.h"
#import "CleverTapInstanceConfigPrivate.h"
#import "CTConstants.h"
#import "CleverTapInternal.h"

@interface CTSessionManager()
@property (nonatomic, strong) CleverTapInstanceConfig *config;
#if !CLEVERTAP_NO_INAPP_SUPPORT
@property (nonatomic, strong) CTImpressionManager *impressionManager;
@property (nonatomic, strong) CTInAppStore *inAppStore;
#endif
@end

@implementation CTSessionManager
@synthesize sessionId=_sessionId;
@synthesize source=_source;
@synthesize medium=_medium;
@synthesize campaign=_campaign;
@synthesize wzrkParams=_wzrkParams;
@synthesize firstRequestInSession=_firstRequestInSession;

#if !CLEVERTAP_NO_INAPP_SUPPORT
- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config impressionManager:(CTImpressionManager *)impressionManager inAppStore:(CTInAppStore *)inAppStore {
    if ((self = [super init])) {
        self.minSessionSeconds =  CLTAP_SESSION_LENGTH_MINS * 60;
        self.config = config;
        self.impressionManager = impressionManager;
        self.inAppStore = inAppStore;
    }
    return self;
}
#endif

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config {
    if ((self = [super init])) {
        self.minSessionSeconds =  CLTAP_SESSION_LENGTH_MINS * 60;
        self.config = config;
    }
    return self;
}

- (void)createSessionIfNeeded {
    if ([CTUIUtils runningInsideAppExtension] || [self inCurrentSession]) {
        return;
    }
    [self resetSession];
    [self createSession];
}

- (void)updateSessionStateOnLaunch {
    if (![self inCurrentSession]) {
        [self resetSession];
        [self createSession];
        return;
    }
    CleverTapLogInternal(self.config.logLevel, @"%@: have current session: %lu", self, self.sessionId);
    long now = (long) [[NSDate date] timeIntervalSince1970];
    if (![self isSessionTimedOut:now]) {
        [self updateSessionTime:now];
        return;
    }
    CleverTapLogInternal(self.config.logLevel, @"%@: Session timeout reached", self);
    [self resetSession];
    [self createSession];
}

- (BOOL)inCurrentSession {
    return self.sessionId > 0;
}

- (BOOL)isSessionTimedOut:(long)currentTS {
    long lastSessionTime = [self lastSessionTime];
    return (lastSessionTime > 0 && (currentTS - lastSessionTime > self.minSessionSeconds));
}

- (long)lastSessionTime {
    return (long)[CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kLastSessionTime config: self.config] withResetValue:0];
}

- (void)updateSessionTime:(long)ts {
    if (![self inCurrentSession]) return;
    CleverTapLogInternal(self.config.logLevel, @"%@: updating session time: %lu", self, ts);
    [CTPreferences putInt:ts forKey:[CTPreferences storageKeyWithSuffix:kLastSessionTime config: self.config]];
}

- (void)createFirstRequestInSession {
    self.firstRequestInSession = YES;
    [CTValidator setDiscardedEvents:nil];
}

- (void)resetSession {
    if ([CTUIUtils runningInsideAppExtension]) return;
    self.appLaunchProcessed = NO;
    long lastSessionID = 0;
    long lastSessionEnd = 0;
    if (self.config.isDefaultInstance) {
        lastSessionID = [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kSessionId config: self.config] withResetValue:[CTPreferences getIntForKey:kSessionId withResetValue:0]];
        lastSessionEnd = [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kLastSessionTime config: self.config] withResetValue:[CTPreferences getIntForKey:kLastSessionPing withResetValue:0]];
    } else {
        lastSessionID = [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kSessionId config: self.config] withResetValue:0];
        lastSessionEnd = [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:kLastSessionTime config: self.config] withResetValue:0];
    }
    self.lastSessionLengthSeconds = (lastSessionID > 0 && lastSessionEnd > 0) ? (int)(lastSessionEnd - lastSessionID) : 0;
    self.sessionId = 0;
    [self updateSessionTime:0];
    [CTPreferences removeObjectForKey:kSessionId];
    [CTPreferences removeObjectForKey:[CTPreferences storageKeyWithSuffix:kSessionId config: self.config]];
    self.screenCount = 1;
    [self clearSource];
    [self clearMedium];
    [self clearCampaign];
    [self clearWzrkParams];
#if !CLEVERTAP_NO_INAPP_SUPPORT
    if (![CTUIUtils runningInsideAppExtension]) {
        [self.impressionManager resetSession];
    }
#endif
}

- (void)setSessionId:(long)sessionId {
    _sessionId = sessionId;
    [CTPreferences putInt:self.sessionId forKey:[CTPreferences storageKeyWithSuffix:kSessionId config: self.config]];
}

- (long)sessionId {
    return _sessionId;
}

- (void)createSession {
    self.sessionId = (long) [[NSDate date] timeIntervalSince1970];
    [self updateSessionTime:self.sessionId];
    [self createFirstRequestInSession];
    if (self.config.isDefaultInstance) {
        self.firstSession = [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:@"firstTime" config: self.config] withResetValue:[CTPreferences getIntForKey:@"firstTime" withResetValue:0]] == 0;
    } else {
        self.firstSession = [CTPreferences getIntForKey:[CTPreferences storageKeyWithSuffix:@"firstTime" config: self.config] withResetValue:0] == 0;
    }
    [CTPreferences putInt:1 forKey:[CTPreferences storageKeyWithSuffix:@"firstTime" config: self.config]];
    CleverTapLogInternal(self.config.logLevel, @"%@: session created with ID: %lu", self, self.sessionId);
    CleverTapLogInternal(self.config.logLevel, @"%@: previous session length: %d seconds", self, self.lastSessionLengthSeconds);
#if !CLEVERTAP_NO_INAPP_SUPPORT
    if (![CTUIUtils runningInsideAppExtension]) {
        [self.inAppStore clearInApps];
    }
#endif
}

- (void)setFirstRequestInSession:(BOOL)firstRequestInSession {
    _firstRequestInSession = firstRequestInSession;
}

- (BOOL)firstRequestInSession {
    return _firstRequestInSession;
}

- (NSString*)source {
    return _source;
}
// only set if not already set for this session
- (void)setSource:(NSString *)source {
    if (_source == nil) {
        _source = source;
    }
}
- (void)clearSource {
    _source = nil;
}

- (NSString*)medium{
    return _medium;
}
// only set them if not already set during the session
- (void)setMedium:(NSString *)medium {
    if (_medium == nil) {
        _medium = medium;
    }
}
- (void)clearMedium {
    _medium = nil;
}

- (NSString*)campaign {
    return _campaign;
}
// only set them if not already set during the session
- (void)setCampaign:(NSString *)campaign {
    if (_campaign == nil) {
        _campaign = campaign;
    }
}
- (void)clearCampaign {
    _campaign = nil;
}

- (NSDictionary*)wzrkParams{
    return _wzrkParams;
}
// only set them if not already set during the session
- (void)setWzrkParams:(NSDictionary *)params {
    if (_wzrkParams == nil) {
        _wzrkParams = params;
    }
}
- (void)clearWzrkParams {
    _wzrkParams = nil;
}

@end

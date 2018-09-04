#import <UIKit/UIKit.h>
#import "CTLocalDataStore.h"
#import "CTConstants.h"
#import "CTPreferences.h"
#import "CleverTapSyncDelegate.h"
#import "CleverTapEventDetail.h"
#import "CleverTapInstanceConfig.h"
#import "CleverTapInstanceConfigPrivate.h"

static const void *const kProfileBackgroundQueueKey = &kProfileBackgroundQueueKey;
static const double kProfilePersistenceIntervalSeconds = 30.f;
NSString* const kWR_KEY_EVENTS = @"local_events_cache";
NSString* const kLocalCacheLastSync = @"local_cache_last_sync";
NSString* const kLocalCacheExpiry = @"local_cache_expiry";

@interface CTLocalDataStore() {
    NSMutableDictionary *localProfileUpdateExpiryStore;
    NSMutableDictionary *localProfileForSession;
    dispatch_queue_t _backgroundQueue;
    NSNumber *lastProfilePersistenceTime;
}

@property (nonatomic, strong) CleverTapInstanceConfig *config;

@end

@implementation CTLocalDataStore

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)config andProfileValues:(NSDictionary*)profileValues {
    if (self = [super init]) {
        _config = config;
        localProfileUpdateExpiryStore = [NSMutableDictionary new];
        _backgroundQueue = dispatch_queue_create([[NSString stringWithFormat:@"com.clevertap.profileBackgroundQueue:%@", _config.accountId] UTF8String], DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_backgroundQueue, kProfileBackgroundQueueKey, (__bridge void *)self, NULL);
        lastProfilePersistenceTime = 0;
        [self runOnBackgroundQueue:^{
            @synchronized (self->localProfileForSession) {
                self->localProfileForSession = [self _inflateLocalProfile];
                for (NSString* key in [profileValues allKeys]) {
                    [self setProfileFieldWithKey:key andValue:profileValues[key]];
                }
            }
        }];
        [self addObservers];
    }
    return self;
}
- (void)addObservers {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"CTLocalDataStore.%@", self.config.accountId];
}

- (NSString *)storageKeyWithSuffix: (NSString *)suffix {
    return [NSString stringWithFormat:@"%@:%@", self.config.accountId, suffix];
}

- (void)runOnBackgroundQueue:(void (^)(void))taskBlock {
    if ([self inBackgroundQueue]) {
        taskBlock();
    } else {
        dispatch_async(_backgroundQueue, taskBlock);
    }
}

- (BOOL)inBackgroundQueue {
    CTLocalDataStore *currentQueue = (__bridge id) dispatch_get_specific(kProfileBackgroundQueueKey);
    return currentQueue == self;
}

- (void)changeUser {
    localProfileUpdateExpiryStore = [NSMutableDictionary new];
    localProfileForSession = [NSMutableDictionary dictionary];
    // this will remove the old profile from the file system
    [self _persistLocalProfileAsync];
    [self clearStoredEvents];
}

#pragma mark - UIApplication State and Events

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self _persistLocalProfileAsync];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self _persistLocalProfileAsync];
}

/*!
 Adds the "dsync" flag, if required to the event
 */
- (void)addDataSyncFlag:(NSMutableDictionary *)event {
    if (!event) return;
    @try {
        // For App Launched events, force a dsync true
        NSString *eventType = event[@"type"];
        if ([@"event" isEqualToString:eventType] && [CLTAP_APP_LAUNCHED_EVENT isEqualToString:event[@"evtName"]]) {
            event[@"dsync"] = @YES;
            return;
        }
        if ([@"profile" isEqualToString:eventType]) {
            event[@"dsync"] = @YES;
            return;
        }
        const double now = [[[NSDate alloc] init] timeIntervalSince1970];
        long last = [self getLastDataSyncTimeWithResetValue:now];
        long expiry = [self getLocalCacheExpiryIntervalWithResetValue:20 * 60];
        if (now > last + expiry) {
            event[@"dsync"] = @YES;
            CleverTapLogInternal(self.config.logLevel, @"%@: Local data cache needs to be updated", self);
        } else {
            CleverTapLogInternal(self.config.logLevel, @"%@: Local data cache doesn't need to be updated", self);
        }
    } @catch (NSException *e) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Failed to add the data sync flag: %@",self, e.debugDescription);
    }
}

# pragma mark events

- (NSDictionary *)getStoredEvents {
    NSDictionary *events = [CTPreferences getObjectForKey:[self storageKeyWithSuffix:kWR_KEY_EVENTS]];
    if (self.config.isDefaultInstance) {
        if (!events) {
            events = [CTPreferences getObjectForKey:kWR_KEY_EVENTS];
            if (events) {
                [CTPreferences removeObjectForKey:kWR_KEY_EVENTS];
                [self setStoredEvents:events];
            }
        }
    }
    return events;
}

- (void)setStoredEvents:(NSDictionary *)store {
    [CTPreferences putObject:store forKey:[self storageKeyWithSuffix:kWR_KEY_EVENTS]];
}

- (void)clearStoredEvents {
    [CTPreferences removeObjectForKey:[self storageKeyWithSuffix:kWR_KEY_EVENTS]];
}

/*!
 *!
 Updates the local data for this event.
 If this is the very first time it's being recorded, then it will create a new entry,
 and set the occurrences to 1, last and first to now.
 
 If an entry already exists, it will increment the occurrences by 1,
 and set the last time to now.
 */
- (void)persistEvent:(NSDictionary *)event  {
    if (!event || !event[@"evtName"]) return;
    [self runOnBackgroundQueue:^{
        NSString *eventName = event[@"evtName"];
        NSDictionary *s = [self getStoredEvents];
        if (!s) s = @{};
        NSTimeInterval now = [[[NSDate alloc] init] timeIntervalSince1970];
        NSArray *ed = s[eventName];
        if (!ed || ed.count < 3) {
            // This event has been recorded for the very first time
            // Set the count to 0, first and last to now
            // Count will be incremented soon after this block
            ed = @[@0.0f, @(now), @(now)];
        }
        NSMutableArray *ped = [ed mutableCopy];
        double currentCount = ((NSNumber *) ped[0]).doubleValue;
        currentCount++;
        ped[0] = @(currentCount);
        ped[2] = @(now);
        NSMutableDictionary *store = [s mutableCopy];
        store[eventName] = ped;
        [self setStoredEvents:store];
    }];
}

/*!
 Performs a sanity check while updating the local copy of events.
 If an event doesn't exist in the local cache, then whatever comes from upstream will
 be set for it.
 
 However, if the event does exist locally, then it checks the occurrence count.
 If found to be greater, it will replace the local copy with that of upstream.
 */

- (NSDictionary *)syncEventCacheFromUpstream:(NSDictionary *)events {
    @try {
        NSMutableDictionary *changes;
        
        NSDictionary *s = [self getStoredEvents];
        if (!s) s = @{};
        
        NSMutableDictionary *store = [s mutableCopy];
        
        for (NSString *eventName in [events keyEnumerator]) {
            BOOL evDidUpdate = NO;
            NSArray *ed = store[eventName];
            
            NSArray *upstreamEvent = events[eventName];
            
            if (!ed) {
                // Blindly set this data in the store
                // Further validation is unnecessary
                store[eventName] = upstreamEvent;
                CleverTapLogInternal(self.config.logLevel, @"%@: Upstream event sync - Event \"%@\" not available locally. Trusting upstream", self, eventName);
                evDidUpdate = YES;
            } else {
                // There exists a local copy of this event
                // Only if the occurrences is greater than the local copy, update the entire copy
                NSNumber *upstreamOccurrences = upstreamEvent[0];
                NSNumber *localOccurrences = ed[0];
                
                if (upstreamOccurrences.intValue > localOccurrences.intValue) {
                    store[eventName] = upstreamEvent;
                    CleverTapLogInternal(self.config.logLevel, @"%@: Upstream event sync - Event \"%@\" has updated details. Trusting upstream", self, eventName);
                    evDidUpdate = YES;
                } else {
                    CleverTapLogInternal(self.config.logLevel, @"%@: Upstream event sync - Event \"%@\" has been rejected from upstream", self, eventName);
                }
            }
            if (evDidUpdate) {
                
                if (!changes) {
                    changes = [NSMutableDictionary new];
                }
                @try {
                    NSDictionary *evChanged = @{
                                                @"count" : @{@"oldValue" : @([ed[0] intValue]),
                                                             @"newValue" : @([upstreamEvent[0] intValue])
                                                             },
                                                
                                                @"firstTime" : @{@"oldValue" : @([ed[1] doubleValue]),
                                                                 @"newValue" : @([upstreamEvent[1] doubleValue])
                                                                 },
                                                
                                                @"lastTime" : @{@"oldValue" : @([ed[2] doubleValue]),
                                                                @"newValue" : @([upstreamEvent[2] doubleValue])
                                                                },
                                                
                                                };
                    changes[eventName] = evChanged;
                }
                @catch (NSException *e) {
                    CleverTapLogInternal(self.config.logLevel, @"Failed to set event changes for event: %@ for reason: %@", eventName, [e reason]);
                    continue;
                }
                
            }
        }
        
        [self setStoredEvents:store];
        return changes;
    } @catch (NSException *e) {
        return @{};
    }
}


/*!
 Sync's the remote profile with local profile and returns a changed values dict
 */
- (NSDictionary *)syncProfile:(NSDictionary *)remoteProfile {
    
    if (!remoteProfile || [remoteProfile count] <= 0) return @{};
    
    NSMutableDictionary *changes = [NSMutableDictionary new];
    
    @try {
        
        // will hold the updated fields that need to be written to the local profile
        NSMutableDictionary *fieldsToUpdateLocally = [NSMutableDictionary new];
        
        // cache the current date/time for the shouldPreferLocalUpdateForKey: forDate: check
        NSDate *now = [NSDate date];
        
        // walk the remote profile and compare values against the local profile values
        // prefer the remote profile value unless we have set a still-valid expiration time for the local profile value
        
        NSArray *keys = [remoteProfile allKeys];
        
        for (NSString *key in keys) {
            @try {
                
                if ([self shouldPreferLocalProfileUpdateForKey:key forDate:now]) {
                    CleverTapLogInternal(self.config.logLevel, @"%@: Rejecting update for key:%@ in favor of locally updated value", self, key);
                    continue;
                }
                
                id localValue = [self getProfileFieldForKey:key];
                
                id remoteValue = remoteProfile[key];
                
                // if the remote value is empty (empty string or array) consider it removed and nil it out
                if ([CTLocalDataStore profileValueIsEmpty:remoteValue]) {
                    remoteValue = nil;
                }
                
                // this test handles nil values
                if (![[self class] profileValue:remoteValue isEqualToProfileValue:localValue]) {
                    // Update required as we prefer the remote value once we've passed the local expiration time check
                    
                    // add the new value to be written to the local profile (or if nil remove)
                    if (remoteValue) {
                        fieldsToUpdateLocally[key] = remoteValue;
                        
                    } else {
                        // value is nil so send a remove to the local profile
                        [self removeProfileFieldForKey:key];
                    }
                    
                    // add the changed values to the dictionary to be returned
                    // nil values are handled
                    NSDictionary *changedValues = [[self class] buildChangeFromOldValue:localValue toNewValue:remoteValue];
                    if(changedValues) {
                        changes[key] = changedValues;
                    }
                }
                
            } @catch (NSException *e) {
                // Ignore
            }
        }
        
        // save the changed fields locally
        if ([fieldsToUpdateLocally count] > 0) {
            [self setProfileFields:fieldsToUpdateLocally fromUpstream:YES];
        }
        
        return changes;
        
    } @catch (NSException *e) {
        CleverTapLogDebug(self.config.logLevel, @"Failed to persist profile: %@", [e reason]);
        return @{};
    }
}

/*!
 Updates the local cache state if new data is available in the response
 */

- (NSDictionary*)syncWithRemoteData:(NSDictionary *)responseData {
    if (!responseData) return nil;
    @try {
        NSDictionary *eventChanges;
        NSDictionary *profileChanges;
        
        BOOL somethingGotUpdated = false;
        
        NSDictionary *p = responseData[@"profile"];
        
        // Sync up the profile
        if (p) {
            NSMutableDictionary *profile = [p mutableCopy];
            NSDictionary *custom = profile[@"_custom"];
            [profile removeObjectForKey:@"_custom"];
            if (custom) {
                [profile addEntriesFromDictionary:custom];
            }
            profileChanges = [self syncProfile:profile];
            if (profileChanges && [profileChanges count] > 0) {
                somethingGotUpdated = YES;
            } else {
                profileChanges = nil;
            }
        }
        
        // Sync up events
        NSDictionary *events = responseData[@"events"];
        if (events) {
            
            eventChanges = [self syncEventCacheFromUpstream:events];
            if (eventChanges && [eventChanges count] > 0) {
                somethingGotUpdated = YES;
            } else {
                eventChanges = nil;
            }
        }
        int now = @([[[NSDate alloc] init] timeIntervalSince1970]).intValue;
        [self setLastDataSyncTime:now];
        NSNumber *expiry = responseData[@"expires_in"];
        if (expiry) {
            [self setLocalCacheExpiryInterval:expiry.intValue];
        }
        if (somethingGotUpdated) {
            @try {
                NSMutableDictionary *updates = [NSMutableDictionary new];
                if (profileChanges) {
                    updates[@"profile"] = profileChanges;
                }
                if (eventChanges) {
                    updates[@"events"] = eventChanges;
                }
                return updates;
            } @catch (NSException *e) {
                CleverTapLogInternal(self.config.logLevel, @"%@: Failed to process profile updates: %@",self, e.debugDescription);
                return nil;
            }
        }
    } @catch (NSException *e) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Failed to process data sync from upstream: %@", self, e.debugDescription);
        return nil;
    }
}


#pragma mark Public API

- (NSTimeInterval)getFirstTimeForEvent:(NSString *)event {
    return [self getEventDetail:event withIndex:1];
}

- (NSTimeInterval)getLastTimeForEvent:(NSString *)event {
    return [self getEventDetail:event withIndex:2];
}

- (int)getOccurrencesForEvent:(NSString *)event {
    return (int) [self getEventDetail:event withIndex:0];
}

- (double)getEventDetail:(NSString *)event withIndex:(int)index {
    @try {
        NSDictionary *s = [self getStoredEvents];
        if (!s) {
            return -1;
        }
        // The storage structure looks like this: [count, first, last]
        NSArray *e = s[event];
        if (!e || e.count != 3) return -1;
        
        return [((NSNumber *) e[(NSUInteger) index]) doubleValue];
        
    } @catch (NSException *e) {
        return -1;
    }
}

- (CleverTapEventDetail *)getEventDetail:(NSString *)event {
    @try {
        
        NSDictionary *s = [self getStoredEvents];
        if (!s) {
            return nil;
        }
        // The storage structure looks like this: [count, first, last]
        NSArray *e = s[event];
        if (!e || e.count != 3) return nil;
        CleverTapEventDetail *ed = [[CleverTapEventDetail alloc] init];
        ed.count = [((NSNumber *) e[0]) intValue];
        ed.firstTime = [((NSNumber *) e[1]) doubleValue];
        ed.lastTime = [((NSNumber *) e[2]) doubleValue];
        ed.eventName = event;
        return ed;
    } @catch (NSException *e) {
        return nil;
    }
}

- (NSDictionary *)getEventHistory {
    @try {
        NSDictionary *s = [self getStoredEvents];
        if (!s) {
            return @{};
        }
        NSMutableDictionary *history = [[NSMutableDictionary alloc] init];
        for (NSString *eventName in [s keyEnumerator]) {
            NSArray *details = s[eventName];
            if (!details || details.count != 3) continue;
            
            CleverTapEventDetail *ev = [[CleverTapEventDetail alloc] init];
            ev.eventName = eventName;
            ev.firstTime = ((NSNumber *) details[1]).intValue;
            ev.lastTime = ((NSNumber *) details[2]).intValue;
            ev.count = ((NSNumber *) details[0]).intValue;
            history[eventName] = ev;
        }
        return history;
    } @catch (NSException *e) {
        return nil;
    }
}

- (id)getProfileFieldForKey:(NSString *)key {
    @try {
        return [self _getProfileFieldFromSessionCacheWithKey:key];
        
    } @catch (NSException *e) {
        return nil;
    }
}

- (void)setProfileFields:(NSDictionary *)fields {
    [self setProfileFields:fields fromUpstream:NO];
}

- (void)setProfileFieldWithKey:(NSString *)key andValue:(id)value {
    [self setProfileFieldWithKey:key andValue:value fromUpstream:NO];
}

- (void)removeProfileFieldForKey:(NSString *)key {
    [self removeProfileFieldForKey:key fromUpstream:NO];
}

- (void)removeProfileFieldsWithKeys:(NSArray *)keys {
    [self removeProfileFieldsWithKeys:keys fromUpstream:NO];
}

#pragma mark Private Local Profile Getters and Setters and disk persistence handling

// local profile is written to the file system on app backgrounding, app termination and on changes after a 30 second interval

- (void)setProfileFieldWithKey:(NSString *)key andValue:(id)value fromUpstream:(BOOL)fromUpstream {
    if (!key || !value) return;
    
    [self setProfileFields:@{key : value} fromUpstream:fromUpstream];
}

- (void)setProfileFields:(NSDictionary *)fields fromUpstream:(BOOL)fromUpstream {
    
    if(!fields) return ;
    
    for (NSString *key in fields) {
        id value = fields[key];
        if (!value) continue;
        
        [self _setProfileValue:fields[key] forKey:key fromUpstream:fromUpstream];
    }
    
    [self persistLocalProfileIfRequired];
}

- (void)_setProfileValue:(id)value forKey:(NSString *)key fromUpstream:(BOOL)fromUpstream {
    @try {
        @synchronized (localProfileForSession) {
            localProfileForSession[key] = value;
        }
        if (!fromUpstream) {
            [self updateLocalProfileUpdateExpiryTimeForKey:key];
        }
    }
    @catch (NSException *exception) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Exception setting profile field %@ in session cache for value %@", self, key, value);
    }
}

- (void)removeProfileFieldForKey:(NSString *)key fromUpstream:(BOOL)fromUpstream {
    if (!key) return;
    [self removeProfileFieldsWithKeys:@[key] fromUpstream:fromUpstream];
}

- (void)removeProfileFieldsWithKeys:(NSArray *)keys fromUpstream:(BOOL)fromUpstream {
    if(!keys) return;
    for (NSString *key in keys) {
        [self _removeProfileValueForKey:key fromUpstream:fromUpstream];
    }
    [self persistLocalProfileIfRequired];
}

- (void)_removeProfileValueForKey:(NSString *)key fromUpstream:(BOOL)fromUpstream {
    
    @try {
        @synchronized (localProfileForSession) {
            [localProfileForSession removeObjectForKey:key];
        }
        
        // if a local change, still add the key to the expiry store so that a premature sync won't restore the key
        if (!fromUpstream) {
            [self updateLocalProfileUpdateExpiryTimeForKey:key];
        }
    }
    @catch (NSException *exception) {
        CleverTapLogInternal(self.config.logLevel, @"%@: Exception removing profile field %@ in session cache", self, key);
    }
    
}

- (id)_getProfileFieldFromSessionCacheWithKey:(NSString *)key {
    if (!key || !localProfileForSession) return nil;
    
    id val = nil;
    
    @synchronized (localProfileForSession) {
        val = localProfileForSession[key];
    }
    
    return val;
}

- (NSString *)profileFileName {
    return [NSString stringWithFormat:@"clevertap-%@-userprofile.plist", self.config.accountId];
}

- (NSMutableDictionary *)_inflateLocalProfile {
    NSMutableDictionary *_profile = (NSMutableDictionary *)[CTPreferences unarchiveFromFile:[self profileFileName] removeFile:NO];
    if (!_profile) {
        _profile = [NSMutableDictionary dictionary];
    }
    return _profile;
}

- (void)persistLocalProfileIfRequired {
    BOOL shouldPersist = NO;
    double now = [[[NSDate alloc] init] timeIntervalSince1970];
    @synchronized (lastProfilePersistenceTime) {
        if (now > (lastProfilePersistenceTime.doubleValue + kProfilePersistenceIntervalSeconds)) {
            shouldPersist = YES;
        }
    }
    if (shouldPersist) {
        [self _persistLocalProfileAsync];
    }
}

- (void)_persistLocalProfileAsync {
    [self runOnBackgroundQueue:^{
        NSMutableDictionary *_profile;
        
        @synchronized (self->localProfileForSession) {
            _profile = [NSMutableDictionary dictionaryWithDictionary:[self->localProfileForSession copy]];
        }
        
        if (!_profile) return;
        
        @synchronized (self->lastProfilePersistenceTime) {
            self->lastProfilePersistenceTime = @([[[NSDate alloc] init] timeIntervalSince1970]);
        }
        
        [CTPreferences archiveObject:_profile forFileName:[self profileFileName]];
    }];
}

#pragma mark Private Local Profile Update Precedence Bookkeeping and Handling


// checks whether we have a local update expiration time and its greater than the specified time (or now as default)
// if so we prefer the local update to a remote update of the specified key

- (BOOL)shouldPreferLocalProfileUpdateForKey:(NSString *)key forDate:(NSDate *)date {
    
    date = date ? date :[[NSDate alloc] init];
    double time = [date timeIntervalSince1970];
    
    double localKeyValidityTime = [self getLocalProfileUpdateExpiryTimeForKey:key];
    
    return (localKeyValidityTime && localKeyValidityTime > time);
}

- (void)updateLocalProfileUpdateExpiryTimeForKey:(NSString *)key {
    if (!key) return;
    
    @synchronized (localProfileUpdateExpiryStore) {
        localProfileUpdateExpiryStore[key] = @([self calculateLocalKeyValidityTime]);
    }
}

- (double)getLocalProfileUpdateExpiryTimeForKey:(NSString *)key {
    double time = 0;
    
    if (key) {
        @synchronized (localProfileUpdateExpiryStore) {
            time = [localProfileUpdateExpiryStore[key] doubleValue];
        }
    }
    
    return time;
}

- (void)setLocalCacheExpiryInterval:(int)interval {
    [CTPreferences putInt:interval forKey:[self storageKeyWithSuffix:kLocalCacheExpiry]];
}

- (long)getLocalCacheExpiryIntervalWithResetValue:(int)resetValue {
    if (self.config.isDefaultInstance) {
         return  [CTPreferences getIntForKey:[self storageKeyWithSuffix:kLocalCacheExpiry] withResetValue:[CTPreferences getIntForKey:kLocalCacheExpiry withResetValue:resetValue]];
    } else {
         return [CTPreferences getIntForKey:[self storageKeyWithSuffix:kLocalCacheExpiry] withResetValue:resetValue];
    }
}

- (double)calculateLocalKeyValidityTime {
    long expiry = [self getLocalCacheExpiryIntervalWithResetValue:0];
    double now = [[[NSDate alloc] init] timeIntervalSince1970];
    double localKeysValidUntil = now + expiry;
    return localKeysValidUntil;
}

- (long)getLastDataSyncTimeWithResetValue:(long)resetValue {
    if (self.config.isDefaultInstance) {
        return [CTPreferences getIntForKey:[self storageKeyWithSuffix:kLocalCacheLastSync] withResetValue:[CTPreferences getIntForKey:kLocalCacheLastSync withResetValue:resetValue]];
    } else {
        return [CTPreferences getIntForKey:[self storageKeyWithSuffix:kLocalCacheLastSync] withResetValue:resetValue];
    }
}

- (void)setLastDataSyncTime:(long)time {
    [CTPreferences putInt:time forKey:[self storageKeyWithSuffix:kLocalCacheLastSync]];
}

# pragma mark helpers

+ (NSDictionary *)buildChangeFromOldValue:(id)oldValue toNewValue:(id)newValue {
    if (!newValue && !oldValue) return nil;
    
    NSMutableDictionary *_values = [NSMutableDictionary new];
    
    // if newValue is nil it means its been removed; represent that as -1
    _values[@"newValue"] = (newValue != nil) ? newValue : @(-1);
    
    if(oldValue) {
        _values[@"oldValue"] = oldValue;
    }
    
    return _values;
}

+ (BOOL)profileValueIsEmpty:(id)value {
    if (!value) return YES;
    BOOL isEmpty = NO;
    if ([value isKindOfClass:[NSString class]]) {
        NSString *_val = (NSString *)value;
        
        isEmpty = [[_val stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]] length] <= 0;
    }
    if ([value isKindOfClass:[NSArray class]]) {
        NSArray *_val = (NSArray *)value;
        
        isEmpty = [_val count] <= 0;
    }
    return isEmpty;
}

+ (BOOL)profileValue:(id)value1 isEqualToProfileValue:(id)value2 {
    
    // convert to strings (nil converts to empty string) and do a string comparison
    // nil values are handled in stringify
    NSString *stringValue1 = [[self class] stringifyValue:value1];
    NSString *stringValue2 = [[self class]  stringifyValue:value2];
    return [stringValue1 isEqualToString:stringValue2];
}

+ (NSString *)stringifyValue:(id)value {
    return (!value) ? @"" : [NSString stringWithFormat:@"%@", value];
}

- (void)addPropertyFromStoreIfExists:(NSString *)profileKey
                             profile:(NSMutableDictionary *)profile
                         storageKeys:(NSArray *)storageKeys {
    for (NSString *key in storageKeys) {
        id object = [self getProfileFieldForKey:key];
        if (!object) continue;
        profile[profileKey] = object;
        break;
    }
}

- (NSDictionary*)generateBaseProfile {
    NSMutableDictionary *profile = [NSMutableDictionary new];
    [self addPropertyFromStoreIfExists:@"Name" profile:profile storageKeys:@[CLTAP_USER_NAME, CLTAP_FB_NAME, CLTAP_GP_NAME]];
    [self addPropertyFromStoreIfExists:@"Gender" profile:profile storageKeys:@[CLTAP_USER_GENDER, CLTAP_FB_GENDER, CLTAP_GP_GENDER]];
    [self addPropertyFromStoreIfExists:@"Education" profile:profile storageKeys:@[CLTAP_USER_EDUCATION, CLTAP_FB_EDUCATION]];
    [self addPropertyFromStoreIfExists:@"Employed" profile:profile storageKeys:@[CLTAP_USER_EMPLOYED, CLTAP_FB_EMPLOYED, CLTAP_GP_EMPLOYED]];
    [self addPropertyFromStoreIfExists:@"Married" profile:profile storageKeys:@[CLTAP_USER_MARRIED, CLTAP_FB_MARRIED, CLTAP_GP_MARRIED]];
    [self addPropertyFromStoreIfExists:@"DOB" profile:profile storageKeys:@[CLTAP_USER_DOB, CLTAP_FB_DOB, CLTAP_GP_DOB]];
    [self addPropertyFromStoreIfExists:@"Birthday" profile:profile storageKeys:@[CLTAP_USER_BIRTHDAY]];
    [self addPropertyFromStoreIfExists:@"FBID" profile:profile storageKeys:@[CLTAP_FB_ID]];
    [self addPropertyFromStoreIfExists:@"GPID" profile:profile storageKeys:@[CLTAP_GP_ID]];
    [self addPropertyFromStoreIfExists:@"Phone" profile:profile storageKeys:@[CLTAP_USER_PHONE]];
    [self addPropertyFromStoreIfExists:@"Age" profile:profile storageKeys:@[CLTAP_USER_AGE]];
    [self addPropertyFromStoreIfExists:@"Email" profile:profile storageKeys:@[CLTAP_USER_EMAIL, CLTAP_FB_EMAIL]];
    [self addPropertyFromStoreIfExists:@"tz" profile:profile storageKeys:@[CLTAP_SYS_TZ]];
    [self addPropertyFromStoreIfExists:@"Carrier" profile:profile storageKeys:@[CLTAP_SYS_CARRIER]];
    [self addPropertyFromStoreIfExists:@"cc" profile:profile storageKeys:@[CLTAP_SYS_CC]];
    return profile;
}

@end

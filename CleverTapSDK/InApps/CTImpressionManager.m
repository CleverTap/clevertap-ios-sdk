//
//  CTImpressionManager.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 18.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTImpressionManager.h"
#import "CTPreferences.h"
#import "CleverTapInternal.h"
#import "CTSystemClock.h"

@interface CTImpressionManager()

@property (nonatomic, strong) NSString *accountId;
@property (nonatomic, strong) NSString *deviceId;

@property (nonatomic, strong) NSMutableDictionary *sessionImpressions;
@property (nonatomic, strong) NSMutableDictionary *impressions;
@property (nonatomic, assign) int sessionImpressionsTotal;

@property (nonatomic, strong) NSLocale *locale;
@property (nonatomic, strong) id <CTClock> clock;

@end

@implementation CTImpressionManager

- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId
                  delegateManager:(CTMultiDelegateManager *)delegateManager {
    if (self = [super init]) {
        return [self initWithAccountId:accountId
                              deviceId:deviceId
                       delegateManager:delegateManager
                                 clock:[[CTSystemClock alloc] init]
                                locale:[NSLocale currentLocale]];
    }
    return self;
}

- (instancetype)initWithAccountId:(NSString *)accountId
                         deviceId:(NSString *)deviceId
                  delegateManager:(CTMultiDelegateManager *)delegateManager
                            clock:(id <CTClock>)clock
                           locale:(NSLocale *)locale {
    if (self = [super init]) {
        self.accountId = accountId;
        self.deviceId = deviceId;
        
        self.clock = clock;
        self.locale = locale;
        
        self.sessionImpressions = [NSMutableDictionary new];
        self.impressions = [NSMutableDictionary new];
        self.sessionImpressionsTotal = 0;
        
        [delegateManager addSwitchUserDelegate:self];
    }
    return self;
}

#pragma mark Manage Impressions
- (void)recordImpression:(NSString *)campaignId {
    if (![campaignId isKindOfClass:[NSString class]] || [campaignId length] == 0) {
        return;
    }
    
    self.sessionImpressionsTotal++;
    // Record session impressions
    @synchronized (self.sessionImpressions) {
        int existing = [self.sessionImpressions[campaignId] intValue];
        existing++;
        self.sessionImpressions[campaignId] = @(existing);
    }
    
    NSNumber *now = [self.clock timeIntervalSince1970];
    [self addImpression:campaignId timestamp:now];
}

- (NSInteger)perSessionTotal {
    return self.sessionImpressionsTotal;
}

- (NSInteger)perSession:(NSString *)campaignId {
    @synchronized (self.sessionImpressions) {
        return [self.sessionImpressions[campaignId] intValue];
    }
}

- (NSInteger)perSecond:(NSString *)campaignId seconds:(NSInteger)seconds {
    NSNumber *now = [self.clock timeIntervalSince1970];
    NSInteger timestampStart = [now integerValue] - seconds;
    return [self getImpressionCount:campaignId timestampStart:timestampStart];
}

- (NSInteger)perMinute:(NSString *)campaignId minutes:(NSInteger)minutes {
    NSInteger now = [[self.clock timeIntervalSince1970] integerValue];
    NSInteger offsetSeconds = minutes * 60;
    return [self getImpressionCount:campaignId timestampStart:now - offsetSeconds];
}

- (NSInteger)perHour:(NSString *)campaignId hours:(NSInteger)hours {
    NSInteger now = [[self.clock timeIntervalSince1970] integerValue];
    NSInteger offsetSeconds = hours * 60 * 60;
    return [self getImpressionCount:campaignId timestampStart:now - offsetSeconds];
}

- (NSInteger)perDay:(NSString *)campaignId days:(NSInteger)days {
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setLocale:self.locale];

    NSDate *currentDate = [self.clock currentDate];
    
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:currentDate];
        [components setHour:0];
        [components setMinute:0];
        [components setSecond:0];
        [components setNanosecond:0];
        [components setDay:components.day - (days - 1)];

    NSDate *startOfDay = [calendar dateFromComponents:components];
    NSTimeInterval timestamp = [startOfDay timeIntervalSince1970];
    
    return [self getImpressionCount:campaignId timestampStart:(NSInteger)timestamp];
}

- (NSInteger)perWeek:(NSString *)campaignId weeks:(NSInteger)weeks {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setLocale:self.locale];
    
    // Get the first weekday based on the user's locale
    NSInteger firstWeekday = [calendar firstWeekday];
    
    NSDate *currentDate = [self.clock currentDate];
    
    // Subtract the number of weeks from the current date
    weeks -= 1; // Start from current week
    NSDate *startOfWeek = [calendar dateByAddingUnit:NSCalendarUnitWeekOfYear value:-weeks toDate:currentDate options:0];
    
    // Get the components of the start of the week
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitWeekOfYear fromDate:startOfWeek];
    
    // Correct the components to represent the start of the week
    NSInteger daysToSubtract = (components.weekday - firstWeekday + 7) % 7;
    components.day -= daysToSubtract;
    
    NSDate *startDate = [calendar dateFromComponents:components];
    NSTimeInterval timestamp = [startDate timeIntervalSince1970];
    
    return [self getImpressionCount:campaignId timestampStart:(NSInteger)timestamp];
}

- (NSInteger)getImpressionCount:(NSString *)campaignId {
    return [[self getImpressions:campaignId] count];
}

- (NSInteger)getImpressionCount:(NSString *)campaignId timestampStart:(NSInteger)timestampStart {
    NSMutableArray<NSNumber *> *timestamps = [self getImpressions:campaignId];
    NSInteger count = 0;

    NSEnumerator *enumerator = [timestamps reverseObjectEnumerator];
    for (NSNumber *timestamp in enumerator)
    {
        if (timestampStart > [timestamp longLongValue]) {
            break;
        }
        count++;
    }

    return count;
}

- (void)resetSession {
    [self setSessionImpressions:[NSMutableDictionary new]];
    self.sessionImpressionsTotal = 0;
}

#pragma mark Switch User Delegate
- (void)deviceIdDidChange:(NSString *)newDeviceId {
    self.deviceId = newDeviceId;
    [self resetSession];
    [self setImpressions:[NSMutableDictionary new]];
}

#pragma mark Store Impressions
- (NSMutableArray *)getImpressions:(NSString *)campaignId {
    NSMutableArray *campaignImpressions = self.impressions[campaignId];
    if (campaignImpressions) {
        return campaignImpressions;
    }

    NSArray *savedImpressions = [CTPreferences getObjectForKey:[self getImpressionKey:campaignId]];
    if (savedImpressions) {
        self.impressions[campaignId] = [savedImpressions mutableCopy];
    } else {
        self.impressions[campaignId] = [NSMutableArray new];
    }
    
    return self.impressions[campaignId];
}

- (void)addImpression:(NSString *)campaignId timestamp:(NSNumber *)timestamp {
    NSMutableArray *impressions = [self getImpressions:campaignId];
    if (!impressions) {
        impressions = [NSMutableArray new];
    }
    NSInteger val = [timestamp integerValue];
    [impressions addObject:[NSNumber numberWithLong:val]];
    [CTPreferences putObject:impressions forKey:[self getImpressionKey:campaignId]];
}

- (void)removeImpressions:(NSString *)campaignId {
    [self.impressions removeObjectForKey:campaignId];
    [CTPreferences removeObjectForKey:[self getImpressionKey:campaignId]];
}

- (NSString *)getImpressionKey:(NSString *)campaignId {
    return [NSString stringWithFormat:@"%@:%@:%@:%@", self.accountId, self.deviceId, @"impressions", campaignId];
}

@end

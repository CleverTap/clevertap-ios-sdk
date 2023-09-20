//
//  CTImpressionManager.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 18.08.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTImpressionManager.h"
#import "CTPreferences.h"

@interface CTImpressionManager()

@property (nonatomic, strong) NSMutableDictionary *sessionImpressions;
@property (nonatomic, strong) NSMutableDictionary *impressions;

@property NSLocale *locale;

@end

@implementation CTImpressionManager

- (id)init
{
    self = [self init:[NSLocale currentLocale]];
    return self;
}

- (id)init:(NSLocale *)locale
{
    if (self = [super init]) {
        _sessionImpressions = [NSMutableDictionary new];
        _impressions = [NSMutableDictionary new];
        _locale = locale;
    }
    return self;
}

- (void)recordImpression:(NSString *)campaignId {
    
    // Record session impressions
    @synchronized (self.sessionImpressions) {
        int existing = [self.sessionImpressions[campaignId] intValue];
        existing++;
        self.sessionImpressions[campaignId] = @(existing);
    }
    
    NSNumber *now = @([[NSDate date] timeIntervalSince1970]);
    [self addImpression:campaignId timestamp:now];
}

- (NSInteger)perSessionTotal {
    @synchronized (self.sessionImpressions) {
        return [self.sessionImpressions count];
    }
}

- (NSInteger)perSession:(NSString *)campaignId {
    @synchronized (self.sessionImpressions) {
        return [self.sessionImpressions[campaignId] intValue];
    }
}

- (NSInteger)perSecond:(NSString *)campaignId seconds:(NSInteger)seconds {
    NSNumber *now = @([[NSDate date] timeIntervalSince1970]);
    NSInteger timestampStart = [now integerValue] - seconds;
    return [self getImpressionCount:campaignId timestampStart:timestampStart];
}

- (NSInteger)perMinute:(NSString *)campaignId minutes:(NSInteger)minutes {
    NSInteger now = (NSInteger)[[NSDate date] timeIntervalSince1970];
    NSInteger offsetSeconds = minutes * 60;
    return [self getImpressionCount:campaignId timestampStart:now - offsetSeconds];
}

- (NSInteger)perHour:(NSString *)campaignId hours:(NSInteger)hours {
    NSInteger now = (NSInteger)[[NSDate date] timeIntervalSince1970];
    NSInteger offsetSeconds = hours * 60 * 60;
    return [self getImpressionCount:campaignId timestampStart:now - offsetSeconds];
}

- (NSInteger)perDay:(NSString *)campaignId days:(NSInteger)days {
    NSInteger now = (NSInteger)[[NSDate date] timeIntervalSince1970];
    // TODO: use Calendar?
//    NSInteger offsetSeconds = days * 24 * 60 * 60;
//    return [self getImpressionCount:campaignId timestampStart:now - offsetSeconds];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    calendar.locale = self.locale;
    
    NSDate *currentDate = [NSDate date];
    
    NSDateComponents *components = [calendar components:NSCalendarUnitDay fromDate:currentDate];
    components.day -= days;

    NSDate *startOfWeek = [calendar dateFromComponents:components];
    NSTimeInterval timestamp = [startOfWeek timeIntervalSince1970];
    
    return [self getImpressionCount:campaignId timestampStart:(NSInteger)timestamp];
}

- (NSInteger)perWeek:(NSString *)campaignId weeks:(NSInteger)weeks {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    calendar.locale = self.locale;
    
    // Get the first weekday based on the user's locale
    NSInteger firstWeekday = [calendar firstWeekday];
    
    NSDate *currentDate = [NSDate date];
    
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitWeekOfYear fromDate:currentDate];
    
    // Calculate the number of days to subtract to reach the starting day of the week
    NSInteger daysToSubtract = (components.weekday - firstWeekday + 7) % 7;
    
    components.day -= daysToSubtract;
    
    // Move back the number of weeks
    if (weeks > 1) {
        components.weekOfYear -= weeks;
    }
    
    NSDate *startOfWeek = [calendar dateFromComponents:components];
    NSTimeInterval timestamp = [startOfWeek timeIntervalSince1970];
    
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
    [impressions addObject:timestamp];
    [CTPreferences putObject:impressions forKey:[self getImpressionKey:campaignId]];
}

- (void)removeImpressions:(NSString *)campaignId {
    [CTPreferences removeObjectForKey:[self getImpressionKey:campaignId]];
}

// TODO: make impressions per instance and per device id?
- (NSString *)getImpressionKey:(NSString *)campaignId {
    return [NSString stringWithFormat:@"%@_%@", @"_impressions", campaignId];
}

@end

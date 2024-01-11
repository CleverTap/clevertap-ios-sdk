//
//  CTImpressionManagerTest.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 27.10.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "CTImpressionManager.h"
#import "CTMultiDelegateManager.h"
#import "CTClockMock.h"
#import "CTImpressionManager+Tests.h"
#import "CTMultiDelegateManager+Tests.h"
#import "InAppHelper.h"

// Use fixed date and time
// Do not set a timezone to the formatter,
// the CTImpressionManager Calendar uses the current timezone
NSString * const DATE_STRING = @"2023-10-26 19:00:00"; // Thursday
NSString * const DATE_FORMAT = @"yyyy-MM-dd HH:mm:ss";
// Use locale where first day of the week is 1 (Sunday)
NSString * const LOCALE = @"en_US_POSIX";

@interface CTImpressionManagerTest : XCTestCase

@property (nonatomic, strong) CTImpressionManager *impressionManager;
@property (nonatomic, strong) CTClockMock *mockClock;
@property (nonatomic, strong) NSString *testCampaignId;

@end

@implementation CTImpressionManagerTest

- (void)setUp {
    [super setUp];
    self.testCampaignId = CLTAP_TEST_CAMPAIGN_ID;

    // Configure the date and clock
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:DATE_FORMAT];
    
    NSDate *date = [dateFormatter dateFromString:DATE_STRING];
    
    CTClockMock *mockClock = [[CTClockMock alloc] initWithCurrentDate:date];
    self.mockClock = mockClock;
    
    // Use locale where first day of the week is 1 (Sunday)
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:LOCALE];
    
    CTMultiDelegateManager *delegateManager = [[CTMultiDelegateManager alloc] init];
    self.impressionManager = [[CTImpressionManager alloc] initWithAccountId:CLTAP_TEST_ACCOUNT_ID
                                                                   deviceId:CLTAP_TEST_DEVICE_ID
                                                            delegateManager:delegateManager
                                                                      clock:mockClock
                                                                     locale:locale];
}

- (void)tearDown {
    [super tearDown];
    [self.impressionManager removeImpressions:self.testCampaignId];
}

- (void)testRecordImpression {
    [self.impressionManager recordImpression:self.testCampaignId];
    
    XCTAssertEqual([self.impressionManager perSessionTotal], 1);
    XCTAssertEqual([self.impressionManager perSession:self.testCampaignId], 1);
    
    NSString *anotherCampaignId = [NSString stringWithFormat:@"%@_2", self.testCampaignId];
    [self.impressionManager recordImpression:self.testCampaignId];
    [self.impressionManager recordImpression:anotherCampaignId];
    XCTAssertEqual([self.impressionManager perSessionTotal], 3);
    XCTAssertEqual([self.impressionManager perSession:self.testCampaignId], 2);
    
    [self.impressionManager removeImpressions:anotherCampaignId];
}

- (void)testImpressionCountMethods {
    [self.impressionManager recordImpression:self.testCampaignId];
    
    XCTAssertEqual([self.impressionManager perSecond:self.testCampaignId seconds:1], 1);
    XCTAssertEqual([self.impressionManager perMinute:self.testCampaignId minutes:1], 1);
    XCTAssertEqual([self.impressionManager perHour:self.testCampaignId hours:1], 1);
    XCTAssertEqual([self.impressionManager perDay:self.testCampaignId days:1], 1);
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:1], 1);
    
    [self.impressionManager recordImpression:self.testCampaignId];
    
    XCTAssertEqual([self.impressionManager perSecond:self.testCampaignId seconds:1], 2);
    XCTAssertEqual([self.impressionManager perMinute:self.testCampaignId minutes:1], 2);
    XCTAssertEqual([self.impressionManager perHour:self.testCampaignId hours:1], 2);
    XCTAssertEqual([self.impressionManager perDay:self.testCampaignId days:1], 2);
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:1], 2);
    
    NSString *anotherCampaignId = [NSString stringWithFormat:@"%@_2", self.testCampaignId];
    XCTAssertEqual([self.impressionManager perSecond:anotherCampaignId seconds:1], 0);
    XCTAssertEqual([self.impressionManager perMinute:anotherCampaignId minutes:1], 0);
    XCTAssertEqual([self.impressionManager perHour:anotherCampaignId hours:1], 0);
    XCTAssertEqual([self.impressionManager perDay:anotherCampaignId days:1], 0);
    XCTAssertEqual([self.impressionManager perWeek:anotherCampaignId weeks:1], 0);
}

- (void)testImpressionStorage {
    [self.impressionManager recordImpression:self.testCampaignId];
    XCTAssertEqual([self.impressionManager getImpressionCount:self.testCampaignId], 1);
    
    [self.impressionManager recordImpression:self.testCampaignId];
    XCTAssertEqual([self.impressionManager getImpressionCount:self.testCampaignId], 2);
    
    [self.impressionManager removeImpressions:self.testCampaignId];
    XCTAssertEqual([self.impressionManager getImpressionCount:self.testCampaignId], 0);
}

- (void)testPerSecond {
    [self.impressionManager recordImpression:self.testCampaignId];
    NSDate *initialDate = self.mockClock.currentDate;
    
    // Advance the clock by 1 seconds
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:1];
    XCTAssertEqual([self.impressionManager perSecond:self.testCampaignId seconds:1], 1);
    XCTAssertEqual([self.impressionManager perSecond:self.testCampaignId seconds:10], 1);
    
    // Advance the clock by 11 seconds
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:11];
    XCTAssertEqual([self.impressionManager perSecond:self.testCampaignId seconds:10], 0);
    XCTAssertEqual([self.impressionManager perSecond:self.testCampaignId seconds:12], 1);
}

- (void)testPerMinute {
    [self.impressionManager recordImpression:self.testCampaignId];
    
    NSDate *initialDate = self.mockClock.currentDate;
    
    // Advance the clock by 30 seconds
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:30];
    XCTAssertEqual([self.impressionManager perMinute:self.testCampaignId minutes:1], 1);
    
    // Advance the clock by 1 minute
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:60];
    XCTAssertEqual([self.impressionManager perMinute:self.testCampaignId minutes:1], 1);
    
    // Advance the clock by 1 minute and 1 second
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:61];
    XCTAssertEqual([self.impressionManager perMinute:self.testCampaignId minutes:1], 0);
    
    // Advance the clock by 1 minute and 1 second test per 2 minutes
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:61];
    XCTAssertEqual([self.impressionManager perMinute:self.testCampaignId minutes:2], 1);
    
    // Advance the clock by 1 minute and 1 second test per 2 minutes
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:60 * 60];
    XCTAssertEqual([self.impressionManager perMinute:self.testCampaignId minutes:60], 1);
}

- (void)testPerHour {
    [self.impressionManager recordImpression:self.testCampaignId];
    
    NSDate *initialDate = self.mockClock.currentDate;
    
    // Advance the clock by 30 mins
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:30 * 60];
    XCTAssertEqual([self.impressionManager perHour:self.testCampaignId hours:1], 1);
    
    // Advance the clock by 1 hour
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:60 * 60];
    XCTAssertEqual([self.impressionManager perHour:self.testCampaignId hours:1], 1);
    
    // Advance the clock by 1 hour and 1 second
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:60 * 60 + 1];
    XCTAssertEqual([self.impressionManager perHour:self.testCampaignId hours:1], 0);
    
    // Advance the clock by 1 hour and 1 second and test per 2 hours
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:60 * 60 + 1];
    XCTAssertEqual([self.impressionManager perHour:self.testCampaignId hours:2], 1);
    
    // Advance the clock by 25 hours
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:25 * 60 * 60];
    XCTAssertEqual([self.impressionManager perHour:self.testCampaignId hours:1], 0);
    
    // Advance the clock by 25 hours and test per 25 hours
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:25 * 60 * 60];
    XCTAssertEqual([self.impressionManager perHour:self.testCampaignId hours:25], 1);
}

- (void)testPerDay {
    [self.impressionManager recordImpression:self.testCampaignId];
    
    NSDate *initialDate = self.mockClock.currentDate;
    // Advance the clock by 2 hours
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:2 * 60 * 60];
    XCTAssertEqual([self.impressionManager perDay:self.testCampaignId days:1], 1);
    
    // Advance the clock by 5 hours minus 1 second
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:(5 * 60 * 60) - 1];
    XCTAssertEqual([self.impressionManager perDay:self.testCampaignId days:1], 1);
    
    // Advance the clock by 5 hours - the day changes
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:5 * 60 * 60];
    XCTAssertEqual([self.impressionManager perDay:self.testCampaignId days:1], 0);
    
    // Advance the clock by 5 hours - the day changes
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:5 * 60 * 60];
    XCTAssertEqual([self.impressionManager perDay:self.testCampaignId days:2], 1);
    
    // Advance the clock by 1 day
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:1 * 24 * 60 * 60];
    XCTAssertEqual([self.impressionManager perDay:self.testCampaignId days:1], 0);
}

- (void)testPerMultipleDays {
    NSDate *initialDate = self.mockClock.currentDate;
    [self.impressionManager recordImpression:self.testCampaignId];
    
    // Advance the clock by 2 hours
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:2 * 60 * 60];
    [self.impressionManager recordImpression:self.testCampaignId];
    XCTAssertEqual([self.impressionManager perDay:self.testCampaignId days:1], 2);
    
    // Advance the clock by 5 hours - the day changes
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:5 * 60 * 60];
    [self.impressionManager recordImpression:self.testCampaignId];
    
    // Check with clock advanced 5 hours - into the next day
    XCTAssertEqual([self.impressionManager perDay:self.testCampaignId days:1], 1);
    XCTAssertEqual([self.impressionManager perDay:self.testCampaignId days:2], 3);
    XCTAssertEqual([self.impressionManager perDay:self.testCampaignId days:7], 3);
    
    // Advance the clock by 24 + 5 hours - 2 days ahead
    self.mockClock.currentDate = [initialDate dateByAddingTimeInterval:(24 + 5) * 60 * 60];
    XCTAssertEqual([self.impressionManager perDay:self.testCampaignId days:1], 0);
    XCTAssertEqual([self.impressionManager perDay:self.testCampaignId days:2], 1);
    
    // Check with clock advanced 2 days
    [self.impressionManager recordImpression:self.testCampaignId];
    XCTAssertEqual([self.impressionManager perDay:self.testCampaignId days:1], 1);
    XCTAssertEqual([self.impressionManager perDay:self.testCampaignId days:2], 2);
    XCTAssertEqual([self.impressionManager perDay:self.testCampaignId days:3], 4);
}

- (void)testPerWeek {
    [self.impressionManager recordImpression:self.testCampaignId];
    
    NSDate *startDate = self.mockClock.currentDate;
    // Advance the clock by 2 days
    self.mockClock.currentDate = [startDate dateByAddingTimeInterval:2 * 24 * 60 * 60];
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:1], 1);
    
    // Advance the clock by 2 days and 5 hours minus 1 second
    self.mockClock.currentDate = [startDate dateByAddingTimeInterval:(2 * 24 * 60 * 60 + 5 * 60 * 60) - 1];
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:1], 1);
    
    // Advance the clock by 2 days and 5 hours - goes into Sunday which is the start of the next week
    self.mockClock.currentDate = [startDate dateByAddingTimeInterval:2 * 24 * 60 * 60 + 5 * 60 * 60];
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:1], 0);
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:2], 1);
    
    // Advance the clock by 3 days
    self.mockClock.currentDate = [startDate dateByAddingTimeInterval:3 * 24 * 60 * 60];
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:1], 0);
    
    // Advance the clock by 1 week
    self.mockClock.currentDate = [startDate dateByAddingTimeInterval:7 * 24 * 60 * 60];
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:1], 0);
    
    // Advance the clock by 1 week and 1 second
    self.mockClock.currentDate = [startDate dateByAddingTimeInterval:(7 * 24 * 60 * 60) + 1];
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:1], 0);
    
    // Advance the clock by 1 week and test per 2 weeks
    self.mockClock.currentDate = [startDate dateByAddingTimeInterval:7 * 24 * 60 * 60];
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:2], 1);
}

- (void)testPerMultipleWeeks {
    NSDate *startDate = self.mockClock.currentDate;
    
    // 2023-10-26 19:00:00
    [self.impressionManager recordImpression:self.testCampaignId];
    // Advance the clock by 2 days
    // 2023-10-28 19:00:00
    self.mockClock.currentDate = [startDate dateByAddingTimeInterval:2 * 24 * 60 * 60];
    [self.impressionManager recordImpression:self.testCampaignId];
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:1], 2);
    
    // Advance the clock by 2 days and 5 hours - goes into Sunday which is the start of the next week
    // 2023-10-29 00:00:00
    self.mockClock.currentDate = [startDate dateByAddingTimeInterval:2 * 24 * 60 * 60 + 5 * 60 * 60];
    [self.impressionManager recordImpression:self.testCampaignId];

    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:1], 1);
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:2], 3);
    
    // Advance the clock by 1 week
    // 2023-11-02 19:00:00
    self.mockClock.currentDate = [startDate dateByAddingTimeInterval:7 * 24 * 60 * 60];
    // Last 1 week - current week
    // 2023-10-30 19:00:00
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:1], 1);
    // Last 2 Weeks - start of current week minus 7 days
    // 2023-10-22 00:00:00
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:2], 3);
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:4], 3);
    
    // Advance the clock by 2 weeks
    // 2023-11-09 19:00:00
    self.mockClock.currentDate = [startDate dateByAddingTimeInterval:2 * 7 * 24 * 60 * 60];
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:1], 0);
    // Last 2 Weeks - start of current week minus 7 days
    // 2023-10-30 00:00:00
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:2], 1);
    // Last 3 Weeks - start of current week minus 14 days
    // 2023-10-22 00:00:00
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:3], 3);
    XCTAssertEqual([self.impressionManager perWeek:self.testCampaignId weeks:4], 3);
}

- (void)testSwitchUserDelegateAdded {
    CTMultiDelegateManager *delegateManager = [[CTMultiDelegateManager alloc] init];
    NSUInteger count = [[delegateManager switchUserDelegates] count];
    
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:LOCALE];
    self.impressionManager = [[CTImpressionManager alloc] initWithAccountId:CLTAP_TEST_ACCOUNT_ID
                                                                   deviceId:CLTAP_TEST_DEVICE_ID
                                                            delegateManager:delegateManager
                                                                      clock:self.mockClock
                                                                     locale:locale];
    
    XCTAssertEqual([[delegateManager switchUserDelegates] count], count + 1);
}

- (void)testSwitchUser {
    NSString *firstDeviceId = CLTAP_TEST_DEVICE_ID;
    NSString *secondDeviceId = [NSString stringWithFormat:@"%@_2", firstDeviceId];
    
    // Record impressions for first user
    [self.impressionManager recordImpression:self.testCampaignId];
    [self.impressionManager recordImpression:self.testCampaignId];
    XCTAssertEqual([self.impressionManager getImpressionCount:self.testCampaignId], 2);
    
    // Switch to second user and record impressions
    [self.impressionManager deviceIdDidChange:secondDeviceId];
    XCTAssertEqual([self.impressionManager getImpressionCount:self.testCampaignId], 0);
    [self.impressionManager recordImpression:self.testCampaignId];
    XCTAssertEqual([self.impressionManager getImpressionCount:self.testCampaignId], 1);

    // Switch to first user to ensure cached impressions for first user are loaded
    [self.impressionManager deviceIdDidChange:firstDeviceId];
    XCTAssertEqual([self.impressionManager getImpressionCount:self.testCampaignId], 2);

    // Switch to second user to ensure cached impressions for second user are loaded
    [self.impressionManager deviceIdDidChange:secondDeviceId];
    XCTAssertEqual([self.impressionManager getImpressionCount:self.testCampaignId], 1);

    // Clear in-apps for the second user
    [self.impressionManager removeImpressions:self.testCampaignId];
    // Switch back to first user to tear down
    [self.impressionManager deviceIdDidChange:firstDeviceId];
}

@end

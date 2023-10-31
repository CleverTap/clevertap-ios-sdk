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
#import "CTDelegateManager.h"
#import "CTClockMock.h"

@interface CTImpressionManager(Tests)
- (NSInteger)getImpressionCount:(NSString *)campaignId;
@end

@interface CTImpressionManagerTest : XCTestCase

@property (nonatomic, strong) CTImpressionManager *impressionManager;
@property (nonatomic, strong) CTClockMock *mockClock;
@property (nonatomic, strong) NSString *testCampaignId;

@end

@implementation CTImpressionManagerTest

- (void)setUp {
    [super setUp];
    self.testCampaignId = @"testCampaignId";
    // Initialize the CTDelegateManager for testing
    CTDelegateManager *delegateManager = [[CTDelegateManager alloc] init];
    
    // Use fixed date and time
    // Do not set a timezone to the formatter,
    // the CTImpressionManager Calendar uses the current timezone
    NSString *dateString = @"2023-10-26 19:00:00"; // Thursday
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

    NSDate *date = [dateFormatter dateFromString:dateString];

    CTClockMock *mockClock = [[CTClockMock alloc] initWithCurrentDate:date];
    self.mockClock = mockClock;
    
    // Use locale where first day of the week is 1 (Sunday)
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    self.impressionManager = [[CTImpressionManager alloc] initWithAccountId:@"testAccountID"
                                                                   deviceId:@"testDeviceID"
                                                            delegateManager:delegateManager
                                                                      clock:mockClock locale:locale];
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
}

- (void)testImpressionStorage {
    [self.impressionManager recordImpression:self.testCampaignId];
    XCTAssertEqual([self.impressionManager getImpressionCount:self.testCampaignId], 1);
    
    [self.impressionManager recordImpression:self.testCampaignId];
    XCTAssertEqual([self.impressionManager getImpressionCount:self.testCampaignId], 2);
    
    [self.impressionManager removeImpressions:self.testCampaignId];
    XCTAssertEqual([self.impressionManager getImpressionCount:self.testCampaignId], 0);
}

- (void)testPerSecondWithMockClock {
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

- (void)testPerMinuteWithMockClock {
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

- (void)testPerHourWithMockClock {
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

- (void)testPerDayWithMockClock {
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

- (void)testPerWeekWithMockClock {
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

@end

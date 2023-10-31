//
//  CTClockMock.m
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 31.10.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTClockMock.h"

@implementation CTClockMock

- (instancetype)initWithCurrentDate:(NSDate *)currentDate {
    self = [super init];
    if (self) {
        _currentDate = currentDate;
    }
    return self;
}

- (NSDate *)currentDate {
    return _currentDate;
}

- (NSNumber *)timeIntervalSince1970 {
    return @([self.currentDate timeIntervalSince1970]);
}

@end

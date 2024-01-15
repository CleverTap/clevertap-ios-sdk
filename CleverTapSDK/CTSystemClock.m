//
//  CTSystemClock.m
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 25.10.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import "CTSystemClock.h"

@implementation CTSystemClock

- (NSNumber *)timeIntervalSince1970 {
    return @([[NSDate date] timeIntervalSince1970]);
}

- (NSDate *)currentDate {
    return [NSDate date];
}

@end

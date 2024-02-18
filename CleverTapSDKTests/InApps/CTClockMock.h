//
//  CTClockMock.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 31.10.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTClock.h"
NS_ASSUME_NONNULL_BEGIN

@interface CTClockMock : NSObject <CTClock>

@property (nonatomic, strong) NSDate *currentDate;

- (instancetype)initWithCurrentDate:(NSDate *)currentDate;

@end

NS_ASSUME_NONNULL_END

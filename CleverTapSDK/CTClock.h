//
//  CTClock.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 27.10.23.
//  Copyright © 2023 CleverTap. All rights reserved.
//

#ifndef CTClock_h
#define CTClock_h

@protocol CTClock <NSObject>
- (NSNumber *)timeIntervalSince1970;
- (NSDate *)currentDate;
@end

#endif /* CTClock_h */

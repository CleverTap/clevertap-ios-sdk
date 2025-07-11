//
//  CTContentFetchManagerMock.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 29.05.25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTContentFetchManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTContentFetchManagerMock : CTContentFetchManager

@property (nonatomic, copy, nullable) void (^onAllRequestsCompleted)(void);

@end

NS_ASSUME_NONNULL_END

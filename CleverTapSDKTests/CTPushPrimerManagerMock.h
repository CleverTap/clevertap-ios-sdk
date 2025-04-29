//
//  CTPushPrimerManagerMock.h
//  CleverTapSDKTests
//
//  Created by Nishant Kumar on 14/04/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTPushPrimerManager.h"

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(10.0))
@interface CTPushPrimerManagerMock : CTPushPrimerManager

@property (nonatomic, readwrite) UNAuthorizationStatus currentPushStatus;

@end

NS_ASSUME_NONNULL_END

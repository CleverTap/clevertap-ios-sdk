//
//  CTPushPrimerManagerMock.m
//  CleverTapSDKTests
//
//  Created by Nishant Kumar on 14/04/25.
//  Copyright © 2025 CleverTap. All rights reserved.
//

#import "CTPushPrimerManagerMock.h"

@implementation CTPushPrimerManagerMock

- (void)getNotificationPermissionStatusWithCompletionHandler:(void (^)(UNAuthorizationStatus))completion {
    completion(self.currentPushStatus);
}

@end

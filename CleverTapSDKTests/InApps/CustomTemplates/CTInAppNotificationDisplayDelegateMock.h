//
//  CTInAppNotificationDisplayDelegateMock.h
//  CleverTapSDKTests
//
//  Created by Nikola Zagorchev on 5.06.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CTInAppNotificationDisplayDelegate.h"
#import "CTInAppNotification.h"
#import "CTNotificationAction.h"

NS_ASSUME_NONNULL_BEGIN

@interface CTInAppNotificationDisplayDelegateMock : NSObject <CTInAppNotificationDisplayDelegate>

//@property (nonatomic) void (^notificationDidShow)(CTInAppNotification *);
@property (nonatomic) void (^handleNotificationAction)(CTNotificationAction *, CTInAppNotification *, NSDictionary *);

//@property (nonatomic) int notificationDidShowInvocations;
@property (nonatomic) int handleNotificationActionInvocations;

@end

NS_ASSUME_NONNULL_END

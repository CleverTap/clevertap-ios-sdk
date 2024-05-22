//
//  CTCustomTemplatesManager-Internal.h
//  CleverTapSDK
//
//  Created by Nikola Zagorchev on 21.05.24.
//  Copyright © 2024 CleverTap. All rights reserved.
//

#ifndef CTCustomTemplatesManager_Internal_h
#define CTCustomTemplatesManager_Internal_h

#import "CTCustomTemplatesManager.h"
#import "CleverTapInstanceConfig.h"
#import "CTInAppNotification.h"
#import "CTInAppNotificationDisplayDelegate.h"

@interface CTCustomTemplatesManager (Internal)

- (instancetype)initWithConfig:(CleverTapInstanceConfig *)instanceConfig;

- (void)presentNotification:(CTInAppNotification *)notification withDelegate:(id<CTInAppNotificationDisplayDelegate>)delegate;

@end

#endif /* CTCustomTemplatesManager_Internal_h */
